//
//  VLCWatchMessage.h
//  VLC for iOS
//
//  Created by Tobias Conradi on 02.05.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const VLCWatchMessageNameGetNowPlayingInfo;
extern NSString *const VLCWatchMessageNamePlayPause;
extern NSString *const VLCWatchMessageNameSkipForward;
extern NSString *const VLCWatchMessageNameSkipBackward;
extern NSString *const VLCWatchMessageNamePlayFile;
extern NSString *const VLCWatchMessageNameSetVolume;
extern NSString *const VLCWatchMessageNameNotification;
extern NSString *const VLCWatchMessageNameRequestThumbnail;
extern NSString *const VLCWatchMessageNameRequestDB;

extern NSString *const VLCWatchMessageKeyURIRepresentation;

@interface VLCWatchMessage : NSObject
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly, nullable) id<NSObject,NSCoding> payload;

@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

- (instancetype)initWithName:(NSString *)name payload:(nullable id<NSObject,NSCoding>)payload;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

+ (NSDictionary *)messageDictionaryForName:(NSString *)name payload:(nullable id<NSObject,NSCoding>)payload;
+ (NSDictionary *)messageDictionaryForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
