/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "VLCNetworkServerBrowser-Protocol.h"

#define DOWNLOAD_SUPPORTED TARGET_OS_IOS

@class MediaLibraryService;

NS_ASSUME_NONNULL_BEGIN
@protocol VLCRemoteBrowsingCell <NSObject>

@property (nonatomic, nullable) NSString *title;
@property (nonatomic, nullable) NSString *subtitle;
@property (nonatomic, nullable) UIImage *thumbnailImage;
@property (nonatomic, nullable) NSURL *thumbnailURL;
@property (nonatomic) BOOL isDirectory;
@property (nonatomic) BOOL couldBeAudioOnlyMedia;
@property (nonatomic) BOOL isFavorable;
#if DOWNLOAD_SUPPORTED
@property (nonatomic) BOOL isDownloadable;
#endif
@end


@interface VLCServerBrowsingController : NSObject
@property (nonatomic, nullable) NSByteCountFormatter *byteCountFormatter;
@property (nonatomic, nullable) UIImage *folderImage;
@property (nonatomic, nullable) UIImage *genericFileImage;

@property (nonatomic, readonly) id<VLCNetworkServerBrowser> serverBrowser;
@property (nonatomic, weak, nullable, readonly) UIViewController *viewController;

- (instancetype)init NS_UNAVAILABLE;

#if TARGET_OS_IOS
- (instancetype)initWithViewController:(UIViewController *)viewController
                         serverBrowser:(id<VLCNetworkServerBrowser>)browser
                   medialibraryService:(MediaLibraryService *)medialibraryService;
# elif TARGET_OS_TV
- (instancetype)initWithViewController:(UIViewController *)viewController
                         serverBrowser:(id<VLCNetworkServerBrowser>)browser;
#endif

- (void)configureCell:(id<VLCRemoteBrowsingCell>)cell withItem:(id<VLCNetworkServerBrowserItem>)item;

#pragma mark - Subtitles
- (void)configureSubtitlesInMediaList:(VLCMediaList *)mediaList;
#pragma mark - Streaming
- (void)streamFileForItem:(id<VLCNetworkServerBrowserItem>)item;
- (void)streamMediaList:(VLCMediaList *)mediaList startingAtIndex:(NSInteger)startIndex;


#if DOWNLOAD_SUPPORTED
- (BOOL)triggerDownloadForItem:(id<VLCNetworkServerBrowserItem>)item;

#endif
@end
NS_ASSUME_NONNULL_END

