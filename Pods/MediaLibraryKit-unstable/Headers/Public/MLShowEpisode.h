/*****************************************************************************
 * MLShowEpisode.h
 * Lunettes
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2013 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
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

#import <CoreData/CoreData.h>

@class MLShow;
@class MLFile;

@interface MLShowEpisode :  NSManagedObject

+ (NSArray *)allEpisodes;

// This will eventually create the show
+ (MLShowEpisode *)episodeWithShow:(MLShow *)show episodeNumber:(NSNumber *)episodeNumber seasonNumber:(NSNumber *)seasonNumber createIfNeeded:(BOOL)createIfNeeded;
+ (MLShowEpisode *)episodeWithShowName:(NSString *)showName episodeNumber:(NSNumber *)episodeNumber seasonNumber:(NSNumber *)seasonNumber
                        createIfNeeded:(BOOL)createIfNeeded wasCreated:(BOOL *)wasCreated;

@property (nonatomic, strong) NSNumber *unread;
@property (nonatomic, strong) NSString *theTVDBID;
@property (nonatomic, strong) NSString *shortSummary;
@property (nonatomic, strong) NSNumber *shouldBeDisplayed;
@property (nonatomic, strong) NSNumber *episodeNumber;
@property (nonatomic, strong) NSNumber *seasonNumber;
@property (nonatomic, strong) NSNumber *lastSyncDate;
@property (nonatomic, strong) NSString *artworkURL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) MLShow *show;
@property (nonatomic, strong) NSSet *files;

@end


@interface MLShowEpisode (CoreDataGeneratedAccessors)
- (void)addFilesObject:(NSManagedObject *)value;
- (void)removeFilesObject:(NSManagedObject *)value;
- (void)addFiles:(NSSet *)value;
- (void)removeFiles:(NSSet *)value;
- (MLFile *)anyFileFromEpisode;
@end

