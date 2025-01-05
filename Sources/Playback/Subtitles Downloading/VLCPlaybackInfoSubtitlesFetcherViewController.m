/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020-2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoSubtitlesFetcherViewController.h"
#import "VLCOSOFetcher.h"
#import "VLCSubtitleItem.h"
#import "VLCMetadata.h"
#import "VLCPlaybackService.h"
#if !TARGET_OS_TV
#import "VLC-Swift.h"
#endif

#define SPUDownloadReUseIdentifier @"SPUDownloadReUseIdentifier"
#define SPUDownloadHeaderReUseIdentifier @"SPUDownloadHeaderReUseIdentifier"

@interface VLCPlaybackInfoSubtitlesFetcherViewController () <UITableViewDataSource, UITableViewDelegate, VLCOSOFetcherDataRecipient, UISearchBarDelegate>
{
    NSString *_lastQuery;
}

@property (strong, nonatomic) VLCOSOFetcher *osoFetcher;
@property (strong, nonatomic) NSArray<VLCSubtitleItem *>* searchResults;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UILabel *nothingFoundLabel;
@property (strong, nonatomic) UISearchController *searchController;
@property (nonatomic) BOOL activityCancelled;

@end

@implementation VLCPlaybackInfoSubtitlesFetcherViewController

- (void)viewDidLoad {
    [super viewDidLoad];

#if TARGET_OS_TV
    self.titleLabel.text = self.title;
    self.tableView.backgroundColor = [UIColor clearColor];
#else
    [self setupDoneButton];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = NO;
        self.navigationItem.largeTitleDisplayMode = NO;
        
        // Setup search controller
        [self setupSearchController];
    }
#endif

    self.osoFetcher = [[VLCOSOFetcher alloc] init];
    self.osoFetcher.dataRecipient = self;
    [self.osoFetcher prepareForFetching];

    self.osoFetcher.subtitleLanguageCode = [self selectedSubtitleLanguageCode];
    
    // Setup activity indicator
    [self setupActivityIndicatorView];

    [self.view addSubview:self.activityIndicatorView];

    NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:self.activityIndicatorView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:yConstraint];
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:self.activityIndicatorView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:xConstraint];

    // Setup nothing found lable
    [self setupNothingFoundLabel];
    [self.view addSubview:self.nothingFoundLabel];

    yConstraint = [NSLayoutConstraint constraintWithItem:self.nothingFoundLabel
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:yConstraint];
    xConstraint = [NSLayoutConstraint constraintWithItem:self.nothingFoundLabel
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:xConstraint];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.nothingFoundLabel
                                                                   attribute:NSLayoutAttributeLeading
                                                                   relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeLeading
                                                                  multiplier:1.0
                                                                    constant:20.0];
    [self.view addConstraint:leftConstraint];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.nothingFoundLabel
                                                                   attribute:NSLayoutAttributeTrailing
                                                                   relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1.0
                                                                    constant:20.0];
    [self.view addConstraint:rightConstraint];

#if TARGET_OS_IOS
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];
#endif
}

- (NSString *)selectedSubtitleLanguageCode 
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *selectedLanguage = [defaults stringForKey:kVLCSettingLastUsedSubtitlesSearchLanguage];

    if (!selectedLanguage) {
        NSString *preferredLanguage = [[NSLocale preferredLanguages] firstObject];
        /* we may receive 'en-GB' so strip that to 'en' */
        if ([preferredLanguage containsString:@"-"]) {
            preferredLanguage = [[preferredLanguage componentsSeparatedByString:@"-"] firstObject];
        }

        /* last resort */
        if (selectedLanguage == nil) {
            selectedLanguage = @"en";
        }

        // Save selected locale
        [defaults setObject:selectedLanguage forKey:kVLCSettingLastUsedSubtitlesSearchLanguage];
    }

    return selectedLanguage;
}

#pragma mark - UI Elements setup

#if !TARGET_OS_TV
- (void)setupDoneButton
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    doneButton.accessibilityIdentifier = VLCAccessibilityIdentifier.done;

    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)setupSearchController API_AVAILABLE(ios(11))
{
    self.searchController = [[UISearchController alloc] init];
    self.searchController.hidesNavigationBarDuringPresentation = NO;

    self.searchController.searchBar.delegate = self;

    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
}
#endif

- (void)setupActivityIndicatorView
{
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] init];
    [self.activityIndicatorView setTranslatesAutoresizingMaskIntoConstraints:NO];

#if TARGET_OS_VISION
    self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleLarge;
#else
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleLarge;
    } else {
        self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
#endif

    self.activityIndicatorView.color = [UIColor lightGrayColor];
    self.activityIndicatorView.hidesWhenStopped = YES;
    [self.activityIndicatorView sizeToFit];
}

- (void)setupNothingFoundLabel 
{
    self.nothingFoundLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.nothingFoundLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

#if TARGET_OS_TV
    self.nothingFoundLabel.font = [UIFont italicSystemFontOfSize:32];
#else
    self.nothingFoundLabel.font = [UIFont italicSystemFontOfSize:16];
#endif

    self.nothingFoundLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NO_SUB_FOUND_OSO", nil), @""];
    self.nothingFoundLabel.textAlignment = NSTextAlignmentCenter;
    self.nothingFoundLabel.textColor = [UIColor blackColor];
    self.nothingFoundLabel.numberOfLines = 0;
    self.nothingFoundLabel.hidden = YES;

    [self.nothingFoundLabel sizeToFit];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#if TARGET_OS_IOS
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    /* the event handler in TabBarCoordinator cannot listen to the system because the movie view controller blocks the event
     * Therefore, we need to check the current theme ourselves */
    if (@available(iOS 13.0, *)) {
        if (previousTraitCollection.userInterfaceStyle == self.traitCollection.userInterfaceStyle) {
            return;
        }

        if ([[NSUserDefaults standardUserDefaults] integerForKey:kVLCSettingAppTheme] == kVLCSettingAppThemeSystem) {
            [PresentationTheme themeDidUpdate];
        }
        [self themeDidChange];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}

#endif

- (void)themeDidChange
{
#if TARGET_OS_TV
    if ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        self.visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.titleLabel.textColor = [UIColor VLCLightTextColor];
        self.nothingFoundLabel.textColor = [UIColor VLCLightTextColor];
    } else {
        self.visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.titleLabel.textColor = [UIColor VLCDarkTextColor];
        self.nothingFoundLabel.textColor = [UIColor VLCDarkTextColor];
    }
#else
    ColorPalette *colors = PresentationTheme.current.colors;
    [self.navigationItem.titleView setTintColor:colors.navigationbarTextColor];
    self.nothingFoundLabel.backgroundColor = self.view.backgroundColor = self.tableView.backgroundColor = colors.background;
    self.nothingFoundLabel.textColor = colors.cellTextColor;
    [self.tableView reloadData];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [self themeDidChange];
    [super viewWillAppear:animated];
}

#pragma mark - OSO Fetcher delegation

- (void)VLCOSOFetcherReadyToSearch:(VLCOSOFetcher *)aFetcher
{
    [self searchFor: [VLCPlaybackService sharedInstance].metadata.title];
}

- (void)searchFor:(NSString *)query
{
    [self startActivity];
    _lastQuery = query;

    self.osoFetcher.subtitleLanguageCode = [self selectedSubtitleLanguageCode];
    [self.osoFetcher searchForSubtitlesWithQuery:query];

    APLog(@"%s: query: '%@' language: '%@'", __func__, query, self.osoFetcher.subtitleLanguageCode);

    // Update searchbar text if it is not the same
    if (![self.searchController.searchBar.text isEqualToString:query]) {
        [self.searchController.searchBar setText:query];
    }
}

- (void)VLCOSOFetcher:(VLCOSOFetcher *)aFetcher didFindSubtitles:(NSArray<VLCSubtitleItem *> *)subtitles forSearchRequest:(NSString *)searchRequest
{
    NSUInteger count = subtitles.count;
    APLog(@"%s: %li items found", __func__, count);
    [self stopActivity];
    self.searchResults = subtitles;
    [self.tableView reloadData];

    if (count == 0) {
        self.nothingFoundLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NO_SUB_FOUND_OSO", nil), self.searchController.searchBar.text];
        self.nothingFoundLabel.hidden = NO;
    } else {
        self.nothingFoundLabel.hidden = YES;
    }
}

- (void)VLCOSOFetcher:(VLCOSOFetcher * _Nonnull)aFetcher didFailToFindSubtitlesForSearchRequest:(NSString * _Nonnull)searchRequest
{
    if (!self.activityCancelled) {
        return;
    }
    APLog(@"%s: failed to find subtitles for request %@", __func__, searchRequest);
    [self stopActivity];
    self.searchResults = @[];
    [self.tableView reloadData];

    self.nothingFoundLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NO_SUB_FOUND_OSO", nil), self.searchController.searchBar.text];
    self.nothingFoundLabel.hidden = NO;
    self.activityCancelled = NO;
}

- (void)VLCOSOFetcher:(VLCOSOFetcher *)aFetcher didFailToDownloadForItem:(VLCSubtitleItem *)subtitleItem withError:(nonnull NSError *)error
{
    [self stopActivity];

    // Show error alert
    UIAlertController *alert = [UIAlertController 
                                alertControllerWithTitle:NSLocalizedString(@"ERROR", nil)
                                message:error.localizedDescription
                                preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction 
                                    actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    }];

    [alert addAction:defaultAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)VLCOSOFetcher:(VLCOSOFetcher *)aFetcher subtitleDownloadSucceededForItem:(VLCSubtitleItem *)subtitleItem atPath:(NSString *)pathToFile
{
    APLog(@"%s: %@", __func__, subtitleItem.name);
    [self stopActivity];
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    [vpc addSubtitlesToCurrentPlaybackFromURL:[NSURL fileURLWithPath:pathToFile]];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackServicePlaybackMetadataDidChange object:nil];
}

#pragma mark - table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }

    if (self.searchResults) {
        return self.searchResults.count;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SPUDownloadReUseIdentifier];

    if (!cell) {
#if TARGET_OS_TV
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SPUDownloadReUseIdentifier];
#else
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SPUDownloadReUseIdentifier];
#endif
    }
    
    if (indexPath.section != 0) {
        VLCSubtitleItem *item = self.searchResults[indexPath.row];
        cell.textLabel.text = item.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ fps - %@", item.fps, item.rating];

        if (item.hd) {
            cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingString:@" - HD"];
        }

        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.textLabel.text = NSLocalizedString(@"LANGUAGE", nil);

        // Get selected subtitle language code
        NSString *selectedLanguageCode = [self selectedSubtitleLanguageCode];
        // Get localized name of the code
        NSString *localizedLanguageName = [[NSLocale currentLocale] localizedStringForLanguageCode:selectedLanguageCode];

        cell.detailTextLabel.text = localizedLanguageName ? localizedLanguageName : selectedLanguageCode;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

#if TARGET_OS_IOS
    ColorPalette *colors = PresentationTheme.current.colors;
    cell.backgroundColor = (indexPath.row % 2 == 0)? colors.cellBackgroundA : colors.cellBackgroundB;
    cell.selectedBackgroundView.backgroundColor = colors.mediaCategorySeparatorColor;
    cell.textLabel.textColor = colors.cellTextColor;
    cell.detailTextLabel.textColor = colors.cellDetailTextColor;
#endif

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"";
    }

    return section == 1 && self.searchResults.count > 0
    ? NSLocalizedString(@"FOUND_SUBS", nil)
    : @"";
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#if TARGET_OS_IOS
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
#endif

    if (indexPath.section == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"LANGUAGE", nil)
                                                                                 message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        NSArray<VLCSubtitleLanguage *> *languages = self.osoFetcher.availableLanguages;
        NSString *selectedLanguageCode = [self selectedSubtitleLanguageCode];

        for (VLCSubtitleLanguage *item in languages) {
            NSString *languageCode = item.languageCode;
            NSString *localizedLanguageName = [[NSLocale currentLocale] localizedStringForLanguageCode:languageCode];

            // If localized language code not found, use the code
            if (!localizedLanguageName) {
                localizedLanguageName = languageCode;
            }

            UIAlertAction *action = [UIAlertAction actionWithTitle:localizedLanguageName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                // Set service's language code
                self.osoFetcher.subtitleLanguageCode = languageCode;

                // Save the selected language
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:languageCode forKey:kVLCSettingLastUsedSubtitlesSearchLanguage];

                // Update tableView
                [self searchFor: [VLCPlaybackService sharedInstance].metadata.title];
                [self.tableView reloadData];
            }];

            [alertController addAction:action];
            if ([languageCode isEqualToString:selectedLanguageCode])
                [alertController setPreferredAction:action];
        }

        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil]];

        UIView *currentCell = [tableView cellForRowAtIndexPath:indexPath];

        alertController.popoverPresentationController.sourceView = currentCell;
        alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        alertController.popoverPresentationController.sourceRect = currentCell.bounds;
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [self startActivity];

        VLCSubtitleItem *item = self.searchResults[indexPath.row];
        NSURL *subStorageDirectory;
        NSFileManager *fileManager = [NSFileManager defaultManager];
#if TARGET_OS_IOS
        /* on iOS, we try to retain the subtitles if the played media is stored locally */
        VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
        NSURL *mediaURL = vpc.currentlyPlayingMedia.url;
        if (mediaURL.isFileURL) {
            /* that the media is a file URL does not mean that we can dump a subtitles file next to it
             * tl;dr we may write to the Documents-folder only, but not to the potential Inbox folder stored within
             * that needs to be treated as read-only */
            NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentFolderPath = [searchPaths firstObject];
            NSString *potentialInboxFolderPath = [documentFolderPath stringByAppendingPathComponent:@"Inbox"];
            NSString *mediaURLpath = mediaURL.path;
            if (![mediaURLpath containsString:potentialInboxFolderPath] && [mediaURLpath containsString:documentFolderPath]) {
                /* the media is stored in the Documents folder but not in Inbox */
                NSString *mediaPath = mediaURL.path;
                subStorageDirectory = [NSURL fileURLWithPath:[mediaPath stringByDeletingLastPathComponent] isDirectory:YES];

                /* make extra sure that we may write in the surrounding folder, otherwise drop it and save in caches */
                if (![fileManager isWritableFileAtPath:[mediaPath stringByDeletingLastPathComponent]]) {
                    subStorageDirectory = nil;
                }
            }

            if (!subStorageDirectory) {
                /* cache the downloaded subtitle in a writeable cache folder that is eventually emptied by the OS */
                searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                NSString *cacheFolderPath = [searchPaths.firstObject stringByAppendingPathComponent:kVLCSubtitlesCacheFolderName];
                [fileManager createDirectoryAtPath:cacheFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
                subStorageDirectory = [NSURL fileURLWithPath:cacheFolderPath isDirectory:YES];
            }
        }
        if (!subStorageDirectory) {
#endif
            /* media is not a file or we are on tvOS, then just store the downloaded subtitle under its own name
             * and have it deleted by the OS some day through the cache folder */
            NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *folderPath = [searchPaths.firstObject stringByAppendingPathComponent:kVLCSubtitlesCacheFolderName];
            [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
            subStorageDirectory = [NSURL fileURLWithPath:folderPath isDirectory:YES];
#if TARGET_OS_IOS
        }
#endif
        [self.osoFetcher downloadSubtitleItem:item toDirectory:subStorageDirectory];
    }
}

#pragma mark - Search bar delegate

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar 
{
#if TARGET_OS_IOS
    [searchBar setShowsCancelButton:NO animated:YES];
#endif

    if (searchBar.text.length == 0) {
        return;
    }

    [self searchFor:searchBar.text];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
#if TARGET_OS_IOS
    [searchBar setShowsCancelButton:YES animated:YES];
#endif
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar 
{
    NSString *lastQuery = _lastQuery;

    // When cancel button clicked, the searchbar's text will be removed. This is a simply workaround for it.
    // This will change searchbar text to latest query to match the results on tableview.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1)), dispatch_get_main_queue(), ^{
        searchBar.text = lastQuery;
    });
}

#pragma mark - Activity controls

- (void)startActivity
{
    [self.activityIndicatorView startAnimating];
    self.activityCancelled = NO;
    [self performSelector:@selector(cancelActivity) withObject:nil afterDelay:20.];
    self.nothingFoundLabel.hidden = YES;
}

- (void)stopActivity
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelActivity) object:nil];
    [self.activityIndicatorView stopAnimating];
}

- (void)cancelActivity
{
    self.activityCancelled = YES;
    [self VLCOSOFetcher:self.osoFetcher didFailToFindSubtitlesForSearchRequest:@"cancellation request"];
}

@end
