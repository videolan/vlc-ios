/*****************************************************************************
 * MLAlbumTrack.m
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2013-2015 Felix Paul Kühne
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
#import "MLAlbumTrack.h"
#import "MLAlbum.h"
#import "MLFile.h"

NSString *const MLAlbumTrackAlbum       = @"MLAlbumTrackAlbum";
NSString *const MLAlbumTrackAlbumName   = @"MLAlbumTrackAlbumName";
NSString *const MLAlbumTrackNumber      = @"MLAlbumTrackNumber";
NSString *const MLAlbumTrackTrackName   = @"MLAlbumTrackTrackName";
NSString *const MLAlbumTrackDiscNumber  = @"MLAlbumTrackDiscNumber";

@interface MLAlbumTrack ()
@property (nonatomic, strong) NSNumber *primitiveUnread;
@end

@implementation MLAlbumTrack

+ (NSArray *)allTracks
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    if (!moc || moc.persistentStoreCoordinator == nil)
        return [NSArray array];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AlbumTrack" inManagedObjectContext:moc];
    [request setEntity:entity];

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];
    [request setSortDescriptors:@[descriptor]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"files.@count > 0"]];

    NSArray *tracks = [moc executeFetchRequest:request error:nil];

    return tracks;
}

+ (MLAlbumTrack *)trackWithAlbum:(MLAlbum *)album trackNumber:(NSNumber *)trackNumber createIfNeeded:(BOOL)createIfNeeded
{
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];

    if (trackNumber)
        [mutDict setObject:trackNumber forKey:MLAlbumTrackNumber];
    BOOL wasCreated = NO;

    return [MLAlbumTrack trackWithAlbum:album metadata:[NSDictionary dictionaryWithDictionary:mutDict] createIfNeeded:createIfNeeded wasCreated:&wasCreated];
}

+ (MLAlbumTrack *)trackWithAlbum:(MLAlbum *)album trackNumber:(NSNumber *)trackNumber trackName:(NSString *)trackName createIfNeeded:(BOOL)createIfNeeded
{
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];

    if (trackName)
        [mutDict setObject:trackName forKey:MLAlbumTrackTrackName];
    if (trackNumber)
        [mutDict setObject:trackNumber forKey:MLAlbumTrackNumber];
    BOOL wasCreated = NO;

    return [MLAlbumTrack trackWithAlbum:album metadata:[NSDictionary dictionaryWithDictionary:mutDict] createIfNeeded:createIfNeeded wasCreated:&wasCreated];
}

+ (MLAlbumTrack *)trackWithAlbum:(MLAlbum *)album metadata:(NSDictionary *)metadata createIfNeeded:(BOOL)createIfNeeded wasCreated:(BOOL *)wasCreated
{
    if (!album)
        return nil;

    NSNumber *trackNumber = metadata[MLAlbumTrackNumber];
    NSString *trackName = metadata[MLAlbumTrackTrackName];
    NSNumber *discNumber = metadata[MLAlbumTrackDiscNumber];

    NSSet *tracks = [album tracks];
    MLAlbumTrack *track = nil;
    for (MLAlbumTrack *trackIter in tracks) {
        if ([trackIter.trackNumber intValue] == [trackNumber intValue]) {
            if (trackIter.discNumber.intValue == discNumber.intValue) {
                track = trackIter;
                break;
            }
        } else if ([trackIter.title isEqualToString:trackName]) {
            if (trackIter.discNumber.intValue == discNumber.intValue) {
                track = trackIter;
                break;
            }
        }
    }

    if (!track && createIfNeeded) {
        track = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"AlbumTrack"];
        if (trackNumber.integerValue == 0)
            trackNumber = @(tracks.count + 1);
        track.trackNumber = trackNumber;
        track.title = trackName;
        if (discNumber)
            track.discNumber = discNumber;
        [album addTrack:track];
    }
    return track;
}

+ (MLAlbumTrack *)trackWithAlbumName:(NSString *)albumName trackNumber:(NSNumber *)trackNumber createIfNeeded:(BOOL)createIfNeeded wasCreated:(BOOL *)wasCreated
{
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];

    if (albumName)
        [mutDict setObject:albumName forKey:MLAlbumTrackAlbumName];
    if (trackNumber)
        [mutDict setObject:trackNumber forKey:MLAlbumTrackNumber];

    return [MLAlbumTrack trackWithMetadata:[NSDictionary dictionaryWithDictionary:mutDict] createIfNeeded:createIfNeeded wasCreated:wasCreated];
}

+ (MLAlbumTrack *)trackWithAlbumName:(NSString *)albumName trackNumber:(NSNumber *)trackNumber trackName:(NSString *)trackName createIfNeeded:(BOOL)createIfNeeded wasCreated:(BOOL *)wasCreated
{
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];

    if (albumName)
        [mutDict setObject:albumName forKey:MLAlbumTrackAlbumName];
    if (trackNumber)
        [mutDict setObject:trackNumber forKey:MLAlbumTrackNumber];
    if (trackName)
        [mutDict setObject:trackName forKey:MLAlbumTrackTrackName];

    return [MLAlbumTrack trackWithMetadata:[NSDictionary dictionaryWithDictionary:mutDict] createIfNeeded:createIfNeeded wasCreated:wasCreated];
}

+ (MLAlbumTrack *)trackWithMetadata:(NSDictionary *)metadata createIfNeeded:(BOOL)createIfNeeded wasCreated:(BOOL *)wasCreated
{
    NSString *albumName = metadata[MLAlbumTrackAlbumName];
    MLAlbum *album = [MLAlbum albumWithName:albumName];
    *wasCreated = NO;

    if (!album && createIfNeeded) {
        *wasCreated = YES;
        album = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"Album"];
        album.name = albumName ? albumName : @"";
    }
    if (!album && !createIfNeeded)
        return nil;

    return [MLAlbumTrack trackWithAlbum:album metadata:metadata createIfNeeded:createIfNeeded wasCreated:wasCreated];
}

@dynamic primitiveUnread;
@dynamic unread;
- (void)setUnread:(NSNumber *)unread
{
    [self willChangeValueForKey:@"unread"];
    [self setPrimitiveUnread:unread];
    [self didChangeValueForKey:@"unread"];
    NSManagedObjectContext *moc = [[MLMediaLibrary sharedMediaLibrary] managedObjectContext];
    if (moc) {
        [moc refreshObject:[self album] mergeChanges:YES];
        [moc refreshObject:self mergeChanges:YES];
    }
}

@dynamic artist;
@dynamic genre;
@dynamic title;
@dynamic trackNumber;
@dynamic discNumber;
@dynamic album;
@dynamic files;
@dynamic containsArtwork;

- (MLFile *)anyFileFromTrack
{
    return (MLFile *)self.files.anyObject;
}

@end
