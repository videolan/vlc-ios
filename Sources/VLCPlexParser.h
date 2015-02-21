/*****************************************************************************
 * VLCPlexParser.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
@interface VLCPlexParser : NSObject

- (NSMutableArray *)PlexMediaServerParser:(NSString *)adress port:(NSString *)port navigationPath:(NSString *)navPath;
- (NSInteger)MarkWatchedUnwatchedMedia:(NSString *)adress port:(NSString *)port videoRatingKey:(NSString *)ratingKey state:(NSString *)state;
- (NSString *)getFileSubtitleFromPlexServer:(NSMutableArray *)mutableMediaObject modeStream:(BOOL)modeStream;

@end