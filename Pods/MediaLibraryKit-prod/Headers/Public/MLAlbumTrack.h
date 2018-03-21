/*****************************************************************************
 * MLAlbumTrack.h
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2013 Felix Paul Kühne
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

#import "MLAlbum.h"

extern NSString *const MLAlbumTrackAlbumName;
extern NSString *const MLAlbumTrackNumber;
extern NSString *const MLAlbumTrackTrackName;
extern NSString *const MLAlbumTrackDiscNumber;

@class MLFile;

@interface MLAlbumTrack : NSManagedObject

+ (NSArray *)allTracks;

+ (MLAlbumTrack *)trackWithAlbum:(MLAlbum *)album
                     trackNumber:(NSNumber *)trackNumber
                  createIfNeeded:(BOOL)createIfNeeded __attribute__((deprecated));
+ (MLAlbumTrack *)trackWithAlbum:(MLAlbum *)album
                     trackNumber:(NSNumber *)trackNumber
                       trackName:(NSString *)trackName
                  createIfNeeded:(BOOL)createIfNeeded __attribute__((deprecated));

+ (MLAlbumTrack *)trackWithAlbumName:(NSString *)albumName
                         trackNumber:(NSNumber *)trackNumber
                      createIfNeeded:(BOOL)createIfNeeded
                          wasCreated:(BOOL *)wasCreated __attribute__((deprecated));
+ (MLAlbumTrack *)trackWithAlbumName:(NSString *)albumName
                         trackNumber:(NSNumber *)trackNumber
                           trackName:(NSString *)trackName
                      createIfNeeded:(BOOL)createIfNeeded
                          wasCreated:(BOOL *)wasCreated __attribute__((deprecated));

/* for available keys, see above */
+ (MLAlbumTrack *)trackWithAlbum:(MLAlbum *)album
                        metadata:(NSDictionary *)metadata
                  createIfNeeded:(BOOL)createIfNeeded
                      wasCreated:(BOOL *)wasCreated;
+ (MLAlbumTrack *)trackWithMetadata:(NSDictionary *)metadata
                     createIfNeeded:(BOOL)createIfNeeded
                         wasCreated:(BOOL *)wasCreated;

@property (nonatomic, strong) NSNumber *unread;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *genre;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *trackNumber;
@property (nonatomic, strong) NSNumber *discNumber;

@property (nonatomic, strong) MLAlbum *album;
@property (nonatomic, strong) NSSet *files;
@property (nonatomic) BOOL containsArtwork;

@end

@interface MLAlbumTrack (CoreDataGeneratedAccessors)
- (void)addFilesObject:(NSManagedObject *)value;
- (void)removeFilesObject:(NSManagedObject *)value;
- (void)addFiles:(NSSet *)value;
- (void)removeFiles:(NSSet *)value;
- (MLFile *)anyFileFromTrack;
@end
