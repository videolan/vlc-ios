/*****************************************************************************
 * VLCPodcastDirectoryLanguageViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPodcastDirectoryLanguageViewController.h"
#import "VLCPodcastIndexService.h"

#import "VLC-Swift.h"

static NSString *const VLCPodcastDirectoryLanguageCellIdentifier = @"PodcastDirectoryLanguageCell";
static NSString *const VLCPodcastDirectoryLanguageHeaderIdentifier = @"PodcastDirectoryLanguageHeader";

@implementation VLCPodcastDirectoryLanguageViewController
{
    VLCPodcastIndexService *_service;
    NSArray<NSString *> *_sectionTitles;
    NSArray<NSArray<NSString *> *> *_sectionedCodes;
    NSArray<NSString *> *_searchResults;
    NSDictionary<NSString *, NSString *> *_displayNames;
    NSDictionary<NSString *, NSString *> *_nativeNames;
}

- (instancetype)initWithService:(VLCPodcastIndexService *)service
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _service = service;
    }
    return self;
}

- (UITableViewStyle)tableViewStyle
{
    return UITableViewStyleInsetGrouped;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"PODCAST_DIRECTORY_LANGUAGE", nil);
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self removePlayAllAction];
    [self stopActivityIndicator];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:VLCPodcastDirectoryLanguageCellIdentifier];
    [self.tableView registerClass:[UITableViewHeaderFooterView class]
        forHeaderFooterViewReuseIdentifier:VLCPodcastDirectoryLanguageHeaderIdentifier];

    [self rebuildSections];
    [self themeDidChange];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeDidChange)
                                                 name:kVLCThemeDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = NO;
}

- (void)themeDidChange
{
    ColorPalette *colors = PresentationTheme.current.colors;
    self.tableView.backgroundColor = colors.background;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = colors.separatorColor;
    [self.tableView reloadData];
}

#pragma mark - languages

- (BOOL)isSearching
{
    return self.searchController.isActive && self.searchController.searchBar.text.length > 0;
}

- (NSString *)capitalizedName:(NSString *)name locale:(NSLocale *)locale
{
    if (name.length == 0) {
        return name;
    }

    NSRange initial = [name rangeOfComposedCharacterSequenceAtIndex:0];
    return [name stringByReplacingCharactersInRange:initial
                                         withString:[[name substringWithRange:initial] uppercaseStringWithLocale:locale]];
}

- (void)rebuildSections
{
    NSArray<NSString *> *suggestedCodes = _service.suggestedLanguageCodes;
    NSMutableArray<NSString *> *moreCodes = [NSMutableArray array];
    for (NSString *code in _service.availableLanguageCodes) {
        if (![suggestedCodes containsObject:code]) {
            [moreCodes addObject:code];
        }
    }

    NSLocale *currentLocale = [NSLocale currentLocale];
    NSMutableDictionary<NSString *, NSString *> *displayNames = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSString *> *nativeNames = [NSMutableDictionary dictionary];

    for (NSString *code in [suggestedCodes arrayByAddingObjectsFromArray:moreCodes]) {
        NSString *displayName = [self capitalizedName:[currentLocale localizedStringForLanguageCode:code] ?: code
                                               locale:currentLocale];
        displayNames[code] = displayName;

        NSLocale *nativeLocale = [NSLocale localeWithLocaleIdentifier:code];
        NSString *nativeName = [self capitalizedName:[nativeLocale localizedStringForLanguageCode:code]
                                              locale:nativeLocale];
        if (nativeName.length > 0 && [nativeName localizedCaseInsensitiveCompare:displayName] != NSOrderedSame) {
            nativeNames[code] = nativeName;
        }
    }

    _displayNames = displayNames;
    _nativeNames = nativeNames;

    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    NSMutableArray<NSArray<NSString *> *> *sections = [NSMutableArray array];
    if (suggestedCodes.count > 0) {
        [titles addObject:NSLocalizedString(@"PODCAST_DIRECTORY_LANGUAGE_SUGGESTED", nil)];
        [sections addObject:suggestedCodes];
    }
    if (moreCodes.count > 0) {
        [titles addObject:NSLocalizedString(@"PODCAST_DIRECTORY_LANGUAGE_MORE", nil)];
        [sections addObject:moreCodes];
    }

    _sectionTitles = titles;
    _sectionedCodes = sections;
}

- (NSString *)codeAtIndexPath:(NSIndexPath *)indexPath
{
    return [self isSearching] ? _searchResults[indexPath.row] : _sectionedCodes[indexPath.section][indexPath.row];
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self isSearching] ? 1 : _sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self isSearching] ? _searchResults.count : _sectionedCodes[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCPodcastDirectoryLanguageCellIdentifier
                                                            forIndexPath:indexPath];
    NSString *code = [self codeAtIndexPath:indexPath];
    NSString *displayName = _displayNames[code];
    NSString *nativeName = _nativeNames[code];
    ColorPalette *colors = PresentationTheme.current.colors;

    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = displayName;
    content.textProperties.color = colors.cellTextColor;
    content.secondaryText = nativeName;
    content.secondaryTextProperties.color = colors.cellDetailTextColor;
    cell.contentConfiguration = content;

    cell.backgroundColor = colors.cardBackground;
    cell.tintColor = colors.orangeUI;
    cell.accessoryType = [code isEqualToString:_service.languageCode] ? UITableViewCellAccessoryCheckmark
                                                                      : UITableViewCellAccessoryNone;

    NSMutableAttributedString *accessibilityLabel = [[NSMutableAttributedString alloc] initWithString:displayName];
    if (nativeName) {
        [accessibilityLabel appendAttributedString:[[NSAttributedString alloc] initWithString:@", "]];
        [accessibilityLabel appendAttributedString:[[NSAttributedString alloc] initWithString:nativeName
                                                                                   attributes:@{ UIAccessibilitySpeechAttributeLanguage: code }]];
    }
    cell.accessibilityAttributedLabel = accessibilityLabel;

    return cell;
}

#pragma mark - table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self isSearching]) {
        return nil;
    }

    UITableViewHeaderFooterView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:VLCPodcastDirectoryLanguageHeaderIdentifier];
    UIListContentConfiguration *content = [UIListContentConfiguration groupedHeaderConfiguration];
    content.text = _sectionTitles[section];
    content.textProperties.color = PresentationTheme.current.colors.sectionHeaderTextColor;
    header.contentConfiguration = content;
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self isSearching] ? CGFLOAT_MIN : UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    _service.languageCode = [self codeAtIndexPath:indexPath];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *query = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSStringCompareOptions options = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    NSMutableArray<NSString *> *results = [NSMutableArray array];

    for (NSArray<NSString *> *codes in _sectionedCodes) {
        for (NSString *code in codes) {
            NSString *nativeName = _nativeNames[code];
            if ([_displayNames[code] rangeOfString:query options:options].location != NSNotFound
                || (nativeName && [nativeName rangeOfString:query options:options].location != NSNotFound)) {
                [results addObject:code];
            }
        }
    }

    _searchResults = results;
    [self.tableView reloadData];
}

@end
