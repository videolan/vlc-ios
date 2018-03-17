/*****************************************************************************
 * VLCNetworkServerBrowserPlex.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowser-Protocol.h"
#import "VLCNetworkServerLoginInformation.h"

NS_ASSUME_NONNULL_BEGIN
@interface VLCNetworkServerBrowserPlex : NSObject <VLCNetworkServerBrowser>
- (instancetype)initWithName:(NSString *)name host:(NSString *)addressOrName portNumber:(NSNumber *)portNumber path:(NSString *)path authentificication:(NSString *)auth NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithName:(NSString *)name url:(NSURL *)url auth:(NSString *)auth;
- (instancetype)initWithLogin:(VLCNetworkServerLoginInformation *)login;

- (instancetype)init NS_UNAVAILABLE;
@end


@interface VLCNetworkServerBrowserItemPlex : NSObject <VLCNetworkServerBrowserItem>
- (instancetype)initWithDictionary:(NSDictionary *)dictionary currentURL:(NSURL *)currentURL authentificication:(NSString *)auth;

@property (nonatomic, readonly, nullable) NSString *filename;
@property (nonatomic, readonly, nullable) NSString *duration;
@property (nonatomic, readonly, nullable) NSString *subtitleType;
@property (nonatomic, readonly, nullable) NSURL *subtitleURL;
@property (nonatomic, readonly, nullable) NSURL *thumbnailURL;
@property (nonatomic, readonly, nullable) NSURL *URLcontainer;
@property (nonatomic, getter=isDownloadable, readonly) BOOL downloadable;

@end


NS_ASSUME_NONNULL_END
