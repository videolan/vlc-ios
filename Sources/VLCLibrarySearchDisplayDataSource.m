/*****************************************************************************
 * VLCLibrarySearchDisplayDataSource.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLibrarySearchDisplayDataSource.h"
#import "VLCPlaylistTableViewCell.h"
#import "VLCPlaylistCollectionViewCell.h"

@interface VLCLibrarySearchDisplayDataSource() <UITableViewDataSource>
{
    NSMutableArray *_searchData;
}
@end

@implementation VLCLibrarySearchDisplayDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        _searchData = [NSMutableArray new];
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _searchData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaylistTableViewCell *cell = (VLCPlaylistTableViewCell *)[tableView dequeueReusableCellWithIdentifier:VLCPlaylistTableViewCell.cellIdentifier forIndexPath:indexPath];

    NSInteger row = indexPath.row;

    if (row < _searchData.count)
        cell.mediaObject = _searchData[row];

    return cell;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    VLCPlaylistCollectionViewCell *cell = (VLCPlaylistCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VLCPlaylistCollectionViewCell.cellIdentifier forIndexPath:indexPath];

    NSInteger row = indexPath.row;

    if (row < _searchData.count)
        cell.mediaObject = _searchData[row];

    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _searchData.count;
}

- (NSManagedObject *)objectAtIndex:(NSUInteger)index
{
    return index < _searchData.count ? _searchData[index] : nil;
}

- (void)shouldReloadTableForSearchString:(NSString *)searchString searchableFiles:(NSArray *)files
{
    if (!searchString || [searchString isEqualToString:@""]) {
        _searchData = [files mutableCopy];
        return;
    }

    [_searchData removeAllObjects];
    NSRange nameRange;

    for (NSManagedObject *item in files) {

        if ([item isKindOfClass:[MLAlbum class]]) {
            nameRange = [self _searchAlbum:(MLAlbum *)item forString:searchString];
        } else if ([item isKindOfClass:[MLAlbumTrack class]]) {
            nameRange = [self _searchAlbumTrack:(MLAlbumTrack *)item forString:searchString];
        } else if ([item isKindOfClass:[MLShowEpisode class]]) {
            nameRange = [self _searchShowEpisode:(MLShowEpisode *)item forString:searchString];
        } else if ([item isKindOfClass:[MLShow class]]) {
            nameRange = [self _searchShow:(MLShow *)item forString:searchString];
        } else if ([item isKindOfClass:[MLLabel class]])
            nameRange = [self _searchLabel:(MLLabel *)item forString:searchString];
        else // simple file
            nameRange = [self _searchFile:(MLFile*)item forString:searchString];

        if (nameRange.location != NSNotFound)
            [_searchData addObject:item];
    }
}

- (NSRange)_searchAlbumTrack:(MLAlbumTrack *)albumTrack forString:(NSString *)searchString
{
    NSString *trackTitle = albumTrack.title;
    NSRange nameRange = [trackTitle rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (nameRange.location != NSNotFound)
        return nameRange;

    NSMutableArray *stringsToSearch = [[NSMutableArray alloc] initWithObjects:trackTitle, nil];
    if ([albumTrack artist])
        [stringsToSearch addObject:[albumTrack artist]];
    if ([albumTrack genre])
        [stringsToSearch addObject:[albumTrack genre]];

    NSArray *substrings = [searchString componentsSeparatedByString:@" "];
    NSUInteger substringCount = substrings.count;
    NSUInteger searchStringCount = stringsToSearch.count;

    for (NSUInteger x = 0; x < substringCount; x++) {
        for (NSUInteger y = 0; y < searchStringCount; y++) {
            nameRange = [stringsToSearch[y] rangeOfString:substrings[x] options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound)
                break;
        }
        if (nameRange.location != NSNotFound)
            break;
    }
    return nameRange;
}

- (NSRange)_searchAlbum:(MLAlbum *)album forString:(NSString *)searchString
{
    NSString *albumName = [album name];
    NSRange nameRange = [albumName rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (nameRange.location != NSNotFound)
        return nameRange;

    if ([album releaseYear]) {
        nameRange = [[album releaseYear] rangeOfString:searchString options:NSCaseInsensitiveSearch];
        if (nameRange.location != NSNotFound)
            return nameRange;
    }

    /* split search string into substrings and try again */
    NSArray *substrings = [searchString componentsSeparatedByString:@" "];
    NSUInteger substringCount = substrings.count;
    if (substringCount > 1) {
        for (NSUInteger x = 0; x < substringCount; x++) {
            nameRange = [searchString rangeOfString:substrings[x] options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound)
                break;
        }
    }

    if (nameRange.location != NSNotFound)
        return nameRange;

    /* search our tracks if we can't find what the user is looking for */
    NSArray *tracks = [album sortedTracks];
    NSUInteger trackCount = tracks.count;
    for (NSUInteger x = 0; x < trackCount; x++) {
        nameRange = [self _searchAlbumTrack:tracks[x] forString:searchString];
        if (nameRange.location != NSNotFound)
            break;
    }
    return nameRange;
}

- (NSRange)_searchShowEpisode:(MLShowEpisode *)episode forString:(NSString *)searchString
{
    /* basic search first, then try more complex things */
    NSString *episodeName = [episode name];
    NSRange nameRange;

    if (episodeName) {
        nameRange = [episodeName rangeOfString:searchString options:NSCaseInsensitiveSearch];
        if (nameRange.location != NSNotFound)
            return nameRange;
    }

    /* split search string into substrings and try again */
    NSArray *substrings = [searchString componentsSeparatedByString:@" "];
    NSUInteger substringCount = substrings.count;
    if (substringCount > 1) {
        for (NSUInteger x = 0; x < substringCount; x++) {
            nameRange = [searchString rangeOfString:substrings[x] options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound)
                break;
        }
    }

    return nameRange;
}

- (NSRange)_searchShow:(MLShow *)mediaShow forString:(NSString *)searchString
{
    /* basic search first, then try more complex things */
    NSRange nameRange = [[mediaShow name] rangeOfString:searchString options:NSCaseInsensitiveSearch];

    if (nameRange.location != NSNotFound)
        return nameRange;

    /* split search string into substrings and try again */
    NSArray *substrings = [searchString componentsSeparatedByString:@" "];
    NSUInteger substringCount = substrings.count;
    if (substringCount > 1) {
        for (NSUInteger x = 0; x < substringCount; x++) {
            nameRange = [searchString rangeOfString:substrings[x] options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound)
                break;
        }
    }
    if (nameRange.location != NSNotFound)
        return nameRange;

    /* user didn't search for our show name, let's do a deeper search on the episodes */
    NSArray *episodes = [mediaShow sortedEpisodes];
    NSUInteger episodeCount = episodes.count;
    for (NSUInteger x = 0; x < episodeCount; x++)
        nameRange = [self _searchShowEpisode:episodes[x] forString:searchString];

    return nameRange;
}

- (NSRange)_searchLabel:(MLLabel *)mediaLabel forString:(NSString *)searchString
{
    /* basic search first, then try more complex things */
    NSRange nameRange = [[mediaLabel name] rangeOfString:searchString options:NSCaseInsensitiveSearch];

    if (nameRange.location != NSNotFound)
        return nameRange;

    /* user didn't search for our label name, let's do a deeper search */
    NSArray *files = [mediaLabel sortedFolderItems];
    NSUInteger fileCount = files.count;
    for (NSUInteger x = 0; x < fileCount; x++) {
        nameRange = [self _searchFile:files[x] forString:searchString];
        if (nameRange.location != NSNotFound)
            break;
    }
    return nameRange;
}

- (NSRange)_searchFile:(MLFile *)mediaFile forString:(NSString *)searchString
{
    /* basic search first, then try more complex things */
    NSRange nameRange = [[mediaFile title] rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (nameRange.location != NSNotFound)
        return nameRange;

    NSMutableArray *stringsToSearch = [[NSMutableArray alloc] initWithObjects:[mediaFile title], nil];
    if ([mediaFile artist])
        [stringsToSearch addObject:[mediaFile artist]];
    if ([mediaFile releaseYear])
        [stringsToSearch addObject:[mediaFile releaseYear]];

    NSArray *substrings = [searchString componentsSeparatedByString:@" "];
    NSUInteger substringCount = substrings.count;
    NSUInteger searchStringCount = stringsToSearch.count;

    for (NSUInteger x = 0; x < substringCount; x++) {
        for (NSUInteger y = 0; y < searchStringCount; y++) {
            nameRange = [stringsToSearch[y] rangeOfString:substrings[x] options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound)
                break;
        }
        if (nameRange.location != NSNotFound)
            break;
    }

    return nameRange;
}

@end
