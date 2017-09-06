/*****************************************************************************
 * VLCPlexWebAPI.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2017 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
@interface VLCPlexWebAPI : NSObject

- (BOOL)PlexCreateIdentification:(NSString *)username password:(NSString *)password;
- (NSArray *)PlexBasicAuthentification:(NSString *)username password:(NSString *)password;
- (NSString *)PlexAuthentification:(NSString *)username password:(NSString *)password;
- (NSString *)urlAuth:(NSString *)url authentification:(NSString *)auth;
- (NSData *)HttpRequestWithCookie:(NSURL *)url cookies:(NSArray *)authToken HTTPMethod:(NSString *)method;
- (NSURL *)CreatePlexStreamingURL:(NSString *)address port:(NSString *)port videoKey:(NSString *)key username:(NSString *)username deviceInfo:(NSDictionary *)deviceInfo session:(NSString *)session;
- (void)stopSession:(NSString *)adress port:(NSString *)port session:(NSString *)session;
- (NSInteger)MarkWatchedUnwatchedMedia:(NSString *)address port:(NSString *)port videoRatingKey:(NSString *)ratingKey state:(NSString *)state authentification:(NSString *)auth;
- (NSString *)getFileSubtitleFromPlexServer:(NSDictionary *)mediaObject modeStream:(BOOL)modeStream error:(NSError *__autoreleasing*)error;
- (NSString *)getSession;
- (NSData *)PlexDeviceInfo:(NSArray *)cookies;

+ (NSString *)urlAuth:(NSString *)url authentification:(NSString *)auth;

@end
