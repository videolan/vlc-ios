/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerSearchBrowser.h"

@interface VLCNetworkServerSearchBrowser()
@property (nonatomic) id<VLCNetworkServerBrowser> serverBrowser;
@property (nonatomic, copy, nullable) NSIndexSet *filteredIndexes;
@property (nonatomic, copy, null_resettable) NSArray<id<VLCNetworkServerBrowserItem>> *filteredItems;
@property (nonatomic, null_resettable) VLCMediaList *filteredMediaList;
@end

@implementation VLCNetworkServerSearchBrowser
@synthesize delegate = _delegate;


- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)serverBrowser
{
    self = [super init];
    if (self) {
        _serverBrowser = serverBrowser;
    }
    return self;
}

- (NSString *)title
{
    return self.serverBrowser.title;
}

- (VLCMediaList *)mediaList
{
    return self.filteredMediaList;
}

- (NSArray<id<VLCNetworkServerBrowserItem>> *)items
{
    return self.filteredItems;
}

- (void)update
{
    [self.serverBrowser update];
}

- (void)setSearchText:(NSString *)searchText
{
    if (![_searchText isEqualToString:searchText]) {
        _searchText = searchText;
        [self updateFilteredItems];
        [self.delegate networkServerBrowserDidUpdate:self];
    }
}

#pragma mark - filtering
- (void)setFilteredIndexes:(NSIndexSet *)filteredIndexes
{
    BOOL needUpdate = NO;
    if (_filteredIndexes) {
        needUpdate = ![_filteredIndexes isEqualToIndexSet:filteredIndexes];
    } else if (filteredIndexes) {
        needUpdate = YES;
    }
    if (needUpdate) {
        _filteredIndexes = [filteredIndexes copy];

        self.filteredItems = nil;
        self.filteredMediaList = nil;
    }
}
- (NSArray<id<VLCNetworkServerBrowserItem>> *)filteredItems
{
    if (!_filteredItems) {
        NSIndexSet *indexes = self.filteredIndexes;
        NSArray<id<VLCNetworkServerBrowserItem>> *items = self.serverBrowser.items;
        _filteredItems = indexes ? [items objectsAtIndexes:indexes] : items;
    }
    return _filteredItems;
}

- (VLCMediaList *)filteredMediaList
{
    if (!_filteredMediaList) {
        NSIndexSet *indexes = self.filteredIndexes;
        VLCMediaList *mediaList = self.serverBrowser.mediaList;
        if (indexes) {
            __block NSUInteger count = 0;
            VLCMediaList *filteredMediaList = [[VLCMediaList alloc] initWithArray:nil];
            [filteredMediaList lock];
            [mediaList lock];
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                VLCMedia *media = [mediaList mediaAtIndex:idx];
                [filteredMediaList insertMedia:media atIndex:count];
                ++count;
            }];
            [mediaList unlock];
            [filteredMediaList unlock];

            _filteredMediaList = filteredMediaList;
        } else {
            _filteredMediaList = mediaList;
        }
    }
    return _filteredMediaList;
}

- (void)updateFilteredItems
{
    NSIndexSet *filteredIndexes = nil;
    if (self.searchText.length) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[cd] %@",self.searchText];

        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        NSArray<id<VLCNetworkServerBrowserItem>> *items = self.serverBrowser.items;
        [items enumerateObjectsUsingBlock:^(id<VLCNetworkServerBrowserItem>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([predicate evaluateWithObject:obj]) {
                [indexSet addIndex:idx];
            }
        }];
        filteredIndexes = indexSet;
    }
    self.filteredIndexes = filteredIndexes;
}


#pragma mark - VLCNetworkServerBrowserDelegate

- (void)networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser
{
    [self updateFilteredItems];
    [self.delegate networkServerBrowserDidUpdate:self];
}

- (void)networkServerBrowser:(id<VLCNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error
{
    [self.delegate networkServerBrowser:self requestDidFailWithError:error];
}

@end
