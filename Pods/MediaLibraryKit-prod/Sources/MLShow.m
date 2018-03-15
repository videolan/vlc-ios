/*****************************************************************************
 * MLShow.m
 * Lunettes
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2015 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "MLShow.h"
#import "MLShowEpisode.h"
#import "MLMediaLibrary.h"

@implementation MLShow

+ (NSArray *)allShows
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    if (!moc || moc.persistentStoreCoordinator == nil)
        return [NSArray array];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Show" inManagedObjectContext:moc];
    [request setEntity:entity];

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    [request setSortDescriptors:@[descriptor]];

    NSArray *shows = [moc executeFetchRequest:request error:nil];

    return shows;
}

+ (MLShow *)showWithName:(NSString *)name
{
    NSFetchRequest *request = [[MLMediaLibrary sharedMediaLibrary] fetchRequestForEntity:@"Show"];
    if (!request)
        return nil;
    [request setPredicate:[NSPredicate predicateWithFormat:@"name == %@", name]];

    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    if (!moc)
        return nil;

    NSArray *dbResults = [moc executeFetchRequest:request error:nil];
    NSAssert(dbResults, @"Can't execute fetch request");

    if ([dbResults count] <= 0)
        return nil;

    return dbResults[0];
}


@dynamic theTVDBID;
@dynamic shortSummary;
@dynamic artworkURL;
@dynamic name;
@dynamic lastSyncDate;
@dynamic releaseYear;
@dynamic episodes;

- (NSSet *)unreadEpisodes
{
    NSArray *episodes = [[self valueForKey:@"episodes"] allObjects];
    NSMutableSet *set = [NSMutableSet set];
    NSUInteger count = episodes.count;
    for (NSUInteger x = 0; x < count; x++) {
        NSSet *files = [episodes[x] valueForKey:@"files"];
        for (id file in files) {
            if ([[file valueForKey:@"unread"] boolValue]) {
                [set addObject:episodes[x]];
                break;
            }
        }
    }
    return set;
}

- (NSArray *)sortedEpisodes
{
    NSArray *episodes = [[self valueForKey:@"episodes"] allObjects];

    NSSortDescriptor *seasonDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"seasonNumber"
                                ascending:YES
                                 selector:@selector(compare:)];
    NSSortDescriptor *episodesDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"episodeNumber"
                                ascending:YES
                                 selector:@selector(compare:)];
    NSArray *descriptors = @[seasonDescriptor, episodesDescriptor];
    return [episodes sortedArrayUsingDescriptors:descriptors];
}

- (void)addEpisode:(MLShowEpisode*)episode
{
    if (!episode)
        return;

    NSMutableSet *episodes = [self mutableSetValueForKey:@"episodes"];
    [episodes addObject:episode];

    [self willChangeValueForKey:@"episodes"];
    [self setValue:episodes forKey:@"episodes"];
    [self didChangeValueForKey:@"episodes"];
}

- (void)removeEpisode:(MLShowEpisode*)episode
{
    if (!episode)
        return;

    NSMutableSet *episodes = [self mutableSetValueForKey:@"episodes"];

    [episodes removeObject:episode];

    [self willChangeValueForKey:@"episodes"];
    [self setValue:episodes forKey:@"episodes"];
    [self didChangeValueForKey:@"episodes"];
}

- (void)removeEpisodeWithSeasonNumber:(NSNumber *)seasonNumber andEpisodeNumber:(NSNumber *)episodeNumber
{
    NSMutableSet *episodes = [self mutableSetValueForKey:@"episodes"];
    MLShowEpisode *episode = nil;
    if (seasonNumber && episodeNumber) {
        for (MLShowEpisode *episodeIter in episodes) {
            if ([episodeIter.seasonNumber intValue] == [seasonNumber intValue] &&
                [episodeIter.episodeNumber intValue] == [episodeNumber intValue]) {
                episode = episodeIter;
                break;
            }
        }
    }
    if (!episode)
        return;

    [episodes removeObject:episode];

    [self willChangeValueForKey:@"episodes"];
    [self setValue:episodes forKey:@"episodes"];
    [self didChangeValueForKey:@"episodes"];
}

@end
