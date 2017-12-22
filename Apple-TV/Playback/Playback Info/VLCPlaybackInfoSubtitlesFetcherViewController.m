/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoSubtitlesFetcherViewController.h"
#import "MetadataFetcherKit.h"
#import "NSString+Locale.h"
#import "VLCMetadata.h"

#define SPUDownloadReUseIdentifier @"SPUDownloadReUseIdentifier"
#define SPUDownloadHeaderReUseIdentifier @"SPUDownloadHeaderReUseIdentifier"

@interface VLCPlaybackInfoSubtitlesFetcherViewController () <UITableViewDataSource, UITableViewDelegate, MDFOSOFetcherDataRecipient>
{
    MDFOSOFetcher *_osoFetcher;
    NSArray <MDFSubtitleItem *>* _searchResults;
    UIActivityIndicatorView *_activityIndicatorView;
}
@end

@implementation VLCPlaybackInfoSubtitlesFetcherViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleLabel.text = self.title;
    self.tableView.backgroundColor = [UIColor clearColor];

    _osoFetcher = [[MDFOSOFetcher alloc] init];
    _osoFetcher.userAgentKey = @"VLSub 0.9";
    _osoFetcher.dataRecipient = self;
    [_osoFetcher prepareForFetching];

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
    _osoFetcher.subtitleLanguageId = selectedLocale;

    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_activityIndicatorView sizeToFit];
    [_activityIndicatorView setTranslatesAutoresizingMaskIntoConstraints:NO];
    _activityIndicatorView.hidesWhenStopped = YES;
    [self.view addSubview:_activityIndicatorView];

    NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:_activityIndicatorView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:yConstraint];
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:_activityIndicatorView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:xConstraint];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        self.visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.titleLabel.textColor = [UIColor VLCLightTextColor];
    } else {
        self.visualEffectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.titleLabel.textColor = [UIColor VLCDarkTextColor];
    }

    [super viewWillAppear:animated];
}

#pragma mark - OSO Fetcher delegation

- (void)MDFOSOFetcher:(MDFOSOFetcher *)aFetcher readyToSearch:(BOOL)bValue
{
    if (!bValue)
        return;

    [self searchForMedia];
}

- (void)searchForMedia
{
    [self startActivity];
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _osoFetcher.subtitleLanguageId = [defaults stringForKey:kVLCSettingLastUsedSubtitlesSearchLanguage];
    [_osoFetcher searchForSubtitlesWithQuery:vpc.metadata.title];
}

- (void)MDFOSOFetcher:(MDFOSOFetcher *)aFetcher didFindSubtitles:(NSArray<MDFSubtitleItem *> *)subtitles forSearchRequest:(NSString *)searchRequest
{
    [self stopActivity];
    _searchResults = subtitles;
    [self.tableView reloadData];
}

- (void)MDFOSOFetcher:(MDFOSOFetcher *)aFetcher didFailToDownloadForItem:(MDFSubtitleItem *)subtitleItem
{
    [self stopActivity];
    // FIXME: missing error handling
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)MDFOSOFetcher:(MDFOSOFetcher *)aFetcher subtitleDownloadSucceededForItem:(MDFSubtitleItem *)subtitleItem atPath:(NSString *)pathToFile
{
    [self stopActivity];
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc openVideoSubTitlesFromFile:pathToFile];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:nil];
}

#pragma mark - table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 1;

    if (_searchResults) {
        return _searchResults.count;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SPUDownloadReUseIdentifier];

    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SPUDownloadReUseIdentifier];

    if (indexPath.section != 0) {
        MDFSubtitleItem *item = _searchResults[indexPath.row];
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

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"";

    return NSLocalizedString(@"FOUND_SUBS", nil);
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"LANGUAGE", nil)
                                                                                 message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        NSArray<MDFSubtitleLanguage *> *languages = _osoFetcher.availableLanguages;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *currentCode = [defaults stringForKey:kVLCSettingLastUsedSubtitlesSearchLanguage];

        for (MDFSubtitleLanguage *item in languages) {
            NSString *itemID = item.ID;
            UIAlertAction *action = [UIAlertAction actionWithTitle:item.localizedName
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               _osoFetcher.subtitleLanguageId = itemID;
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

        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [self startActivity];
        MDFSubtitleItem *item = _searchResults[indexPath.row];
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *folderPath = [searchPaths[0] stringByAppendingPathComponent:@"tempsubs"];
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *subStorageLocation = [folderPath stringByAppendingPathComponent:item.name];
        [_osoFetcher downloadSubtitleItem:item toPath:subStorageLocation];
    }
}

- (void)startActivity
{
    [_activityIndicatorView startAnimating];
    self.tableView.userInteractionEnabled = NO;
}

- (void)stopActivity
{
    [_activityIndicatorView stopAnimating];
    self.tableView.userInteractionEnabled = YES;
}

@end
