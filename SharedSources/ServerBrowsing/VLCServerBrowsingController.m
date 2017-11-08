/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServerBrowsingController.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+VLC.h"

#import "VLCPlaybackController.h"

#if TARGET_OS_TV
#import "VLCFullscreenMovieTVViewController.h"
#import "MetaDataFetcherKit.h"
#endif

#if DOWNLOAD_SUPPORTED
#import "VLCDownloadViewController.h"
#endif

@implementation VLCServerBrowsingController

- (instancetype)initWithViewController:(UIViewController *)viewController serverBrowser:(id<VLCNetworkServerBrowser>)browser
{
    self = [super init];
    if (self) {
        _viewController = viewController;
        _serverBrowser = browser;
#if TARGET_OS_TV
        MDFMovieDBSessionManager *movieDBSessionManager = [MDFMovieDBSessionManager sharedInstance];
        movieDBSessionManager.apiKey = kVLCfortvOSMovieDBKey;
        [movieDBSessionManager fetchProperties];
#endif
    }
    return self;
}

#pragma mark -

- (NSByteCountFormatter *)byteCounterFormatter
{
    if (!_byteCountFormatter)
        _byteCountFormatter = [[NSByteCountFormatter alloc] init];

    return _byteCountFormatter;
}

- (UIImage *)genericFileImage
{
    if (!_genericFileImage)
        _genericFileImage = [UIImage imageNamed:@"blank"];

    return _genericFileImage;
}

- (UIImage *)folderImage
{
    if (!_folderImage)
        _folderImage = [UIImage imageNamed:@"folder"];

    return _folderImage;
}

#pragma mark - cell configuration

- (void)configureCell:(id<VLCRemoteBrowsingCell>)cell withItem:(id<VLCNetworkServerBrowserItem>)item
{
    if (item.isContainer) {
        cell.isDirectory = YES;
        cell.thumbnailImage = self.folderImage;
    } else {
        cell.isDirectory = NO;
        cell.thumbnailImage = self.genericFileImage;

        NSString *sizeString = item.fileSizeBytes ? [self.byteCounterFormatter stringFromByteCount:item.fileSizeBytes.longLongValue] : nil;

        NSString *duration = nil;
        if ([item respondsToSelector:@selector(duration)])
            duration = item.duration;

        NSString *subtitle = nil;
        if (sizeString && duration) {
            subtitle = [NSString stringWithFormat:@"%@ (%@)",duration, sizeString];
        } else if (sizeString) {
            subtitle = sizeString;
        } else if (duration) {
            subtitle = duration;
        }
        cell.subtitle = subtitle;
#if DOWNLOAD_SUPPORTED
        if ([item respondsToSelector:@selector(isDownloadable)])
            cell.isDownloadable = item.isDownloadable;
        else
            cell.isDownloadable = NO;
#endif
    }
    cell.title = item.name;

    NSURL *thumbnailURL = nil;
    if ([item respondsToSelector:@selector(thumbnailURL)])
        thumbnailURL = item.thumbnailURL;

    [cell setThumbnailURL:thumbnailURL];
}

#pragma mark - subtitles

- (NSArray<NSURL*> *)_searchSubtitle:(NSString *)url
{
    NSString *urlTemp = [[url lastPathComponent] stringByDeletingPathExtension];

    NSMutableArray<NSURL*> *urls = [NSMutableArray arrayWithArray:[self.serverBrowser.items valueForKey:@"URL"]];

    NSPredicate *namePredicate = [NSPredicate predicateWithFormat:@"SELF.path contains[c] %@", urlTemp];
    [urls filterUsingPredicate:namePredicate];

    NSPredicate *formatPrediate = [NSPredicate predicateWithBlock:^BOOL(NSURL *_Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject.path isSupportedSubtitleFormat];
    }];
    [urls filterUsingPredicate:formatPrediate];

    return [NSArray arrayWithArray:urls];
}

- (NSString *)_getFileSubtitleFromServer:(NSURL *)subtitleURL
{
    NSString *FileSubtitlePath = nil;
    NSData *receivedSub = [NSData dataWithContentsOfURL:subtitleURL]; // TODO: fix synchronous load

    if (receivedSub.length < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *directoryPath = searchPaths[0];
        FileSubtitlePath = [directoryPath stringByAppendingPathComponent:[subtitleURL lastPathComponent]];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
            //create local subtitle file
            [fileManager createFileAtPath:FileSubtitlePath contents:nil attributes:nil];
            if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
                APLog(@"file creation failed, no data was saved");
                return nil;
            }
        }
        [receivedSub writeToFile:FileSubtitlePath atomically:YES];
    } else {

        [self.viewController vlc_showAlertWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                            message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), [subtitleURL lastPathComponent], [[UIDevice currentDevice] model]]
                                        buttonTitle:NSLocalizedString(@"BUTTON_OK", nil)];
    }

    return FileSubtitlePath;
}

- (void)configureSubtitlesInMediaList:(VLCMediaList *)mediaList
{
    NSArray *items = self.serverBrowser.items;
    id<VLCNetworkServerBrowserItem> loopItem;
    [mediaList lock];
    NSUInteger count = mediaList.count;
    for (NSUInteger i = 0; i < count; i++) {
        loopItem = items[i];
        NSString *URLofSubtitle = nil;
        NSURL *remoteSubtitleURL = nil;
        if ([loopItem respondsToSelector:@selector(subtitleURL)]) {
            remoteSubtitleURL = [loopItem subtitleURL];
        }
        if (remoteSubtitleURL == nil) {
            NSArray *subtitlesList = [self _searchSubtitle:loopItem.URL.lastPathComponent];
            remoteSubtitleURL = subtitlesList.firstObject;
        }

        if(remoteSubtitleURL != nil) {
            URLofSubtitle = [self _getFileSubtitleFromServer:remoteSubtitleURL];
            if (URLofSubtitle != nil)
                [[mediaList mediaAtIndex:i] addOptions:@{ kVLCSettingSubtitlesFilePath : URLofSubtitle }];
        }
    }
    [mediaList unlock];
}

#pragma mark - File Streaming

- (void)showMovieViewController
{
#if TARGET_OS_TV
    VLCFullscreenMovieTVViewController *moviewVC = [VLCFullscreenMovieTVViewController fullscreenMovieTVViewController];
    [self.viewController presentViewController:moviewVC
                                      animated:YES
                                    completion:nil];
#endif
}

- (void)streamMediaList:(VLCMediaList *)mediaList startingAtIndex:(NSInteger)startIndex
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    vpc.fullscreenSessionRequested = YES;
    [vpc playMediaList:mediaList firstIndex:startIndex subtitlesFilePath:nil];
    [self showMovieViewController];
}

- (void)streamFileForItem:(id<VLCNetworkServerBrowserItem>)item
{
    NSString *URLofSubtitle = nil;
    NSURL *remoteSubtitleURL = nil;
    if ([item respondsToSelector:@selector(subtitleURL)])
        remoteSubtitleURL = [item subtitleURL];

    if (!remoteSubtitleURL) {
        NSArray *SubtitlesList = [self _searchSubtitle:item.URL.lastPathComponent];
        remoteSubtitleURL = SubtitlesList.firstObject;
    }

    if(remoteSubtitleURL)
        URLofSubtitle = [self _getFileSubtitleFromServer:remoteSubtitleURL];

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    vpc.fullscreenSessionRequested = YES;
    VLCMediaList *medialist = [[VLCMediaList alloc] init];
    [medialist addMedia:[VLCMedia mediaWithURL:item.URL]];
    [vpc playMediaList:medialist firstIndex:0 subtitlesFilePath:URLofSubtitle];
    [self showMovieViewController];
}

#pragma mark - Downloads

#if DOWNLOAD_SUPPORTED
- (BOOL)triggerDownloadForItem:(id<VLCNetworkServerBrowserItem>)item
{
    // is item supposed to be not downloadable?
    if ([item respondsToSelector:@selector(isDownloadable)] && ![item isDownloadable]) {
        return NO;
    }
    // if the item has no URL we can't download it
    if (!item.URL) {
        return NO;
    }

    if (item.fileSizeBytes.longLongValue  < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
        [self _downloadItem:item];
        return YES;
    } else {
        NSString *title = NSLocalizedString(@"DISK_FULL", nil);
        NSString *messsage = [NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), item.name, [[UIDevice currentDevice] model]];
        NSString *button = NSLocalizedString(@"BUTTON_OK", nil);
        [self.viewController vlc_showAlertWithTitle:title message:messsage buttonTitle:button];
        return NO;
    }
}

- (void)_downloadItem:(id<VLCNetworkServerBrowserItem>)item
{
    NSString *filename;
    if ([item respondsToSelector:@selector(filename)])
        filename = item.filename;
    else
        filename = item.name;

    if (filename.pathExtension.length == 0) {
        /* there are few crappy UPnP servers who don't reveal the correct file extension, so we use a generic fake (#11123) */
        NSString *urlExtension = item.URL.pathExtension;
        NSString *extension = urlExtension.length != 0 ? urlExtension : @"vlc";
        filename = [filename stringByAppendingPathExtension:extension];
    }
    [[VLCDownloadViewController sharedInstance] addURLToDownloadList:item.URL
                                                     fileNameOfMedia:filename];
}

#endif

@end
