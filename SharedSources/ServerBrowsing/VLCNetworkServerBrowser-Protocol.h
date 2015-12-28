/*****************************************************************************
 * VLCNetworkServerBrowser-Protocol.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VLCNetworkServerBrowserItem;
@protocol VLCNetworkServerBrowserDelegate;

@protocol VLCNetworkServerBrowser <NSObject>

@required
@property (nonatomic, weak) id <VLCNetworkServerBrowserDelegate> delegate;
@property (nonatomic, readonly, nullable) NSString *title;
@property (nonatomic, readonly, copy) VLCMediaList *mediaList;
@property (nonatomic, copy, readonly) NSArray<id<VLCNetworkServerBrowserItem>> *items;

- (void)update;

@end

@protocol VLCNetworkServerBrowserDelegate <NSObject>
- (void) networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser;
- (void) networkServerBrowser:(id<VLCNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error;
@end


@protocol VLCNetworkServerBrowserItem <NSObject>
@required
@property (nonatomic, readonly, getter=isContainer) BOOL container;
// if item is container browser is the browser for the container
@property (nonatomic, readonly, nullable) id<VLCNetworkServerBrowser> containerBrowser;

@property (nonatomic, readonly, nullable) VLCMedia *media;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly, nullable) NSURL *URL;
@property (nonatomic, readonly, nullable) NSNumber *fileSizeBytes;

@optional
@property (nonatomic, readonly, nullable) NSString *filename;
@property (nonatomic, readonly, nullable) NSString *duration;
@property (nonatomic, readonly, nullable) NSURL *subtitleURL;
@property (nonatomic, readonly, nullable) NSURL *thumbnailURL;
@property (nonatomic, getter=isDownloadable, readonly) BOOL downloadable;
@end


NS_ASSUME_NONNULL_END