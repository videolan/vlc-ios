/*****************************************************************************
 * MLShowEpisode.m
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

#import "MLMediaLibrary.h"
#import "MLShowEpisode.h"
#import "MLShow.h"
#import "MLFile.h"

@interface MLShowEpisode ()
@property (nonatomic, strong) NSNumber *primitiveUnread;
@property (nonatomic, strong) NSString *primitiveArtworkURL;
@end

@implementation MLShowEpisode

+ (NSArray *)allEpisodes
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    if (!moc || moc.persistentStoreCoordinator == nil)
        return [NSArray array];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShowEpisode" inManagedObjectContext:moc];
    [request setEntity:entity];

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    [request setSortDescriptors:@[descriptor]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"files.@count > 0"]];

    NSArray *episodes = [moc executeFetchRequest:request error:nil];

    return episodes;
}

+ (MLShowEpisode *)episodeWithShow:(MLShow *)show episodeNumber:(NSNumber *)episodeNumber seasonNumber:(NSNumber *)seasonNumber createIfNeeded:(BOOL)createIfNeeded
{
    if (!show)
        return NULL;

    NSSet *episodes = [show valueForKey:@"episodes"];

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

    if (!episode && createIfNeeded) {
        episode = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"ShowEpisode"];
        episode.episodeNumber = episodeNumber;
        episode.seasonNumber = seasonNumber;
        episode.show = show;
    }
    return episode;
}

+ (MLShowEpisode *)episodeWithShowName:(NSString *)showName
                         episodeNumber:(NSNumber *)episodeNumber
                          seasonNumber:(NSNumber *)seasonNumber
                        createIfNeeded:(BOOL)createIfNeeded
                            wasCreated:(BOOL *)wasCreated
{
    MLShow *show = [MLShow showWithName:showName];
    *wasCreated = NO;
    if (!show && createIfNeeded) {
        *wasCreated = YES;
        show = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"Show"];
        show.name = showName;
    } else if (!show && !createIfNeeded)
        return nil;

    return [MLShowEpisode episodeWithShow:show episodeNumber:episodeNumber seasonNumber:seasonNumber createIfNeeded:createIfNeeded];
}

@dynamic primitiveUnread;

@dynamic unread;


- (void)setUnread:(NSNumber *)unread
{
    [self willChangeValueForKey:@"unread"];
    [self setPrimitiveUnread:unread];
    [self didChangeValueForKey:@"unread"];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    if (!moc)
        return;
    [moc refreshObject:[self show] mergeChanges:YES];
    [moc refreshObject:self mergeChanges:YES];
}

@dynamic theTVDBID;
@dynamic shortSummary;
@dynamic shouldBeDisplayed;
@dynamic episodeNumber;
@dynamic seasonNumber;
@dynamic lastSyncDate;
@dynamic artworkURL;

@dynamic primitiveArtworkURL;

- (void)setArtworkURL:(NSString *)artworkURL
{
    [self willChangeValueForKey:@"artworkURL"];
    NSSet *files = self.files;
    for (id file in files)
        [file willChangeValueForKey:@"artworkURL"];
    [self setPrimitiveArtworkURL:artworkURL];
    for (id file in files)
        [file didChangeValueForKey:@"artworkURL"];
    [self didChangeValueForKey:@"artworkURL"];
}
@dynamic name;
@dynamic show;
@dynamic files;

- (MLFile *)anyFileFromEpisode
{
    return (MLFile *)self.files.anyObject;
}

@end
