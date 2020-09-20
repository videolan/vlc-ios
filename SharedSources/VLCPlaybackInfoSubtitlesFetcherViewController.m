/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoSubtitlesFetcherViewController.h"
#import "VLCOSOFetcher.h"
#import "VLCSubtitleItem.h"
#import "NSString+Locale.h"
#import "VLCMetadata.h"
#import "VLCPlaybackService.h"
#if !TARGET_OS_TV
#import "VLC-Swift.h"
#endif

#define SPUDownloadReUseIdentifier @"SPUDownloadReUseIdentifier"
#define SPUDownloadHeaderReUseIdentifier @"SPUDownloadHeaderReUseIdentifier"

@interface VLCPlaybackInfoSubtitlesFetcherViewController () <UITableViewDataSource, UITableViewDelegate, VLCOSOFetcherDataRecipient>

@property (strong, nonatomic) VLCOSOFetcher *osoFetcher;
@property (strong, nonatomic) NSArray<VLCSubtitleItem *>* searchResults;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation VLCPlaybackInfoSubtitlesFetcherViewController

- (void)viewDidLoad {
    [super viewDidLoad];

#if TARGET_OS_TV
    self.titleLabel.text = self.title;
    self.tableView.backgroundColor = [UIColor clearColor];
#else
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    doneButton.accessibilityIdentifier = VLCAccessibilityIdentifier.done;

    self.navigationItem.rightBarButtonItem = doneButton;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
#endif

    self.osoFetcher = [[VLCOSOFetcher alloc] init];
    self.osoFetcher.dataRecipient = self;
    [self.osoFetcher prepareForFetching];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *selectedLocale = [defaults stringForKey:kVLCSettingLastUsedSubtitlesSearchLanguage];
    if (!selectedLocale) {
        NSString *preferredLanguage = [[NSLocale preferredLanguages] firstObject];
        /* we may receive 'en-GB' so strip that to 'en' */
        if ([preferredLanguage containsString:@"-"]) {
            preferredLanguage = [[preferredLanguage componentsSeparatedByString:@"-"] firstObject];
        }
        selectedLocale = [preferredLanguage VLCthreeLetterLanguageKeyForTwoLetterCode];
        /* last resort */
        if (selectedLocale == nil) {
            selectedLocale = @"eng";
        }
        [defaults setObject:selectedLocale forKey:kVLCSettingLastUsedSubtitlesSearchLanguage];
    }
    self.osoFetcher.subtitleLanguageId = selectedLocale;

    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.activityIndicatorView sizeToFit];
    [self.activityIndicatorView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.activityIndicatorView.hidesWhenStopped = YES;
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

#if TARGET_OS_IOS
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];
#endif
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
            BOOL isSystemDarkTheme = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
            PresentationTheme.current = isSystemDarkTheme ? PresentationTheme.darkTheme : PresentationTheme.brightTheme;
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
    } else {
        self.visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.titleLabel.textColor = [UIColor VLCDarkTextColor];
    }
#else
    ColorPalette *colors = PresentationTheme.current.colors;
    [self.navigationItem.titleView setTintColor:colors.navigationbarTextColor];
    self.view.backgroundColor = self.tableView.backgroundColor = colors.background;
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
    [self searchForMedia];
}

- (void)searchForMedia
{
    [self startActivity];
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.osoFetcher.subtitleLanguageId = [defaults stringForKey:kVLCSettingLastUsedSubtitlesSearchLanguage];
    APLog(@"%s: query: '%@' language: '%@'", __func__, self.osoFetcher.subtitleLanguageId, vpc.metadata.title);
    [self.osoFetcher searchForSubtitlesWithQuery:vpc.metadata.title];
}

- (void)VLCOSOFetcher:(VLCOSOFetcher *)aFetcher didFindSubtitles:(NSArray<VLCSubtitleItem *> *)subtitles forSearchRequest:(NSString *)searchRequest
{
    APLog(@"%s: %li items found", __func__, subtitles.count);
    [self stopActivity];
    self.searchResults = subtitles;
    [self.tableView reloadData];
}

- (void)VLCOSOFetcher:(VLCOSOFetcher *)aFetcher didFailToDownloadForItem:(VLCSubtitleItem *)subtitleItem
{
    [self stopActivity];
    // FIXME: missing error handling
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)VLCOSOFetcher:(VLCOSOFetcher *)aFetcher subtitleDownloadSucceededForItem:(VLCSubtitleItem *)subtitleItem atPath:(NSString *)pathToFile
{
    [self stopActivity];
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    [vpc openVideoSubTitlesFromFile:pathToFile];
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
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", item.rating, [item.format uppercaseStringWithLocale:[NSLocale currentLocale]]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        NSString *selectedLocale = [[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingLastUsedSubtitlesSearchLanguage];
        cell.textLabel.text = NSLocalizedString(@"LANGUAGE", nil);
        NSString *detail = [[selectedLocale VLCtwoLetterLanguageKeyForThreeLetterCode] VLClocalizedLanguageNameForTwoLetterCode];
        cell.detailTextLabel.text = detail ? detail : selectedLocale;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

#if TARGET_OS_IOS
    cell.backgroundColor = (indexPath.row % 2 == 0)? PresentationTheme.current.colors.cellBackgroundA : PresentationTheme.current.colors.cellBackgroundB;
    cell.selectedBackgroundView.backgroundColor = PresentationTheme.current.colors.mediaCategorySeparatorColor;
    cell.textLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    cell.detailTextLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor;
#endif

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"";
    }

    return NSLocalizedString(@"FOUND_SUBS", nil);
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
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *currentCode = [defaults stringForKey:kVLCSettingLastUsedSubtitlesSearchLanguage];

        for (VLCSubtitleLanguage *item in languages) {
            NSString *itemID = item.ID;
            UIAlertAction *action = [UIAlertAction actionWithTitle:item.localizedName
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               self.osoFetcher.subtitleLanguageId = itemID;
                                                               [defaults setObject:itemID forKey:kVLCSettingLastUsedSubtitlesSearchLanguage];
                                                               [self searchForMedia];
                                                               [self.tableView reloadData];
                                                           }];
            [alertController addAction:action];
            if ([itemID isEqualToString:currentCode])
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
        NSString *subStorageLocation;
#if TARGET_OS_IOS
        /* on iOS, we try to retain the subtitles if the played media is stored locally */
        VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
        NSURL *mediaURL = vpc.currentlyPlayingMedia.url;
        if (mediaURL.isFileURL) {
            subStorageLocation = [[mediaURL.path stringByDeletingPathExtension] stringByAppendingPathExtension:item.format];
        } else {
#endif
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *folderPath = [searchPaths[0] stringByAppendingPathComponent:@"tempsubs"];
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        subStorageLocation = [folderPath stringByAppendingPathComponent:item.name];
#if TARGET_OS_IOS
        }
#endif
        [self.osoFetcher downloadSubtitleItem:item toPath:subStorageLocation];
    }
}

- (void)startActivity
{
    [self.activityIndicatorView startAnimating];
}

- (void)stopActivity
{
    [self.activityIndicatorView stopAnimating];
}

@end
