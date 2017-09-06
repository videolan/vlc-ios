/*****************************************************************************
 * VLCNetworkServerBrowserSharedLibrary.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowser-Protocol.h"

NS_ASSUME_NONNULL_BEGIN
@interface VLCNetworkServerBrowserSharedLibrary : NSObject <VLCNetworkServerBrowser>
- (instancetype)initWithName:(NSString *)name host:(NSString *)addressOrName portNumber:(NSUInteger)portNumber NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end


@interface VLCNetworkServerBrowserItemSharedLibrary : NSObject <VLCNetworkServerBrowserItem>
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, readonly, nullable) NSURL *subtitleURL;
@property (nonatomic, readonly, nullable) NSString *duration;
@property (nonatomic, readonly, nullable) NSURL *thumbnailURL;
@property (nonatomic, getter=isDownloadable, readonly) BOOL downloadable;

@end

NS_ASSUME_NONNULL_END
