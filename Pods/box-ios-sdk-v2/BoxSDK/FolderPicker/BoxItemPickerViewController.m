//
//  BoxItemPickerViewController.m
//  BoxSDK
//
//  Created on 5/1/13.
//  Copyright (c) 2013 Box Inc. All rights reserved.
//

#import <BoxSDK/UIImage+BoxAdditions.h>
#import <BoxSDK/NSString+BoxAdditions.h>

#import <BoxSDK/BoxItemPickerViewController.h>
#import <BoxSDK/BoxSDK.h>
#import <BoxSDK/BoxLog.h>

#define kStrechWidthOffset 9.0
#define kStrechHeightOffset 16.0
#define kButtonWidth 100
#define kStretchBackButtonLeftOffset 18
#define kStretchBackButtonRightOffset 13
#define kStretchNavBarHeight 20.0

typedef enum {
    BoxItemPickerStateAuthenticate = 1,
    BoxItemPickerStateBrowse
} BoxItemPickerState;

@interface BoxItemPickerViewController ()

@property (nonatomic, readwrite, strong) BoxItemPickerTableViewController *tableViewPicker;
@property (nonatomic, readwrite, strong) UINavigationController *authorizationViewController;
@property (nonatomic, readwrite, assign) BoxItemPickerState folderPickerState;

@property (nonatomic, readwrite, weak) BoxSDK *sdk;

@property (nonatomic, readwrite, strong) NSString *folderID;
@property (nonatomic, readwrite, strong) BoxFolder *folder;

@property (nonatomic, readwrite, assign) NSUInteger totalCount;
@property (nonatomic, readwrite, assign) NSUInteger currentPage;
@property (nonatomic, readwrite, strong) NSMutableArray *items;

@property (nonatomic, readwrite, strong) UIBarButtonItem *selectItem;
@property (nonatomic, readwrite, strong) UIBarButtonItem *closeItem;

@property (nonatomic, readwrite, strong) NSString *thumbnailPath;
@property (nonatomic, readwrite, assign) BOOL thumbnailsEnabled;

@property (nonatomic, readwrite, strong) NSMutableArray *interuptedAPIOperations;

@property (nonatomic, readwrite, strong) BoxItemPickerHelper *helper;

- (void)populateFolderPicker;

@end

@implementation BoxItemPickerViewController

@synthesize delegate = _delegate;
@synthesize numberOfItemsPerPage = _numberOfItemsPerPage;

@synthesize tableViewPicker = _tableViewPicker;
@synthesize authorizationViewController = _authorizationViewController;
@synthesize folderPickerState = _folderPickerState;
@synthesize sdk = _sdk;
@synthesize folderID = _folderID;
@synthesize folder = _folder;
@synthesize totalCount = _totalCount;
@synthesize currentPage = _currentPage;
@synthesize items = _items;
@synthesize selectItem = _selectItem;
@synthesize closeItem = _closeItem;
@synthesize thumbnailPath = _thumbnailPath;
@synthesize thumbnailsEnabled = _thumbnailsEnabled;
@synthesize selectableObjectType = _selectableObjectType;
@synthesize interuptedAPIOperations = _interuptedAPIOperations;
@synthesize helper = _helper;


- (id)initWithSDK:(BoxSDK *)sdk rootFolderID:(NSString *)rootFolderID thumbnailsEnabled:(BOOL)thumbnailsEnabled cachedThumbnailsPath:(NSString *)cachedThumbnailsPath selectableObjectType:(BoxItemPickerObjectType)selectableObjectType
{
    self = [super init];
    if (self != nil)
    {
        _folderID = rootFolderID;
        _currentPage = 1;
        _totalCount = 0;
        _items = [NSMutableArray array];
        _numberOfItemsPerPage = 100;

        _thumbnailPath = cachedThumbnailsPath;
        _thumbnailsEnabled = thumbnailsEnabled;
        _selectableObjectType = selectableObjectType;

        _sdk = sdk;
        _helper = [[BoxItemPickerHelper alloc] initWithSDK:_sdk];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Child View Controllers

- (BoxItemPickerTableViewController *)tableViewPicker
{
    if (!_tableViewPicker)
    {
        _tableViewPicker = [[BoxItemPickerTableViewController alloc] initWithFolderPickerHelper:self.helper];
        _tableViewPicker.itemPicker = self;
        _tableViewPicker.delegate = self;
    }

    return _tableViewPicker;
}

- (UINavigationController *)authorizationViewController
{
    if (!_authorizationViewController)
    {
        BoxAuthorizationViewController *authVC = [[BoxAuthorizationViewController alloc] initWithAuthorizationURL:self.sdk.OAuth2Session.authorizeURL redirectURI:self.sdk.OAuth2Session.redirectURIString];
        authVC.delegate = self;

        _authorizationViewController = [[UINavigationController alloc] initWithRootViewController:authVC];
        _authorizationViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _authorizationViewController.navigationBarHidden = YES;
    }

    return _authorizationViewController;
}

#pragma mark - Bar Buton Items

- (UIBarButtonItem *)closeItem
{
    if (_closeItem == nil) {
        _closeItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Title : button closing the folder picker") style:UIBarButtonItemStyleBordered target:self action:@selector(closeTouched:)];
        [_closeItem setTitlePositionAdjustment:UIOffsetMake(0.0, 1) forBarMetrics:UIBarMetricsDefault];
    }

    return _closeItem;
}

- (UIBarButtonItem *)selectItem
{
    if (!_selectItem) {
        _selectItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select", @"Title : button allowing the user to pick the current folder") style:UIBarButtonItemStyleBordered target:self action:@selector(selectTouched:)];
        _selectItem.width = kButtonWidth;
    }

    return _selectItem;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Creating the cache folder is needed
    if (self.thumbnailPath != nil)
    {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.thumbnailPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.thumbnailPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error)
            {
                BOXLog(@"Cannot create Folder picker's cache folder : %@", error);
            }
        }
    }

    // Content View Controller
    [self addChildViewController:self.tableViewPicker];
    self.tableViewPicker.view.frame = self.view.bounds;
    [self.view addSubview:self.tableViewPicker.view];
    [self.tableViewPicker didMoveToParentViewController:self];
    self.folderPickerState = BoxItemPickerStateBrowse;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // when the folder picker is visible, we may need to retry operations in the event of a refresh
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boxSessionsDidRefreshToken:)
                                                 name:BoxOAuth2SessionDidRefreshTokensNotification
                                               object:self.sdk.OAuth2Session];

    if (self.folderPickerState == BoxItemPickerStateBrowse)
    {
        // when the folder picker is visible, we may need to reauthenticate the user if they are logged out
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(boxAuthenticationDidFailed:)
                                                     name:BoxOAuth2SessionDidReceiveRefreshErrorNotification
                                                   object:self.sdk.OAuth2Session];
    }
    else if (self.folderPickerState == BoxItemPickerStateAuthenticate)
    {
        // If the folder picker is responsible for presenting the authorization view controller,
        // register for authentication notifications so we can appropriately transition the view
        // hierarchy.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(boxSessionDidBecameAuthenticated:)
                                                     name:BoxOAuth2SessionDidBecomeAuthenticatedNotification
                                                   object:self.sdk.OAuth2Session];
    }

    // UI Setup
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor], UITextAttributeTextColor,
      [UIColor blackColor], UITextAttributeTextShadowColor,
      [NSValue valueWithUIOffset:UIOffsetMake(0, 0)], UITextAttributeTextShadowOffset,
      [UIFont boldSystemFontOfSize:16.0], UITextAttributeFont,
      nil]];


    // Back button
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"Title : cell allowing the user to go back in the viewControllers tree") style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.navigationItem.backBarButtonItem = back;

    self.navigationItem.rightBarButtonItems = @[self.closeItem];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage  imageFromBoxSDKResourcesBundleWithName:@"bkg-navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(kStretchNavBarHeight, 1.0, kStretchNavBarHeight, 1.0)] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self populateFolderPicker];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BoxOAuth2SessionDidRefreshTokensNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BoxOAuth2SessionDidReceiveRefreshErrorNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BoxOAuth2SessionDidBecomeAuthenticatedNotification
                                                  object:nil];

    [super viewWillDisappear:animated];
}

#pragma mark - Data management

- (void)populateFolderPicker
{
    //Getting the folder's informations
    BoxFolderBlock infoSuccess = ^(BoxFolder *folder)
    {
        dispatch_async(dispatch_get_main_queue(), ^{

            // Toolbar Setup
            UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            self.toolbarItems = @[space, self.selectItem];
            if (!self.fileSelectionEnabled)
            {
                [self.navigationController setToolbarHidden:NO];
                [self.navigationController.toolbar setBackgroundImage:[[UIImage  imageFromBoxSDKResourcesBundleWithName:@"footer"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 1.0, 0.0, 1.0)] forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
                [self.navigationController.toolbar setBackgroundImage:[[UIImage  imageFromBoxSDKResourcesBundleWithName:@"footer"] resizableImageWithCapInsets:UIEdgeInsetsMake(kStrechHeightOffset, 1.0, kStrechHeightOffset, 1.0)] forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
            }
            self.title = folder.name;
            self.folder = folder;
            self.navigationItem.prompt = nil;

            if ([self.tableViewPicker respondsToSelector:@selector(refreshControl)])
            {
                self.tableViewPicker.refreshControl = [[UIRefreshControl alloc] init];
                [self.tableViewPicker.refreshControl addTarget:self
                                                        action:@selector(refreshData)
                                              forControlEvents:UIControlEventValueChanged];
            }
        });
    };

    BoxAPIJSONFailureBlock infoFailure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary)
    {
        if (error.code == BoxSDKOAuth2ErrorAccessTokenExpired)
        {
            // This error code indicates that an access token is expired but the SDK is attempting to refresh
            // tokens and retry the API call.
            //
            // If the tokens cannot be refreshed, this block will be invoked again and the next if-condition
            // will be hit.
            return;
        }

        // If any of these error code are returned, the user has to login.
        if (error.code == BoxSDKOAuth2ErrorAccessTokenExpiredOperationReachedMaxReenqueueLimit || error.code == BoxSDKOAuth2ErrorAccessTokenExpiredOperationCannotBeReenqueued)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self boxAuthenticationDidFailed:nil];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.navigationItem.prompt = NSLocalizedString(@"An error occured while retrieving data", @"Desciptive : Prompt explaining that an error occured during an API call") ;
            });
        }
    };

    [self.sdk.foldersManager folderInfoWithID:self.folderID requestBuilder:nil success:infoSuccess failure:infoFailure];

    [self refreshData];
}

- (void)refreshData
{
    BOOL supportsRefreshControl = [self.tableViewPicker respondsToSelector:@selector(refreshControl)];
    if (supportsRefreshControl)
    {
        [self.tableViewPicker.refreshControl beginRefreshing];
    }

    BoxAPIJSONFailureBlock infoFailure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (supportsRefreshControl)
            {
                [self.tableViewPicker.refreshControl endRefreshing];
            }
            // If any of these error code are returned, the user has to login.
            if (error.code == BoxSDKOAuth2ErrorAccessTokenExpiredOperationReachedMaxReenqueueLimit || error.code == BoxSDKOAuth2ErrorAccessTokenExpired || error.code == BoxSDKOAuth2ErrorAccessTokenExpiredOperationCannotBeReenqueued)
            {
                [self boxAuthenticationDidFailed:nil];
            }
            else {
                self.navigationController.navigationBar.tintColor = [UIColor redColor];
                self.navigationItem.prompt = NSLocalizedString(@"An error occured while retrieving data", @"Desciptive : Prompt explaining that an error occured during an API call") ;
            }
        });
    };

    //Getting the folder's childrens
    BoxCollectionBlock listSuccess = ^(BoxCollection *collection)
    {
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        
        self.totalCount = [[collection totalCount] integerValue];

        if (self.totalCount > self.items.count) {
            //Adding the page retrieved
            for (int i = 0; i < [collection numberOfEntries]; i++)
            {
                [self.items addObject:[collection modelAtIndex:i]];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (supportsRefreshControl)
            {
                [self.tableViewPicker.refreshControl endRefreshing];
            }
            self.navigationItem.prompt = nil;
            [self.tableViewPicker refreshData];
        });
    };

    NSMutableDictionary *fieldsDictionnary = [NSMutableDictionary dictionary];
    [fieldsDictionnary setObject:@"size,name,modified_at" forKey:@"fields"];
    [fieldsDictionnary setObject:[NSNumber numberWithUnsignedInteger:self.currentPage * self.numberOfItemsPerPage] forKey:@"limit"];
    [fieldsDictionnary setObject:[NSNumber numberWithUnsignedInteger: (self.currentPage - 1) * self.numberOfItemsPerPage ] forKey:@"offset"];
    BoxFoldersRequestBuilder *request = [[BoxFoldersRequestBuilder alloc] initWithQueryStringParameters:fieldsDictionnary];

    [self.sdk.foldersManager folderItemsWithID:self.folderID requestBuilder:request success:listSuccess failure:infoFailure];
}

#pragma mark - Callbacks

- (void)closeTouched:(id)sender
{
    // Purge the in memory cache and cancel all pending download operations before dismiss notify the delegate.
    [self.helper purgeInMemoryCache];
    [self.helper cancelThumbnailOperations];

    [self.delegate itemPickerControllerDidCancel:self];
}

- (void)selectTouched:(id)sender
{
    // Purge the in memory cache and cancel all pending download operations before dismiss notify the delegate.
    [self.helper purgeInMemoryCache];
    [self.helper cancelThumbnailOperations];

    [self.delegate itemPickerController:self didSelectBoxFolder:self.folder];
}

#pragma mark - Folder Picker delegate methods

- (NSUInteger)currentNumberOfItems
{
    return [self.items count];
}

- (NSUInteger)totalNumberOfItems
{
    return self.totalCount;
}

- (BoxItem *)itemAtIndex:(NSUInteger)index
{
    return [self.items objectAtIndex:index];
}

- (void)loadNextSetOfItems
{
    self.currentPage ++;
    [self refreshData];
}

- (NSString *)thumbnailPath
{
    return _thumbnailPath;
}

- (BOOL)thumbnailsEnabled
{
    return _thumbnailsEnabled;
}

- (BOOL)fileSelectionEnabled
{
    return (self.selectableObjectType != BoxItemPickerObjectTypeFolder);
}

- (BoxSDK *)currentSDK
{
    return self.sdk;
}

#pragma mark - Cache

- (void)purgeCache
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.thumbnailPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.thumbnailPath error:nil];
    }
}

#pragma mark - OAuth 2 session management

- (void)boxSessionDidBecameAuthenticated:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view endEditing:YES];
        [self addChildViewController:self.tableViewPicker];
        self.tableViewPicker.view.frame = self.view.bounds;
        [self.authorizationViewController willMoveToParentViewController:nil];

        [self transitionFromViewController:self.authorizationViewController
                          toViewController:self.tableViewPicker
                                  duration:0.3f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:nil
                                completion:^(BOOL finished)
         {
             [self.authorizationViewController removeFromParentViewController];
             [self.tableViewPicker didMoveToParentViewController:self];
             // do not hold a reference to the authorization view controller. It should
             // be discarded when it is no longer needed.
             _authorizationViewController = nil;
             [self populateFolderPicker];
             [[NSNotificationCenter defaultCenter] addObserver:self
                                                      selector:@selector(boxAuthenticationDidFailed:)
                                                          name:BoxOAuth2SessionDidReceiveRefreshErrorNotification
                                                        object:self.sdk.OAuth2Session];
             [[NSNotificationCenter defaultCenter] removeObserver:self
                                                             name:BoxOAuth2SessionDidBecomeAuthenticatedNotification
                                                           object:nil];
             self.folderPickerState = BoxItemPickerStateBrowse;
         }];
    });
}

- (void)boxSessionsDidRefreshToken:(NSNotification *)notification
{
    [self.helper retryOperationsAfterTokenRefresh];
}

- (void)boxAuthenticationDidFailed:(NSNotification *)notification
{
    // This method can be called twice when a folder picker loads : when the get item info fails and when the get folder children fails
    // We only want to do the transition once.
    if (self.tableViewPicker.parentViewController) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationController.title = nil;

            [self addChildViewController:self.authorizationViewController];
            self.authorizationViewController.view.frame = self.view.bounds;
            [self.tableViewPicker willMoveToParentViewController:nil];

            [self transitionFromViewController:self.tableViewPicker
                              toViewController:self.authorizationViewController
                                      duration:0.3f
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:nil
                                    completion:^(BOOL finished)
             {
                 [self.tableViewPicker removeFromParentViewController];
                 [self.authorizationViewController didMoveToParentViewController:self];
                 // If the folder picker is responsible for presenting the authorization view controller,
                 // register for authentication notifications so we can appropriately transition the view
                 // hierarchy.
                 [[NSNotificationCenter defaultCenter] addObserver:self
                                                          selector:@selector(boxSessionDidBecameAuthenticated:)
                                                              name:BoxOAuth2SessionDidBecomeAuthenticatedNotification
                                                            object:self.sdk.OAuth2Session];
                 [[NSNotificationCenter defaultCenter] removeObserver:self
                                                                 name:BoxOAuth2SessionDidReceiveRefreshErrorNotification
                                                               object:nil];
                 self.folderPickerState = BoxItemPickerStateAuthenticate;
             }];
        });
    }
}


#pragma mark - BoxAuthorizationViewControllerDelegate methods

- (void)authorizationViewControllerDidCancel:(BoxAuthorizationViewController *)authorizationViewController
{
    if (![self.sdk.OAuth2Session isAuthorized])
    {
        [self.delegate itemPickerControllerDidCancel:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)authorizationViewControllerDidFinishLoading:(BoxAuthorizationViewController *)authorizationViewController
{

}

- (void)authorizationViewControllerDidStartLoading:(BoxAuthorizationViewController *)authorizationViewController
{

}

- (BOOL)authorizationViewController:(BoxAuthorizationViewController *)authorizationViewController shouldLoadReceivedOAuth2RedirectRequest:(NSURLRequest *)request
{
    [self.sdk.OAuth2Session performAuthorizationCodeGrantWithReceivedURL:request.URL];

    return NO;
}



@end
