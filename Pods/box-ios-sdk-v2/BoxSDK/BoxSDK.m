//
//  BoxSDK.m
//  BoxSDK
//
//  Created on 2/19/13.
//  Copyright (c) 2013 Box. All rights reserved.
//
//  NOTE: this file is a mirror of BoxCocoaSDK/BoxCocoaSDK.m. Changes made here should be reflected there.
//

#import "BoxSDK.h"
#import "BoxSDKConstants.h"
#import "BoxOAuth2Session.h"
#import "BoxSerialOAuth2Session.h"
#import "BoxSerialAPIQueueManager.h"

@implementation BoxSDK

@synthesize APIBaseURL = _APIBaseURL;
@synthesize OAuth2Session = _OAuth2Session;
@synthesize queueManager = _queueManager;
@synthesize foldersManager = _foldersManager;
@synthesize filesManager = _filesManager;
@synthesize searchManager = _searchManager;
@synthesize usersManager = _usersManager;
@synthesize commentsManager = _commentsManager;

#pragma mark - Globally accessible API singleton instance
+ (BoxSDK *)sharedSDK
{
    static dispatch_once_t pred;
    static BoxSDK *sharedBoxSDK;

    dispatch_once(&pred, ^{
        sharedBoxSDK = [[BoxSDK alloc] init];

        [sharedBoxSDK setAPIBaseURL:BoxAPIBaseURL];

        // the circular reference between the queue manager and the OAuth2 session is necessary
        // because the OAuth2 session enqueues API operations to fetch access tokens and the queue
        // manager uses the OAuth2 session as a lock object when enqueuing operations.
        sharedBoxSDK.queueManager = [[BoxParallelAPIQueueManager alloc] init];
        sharedBoxSDK.OAuth2Session = [[BoxParallelOAuth2Session alloc] initWithClientID:nil
                                                                                 secret:nil
                                                                             APIBaseURL:BoxAPIBaseURL
                                                                           queueManager:sharedBoxSDK.queueManager];

        sharedBoxSDK.queueManager.OAuth2Session = sharedBoxSDK.OAuth2Session;

        sharedBoxSDK.filesManager = [[BoxFilesResourceManager alloc] initWithAPIBaseURL:BoxAPIBaseURL OAuth2Session:sharedBoxSDK.OAuth2Session queueManager:sharedBoxSDK.queueManager];
        sharedBoxSDK.filesManager.uploadBaseURL = BoxAPIUploadBaseURL;
        sharedBoxSDK.filesManager.uploadAPIVersion = BoxAPIUploadAPIVersion;

        sharedBoxSDK.foldersManager = [[BoxFoldersResourceManager alloc] initWithAPIBaseURL:BoxAPIBaseURL OAuth2Session:sharedBoxSDK.OAuth2Session queueManager:sharedBoxSDK.queueManager];

        sharedBoxSDK.searchManager = [[BoxSearchResourceManager alloc] initWithAPIBaseURL:BoxAPIBaseURL OAuth2Session:sharedBoxSDK.OAuth2Session queueManager:sharedBoxSDK.queueManager];

        sharedBoxSDK.usersManager = [[BoxUsersResourceManager alloc] initWithAPIBaseURL:BoxAPIBaseURL OAuth2Session:sharedBoxSDK.OAuth2Session queueManager:sharedBoxSDK.queueManager];
        
        sharedBoxSDK.commentsManager = [[BoxCommentsResourceManager alloc]initWithAPIBaseURL:BoxAPIBaseURL OAuth2Session:sharedBoxSDK.OAuth2Session queueManager:sharedBoxSDK.queueManager];
    });

    return sharedBoxSDK;
}

- (void)setAPIBaseURL:(NSString *)APIBaseURL
{
    _APIBaseURL = APIBaseURL;
    self.OAuth2Session.APIBaseURLString = APIBaseURL;

    // managers
    self.filesManager.APIBaseURL = APIBaseURL;
    self.foldersManager.APIBaseURL = APIBaseURL;
    self.searchManager.APIBaseURL = APIBaseURL;
    self.usersManager.APIBaseURL = APIBaseURL;
    self.commentsManager.APIBaseURL = APIBaseURL;
}

#if TARGET_OS_IOS
- (BoxItemPickerViewController *)itemPickerWithRootFolderID:(NSString *)rootFolderID
                                          thumbnailsEnabled:(BOOL)thumbnailsEnabled
                                       cachedThumbnailsPath:(NSString *)cachedThumbnailsPath
                                       selectableObjectType:(BoxItemPickerObjectType)selectableObjectType
{
    return [[BoxItemPickerViewController alloc]
            initWithSDK:self
            rootFolderID:rootFolderID
            thumbnailsEnabled:thumbnailsEnabled
            cachedThumbnailsPath:cachedThumbnailsPath
            selectableObjectType:selectableObjectType];
}

- (BoxItemPickerViewController *)itemPickerWithDelegate:(id <BOXItemPickerDelegate>)delegate selectableObjectType:(BoxItemPickerObjectType)selectableObjectType
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

    if (basePath) {
        NSString *thumbnailPath = [basePath stringByAppendingPathComponent:@"Box"];

        BoxItemPickerViewController *picker = [self itemPickerWithRootFolderID:@"0"
                                                             thumbnailsEnabled:YES
                                                          cachedThumbnailsPath:thumbnailPath
                                                          selectableObjectType:selectableObjectType];
        picker.delegate = delegate;

        return picker;
    } else {
        BOXAssertFail(@"Could not retrieve the documents directory when initializing the folderpicker.");
        return nil;
    }
}
#endif

// Load the ressources bundle.
+ (NSBundle *)resourcesBundle
{
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSURL* ressourcesBundleURL = [[NSBundle mainBundle] URLForResource:@"BoxSDKResources" withExtension:@"bundle"];
        frameworkBundle = [NSBundle bundleWithURL:ressourcesBundleURL];
    });
    return frameworkBundle;
}
@end
