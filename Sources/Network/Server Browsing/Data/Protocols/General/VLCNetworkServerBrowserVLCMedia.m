/*****************************************************************************
 * VLCNetworkServerBrowserVLCMedia.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowserVLCMedia.h"
#import "NSString+SupportedMedia.h"
#import "VLC-Swift.h"

@interface VLCNetworkServerBrowserVLCMedia () <VLCMediaListDelegate, VLCMediaDelegate>
{
    VLCDialogProvider *_dialogProvider;
    VLCCustomDialogRendererHandler *_customDialogHandler;
}

@property (nonatomic) VLCMedia *rootMedia;
@property (nonatomic) VLCMediaList *mediaList;
@property (nonatomic) VLCMediaList *mediaListUnfiltered;
@property (nonatomic) NSMutableArray<id<VLCNetworkServerBrowserItem>> *mutableItems;
@property (nonatomic, readonly) NSDictionary *mediaOptions;

@end
@implementation VLCNetworkServerBrowserVLCMedia
@synthesize delegate = _delegate;

- (instancetype)initWithMedia:(VLCMedia *)media options:(nonnull NSDictionary *)mediaOptions
{
    self = [super init];
    if (self) {
        _mutableItems = [[NSMutableArray alloc] init];
        _mediaList = [[VLCMediaList alloc] init];
        _rootMedia = media;
        _rootMedia.delegate = self;
        // Set timeout to 0 in order to avoid getting interrupted in dialogs for timeout reasons
        [_rootMedia parseWithOptions:VLCMediaParseNetwork|VLCMediaDoInteract timeout:0];
        _mediaListUnfiltered = [_rootMedia subitems];
        _mediaListUnfiltered.delegate = self;
        NSMutableDictionary *mediaOptionsNoFilter = [mediaOptions mutableCopy];
        [mediaOptionsNoFilter setObject:@" " forKey:@":ignore-filetypes"];
        _mediaOptions = [mediaOptionsNoFilter copy];
        [self _addMediaListRootItemsToList];

        _dialogProvider = [[VLCDialogProvider alloc] initWithLibrary:[VLCLibrary sharedLibrary] customUI:YES];
        _customDialogHandler = [[VLCCustomDialogRendererHandler alloc]
                                initWithDialogProvider:_dialogProvider];

        __weak typeof(self) weakSelf = self;
        _customDialogHandler.completionHandler = ^(VLCCustomDialogRendererHandlerCompletionType status)
        {
            [weakSelf customDialogCompletionHandlerWithStatus:status];
        };
        _dialogProvider.customRenderer = _customDialogHandler;
    }
    return self;
}

- (void)dealloc
{
    [_rootMedia parseStop];
}

- (void)customDialogCompletionHandlerWithStatus:(VLCCustomDialogRendererHandlerCompletionType)status
{
    if (status == VLCCustomDialogRendererHandlerCompletionTypeStop) {
        [_rootMedia parseStop];
    }
}

- (void)_addMediaListRootItemsToList
{
    VLCMediaList *rootItems = _rootMedia.subitems;
    [rootItems lock];
    NSUInteger count = rootItems.count;
    for (NSUInteger i = 0; i < count; i++) {
        VLCMedia *media = [rootItems mediaAtIndex:i];
        NSInteger mediaIndex = self.mutableItems.count;
        [self.mediaList insertMedia:media atIndex:mediaIndex];
        [self.mutableItems insertObject:[[VLCNetworkServerBrowserItemVLCMedia alloc] initWithMedia:media options:self.mediaOptions] atIndex:mediaIndex];
    }
    [rootItems unlock];
}

- (void)update {
    int ret = [self.rootMedia parseWithOptions:VLCMediaParseNetwork];
    if (ret == -1) {
        [self.delegate networkServerBrowserDidUpdate:self];
    }
}

- (NSString *)title {
    return self.rootMedia.metaData.title;
}

- (NSArray<id<VLCNetworkServerBrowserItem>> *)items {
    return self.mutableItems.copy;
}

#pragma mark - media list delegate

- (void)mediaList:(VLCMediaList *)aMediaList mediaAdded:(VLCMedia *)media atIndex:(NSUInteger)index
{
    [media addOptions:self.mediaOptions];
    NSInteger mediaIndex = self.mutableItems.count;
    [self.mediaList insertMedia:media atIndex:mediaIndex];
    [self.mutableItems insertObject:[[VLCNetworkServerBrowserItemVLCMedia alloc] initWithMedia:media options:self.mediaOptions] atIndex:mediaIndex];

    [self.delegate networkServerBrowserDidUpdate:self];
}

- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSUInteger)index
{
    VLCMedia *media = [self.mediaListUnfiltered mediaAtIndex:index];
    NSInteger mediaIndex = [self.mediaList indexOfMedia:media];
    [self.mediaList removeMediaAtIndex:mediaIndex];
    [self.mutableItems removeObjectAtIndex:mediaIndex];
    [self.delegate networkServerBrowserDidUpdate:self];
}

#pragma mark - media delegate

- (void)mediaDidFinishParsing:(VLCMedia *)aMedia
{
    if ([aMedia parsedStatus] != VLCMediaParsedStatusDone) {
        if ([self.delegate respondsToSelector:@selector(networkServerBrowserShouldPopView:)]) {
            [self.delegate networkServerBrowserShouldPopView:self];
        }
    } else if (self.mediaList.count != 0) {
        [self.delegate networkServerBrowserDidUpdate:self];
    } else {
        if ([self.delegate respondsToSelector:@selector(networkServerBrowserEndParsing:)]) {
            [self.delegate networkServerBrowserEndParsing:self];
        }
    }
}

@end

@interface VLCNetworkServerBrowserItemVLCMedia () <VLCMediaDelegate>
@property (nonatomic, readonly) NSDictionary *mediaOptions;

@end
@implementation VLCNetworkServerBrowserItemVLCMedia
@synthesize name = _name, container = _container, fileSizeBytes = _fileSizeBytes, URL = _URL, media = _media, downloadable = _downloadable;

- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)mediaOptions;
{
    self = [super init];
    if (self) {
        _media = media;
        _container = media.mediaType == VLCMediaTypeDirectory;
        NSString *title = media.metaData.title;
        if (!title) {
            title = [media.url.lastPathComponent stringByRemovingPercentEncoding];
        }
        if (!title) {
            title = [media.url.absoluteString stringByRemovingPercentEncoding];
        }
        _name = title;
        _URL = media.url;
        _mediaOptions = [mediaOptions copy];
    }
    return self;
}

- (id<VLCNetworkServerBrowser>)containerBrowser {
    return [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:self.media options:self.mediaOptions];
}

- (BOOL)isDownloadable
{
    return _media.mediaType == VLCMediaTypeFile;
}

- (NSURL *)thumbnailURL
{
    return _media.metaData.artworkURL;
}

@end
