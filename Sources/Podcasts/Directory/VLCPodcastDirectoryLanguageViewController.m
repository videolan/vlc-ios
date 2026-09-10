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

@implementation VLCPodcastDirectoryLanguageViewController
{
    VLCPodcastIndexService *_service;
    NSArray<NSString *> *_sectionTitles;
    NSArray<NSArray<NSString *> *> *_sectionedCodes;
    NSArray<NSString *> *_searchResults;
}

- (instancetype)initWithService:(VLCPodcastIndexService *)service
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _service = service;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"PODCAST_DIRECTORY_LANGUAGE", nil);
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self removePlayAllAction];
    [self stopActivityIndicator];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:VLCPodcastDirectoryLanguageCellIdentifier];

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
    self.tableView.sectionIndexColor = colors.orangeUI;
    [self.tableView reloadData];
}

#pragma mark - languages

- (BOOL)isSearching
{
    return self.searchController.isActive && self.searchController.searchBar.text.length > 0;
}

- (NSString *)displayNameForCode:(NSString *)code
{
    return [[NSLocale currentLocale] localizedStringForLanguageCode:code] ?: code;
}

- (void)rebuildSections
{
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    NSMutableArray<NSMutableArray<NSString *> *> *sections = [NSMutableArray array];

    for (NSString *code in _service.availableLanguageCodes) {
        NSString *initial = [self sectionTitleForName:[self displayNameForCode:code]];
        if (titles.count == 0 || ![titles.lastObject isEqualToString:initial]) {
            [titles addObject:initial];
            [sections addObject:[NSMutableArray array]];
        }
        [sections.lastObject addObject:code];
    }

    _sectionTitles = titles;
    _sectionedCodes = sections;
}

- (NSString *)sectionTitleForName:(NSString *)name
{
    if (name.length == 0) {
        return @"#";
    }

    NSString *initial = [name substringWithRange:[name rangeOfComposedCharacterSequenceAtIndex:0]];
    initial = [initial stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]].uppercaseString;
    if (initial.length == 0 || ![[NSCharacterSet letterCharacterSet] characterIsMember:[initial characterAtIndex:0]]) {
        return @"#";
    }

    return [initial substringWithRange:[initial rangeOfComposedCharacterSequenceAtIndex:0]];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self isSearching] ? nil : _sectionTitles[section];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self isSearching] ? nil : _sectionTitles;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCPodcastDirectoryLanguageCellIdentifier
                                                            forIndexPath:indexPath];
    NSString *code = [self codeAtIndexPath:indexPath];
    ColorPalette *colors = PresentationTheme.current.colors;

    cell.textLabel.text = [self displayNameForCode:code];
    cell.textLabel.textColor = colors.cellTextColor;
    cell.backgroundColor = colors.background;
    cell.tintColor = colors.orangeUI;
    cell.accessoryType = [code isEqualToString:_service.languageCode] ? UITableViewCellAccessoryCheckmark
                                                                      : UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark - table view delegate

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
    NSMutableArray<NSString *> *results = [NSMutableArray array];

    for (NSArray<NSString *> *codes in _sectionedCodes) {
        for (NSString *code in codes) {
            NSRange range = [[self displayNameForCode:code] rangeOfString:query
                                                                  options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
            if (range.location != NSNotFound) {
                [results addObject:code];
            }
        }
    }

    _searchResults = results;
    [self.tableView reloadData];
}

@end
