/*****************************************************************************
 * VLCNetworkServerBrowserVLCMedia.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2020, 2026 VideoLAN. All rights reserved.
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

@interface VLCNetworkServerBrowserVLCMedia () <VLCMediaDelegate>
{
    VLCDialogProvider *_dialogProvider;
    VLCCustomDialogRendererHandler *_customDialogHandler;
    VLCMediaParser *_mediaParser;
}

@property (nonatomic) VLCMedia *rootMedia;
@property (nonatomic) VLCMediaList *mediaList;
@property (nonatomic) NSMutableArray<id<VLCNetworkServerBrowserItem>> *mutableItems;
@property (nonatomic, readonly) NSDictionary *mediaOptions;

@end
@implementation VLCNetworkServerBrowserVLCMedia
@synthesize delegate = _delegate;

- (instancetype)initWithMedia:(VLCMedia *)media
                      options:(nonnull NSDictionary *)mediaOptions
{
    return [self initWithMedia:media options:mediaOptions mediaParser:nil];
}

- (instancetype)initWithMedia:(VLCMedia *)media
                      options:(nonnull NSDictionary *)mediaOptions
                  mediaParser:(VLCMediaParser *)mediaParser
{
    self = [super init];
    if (self) {
        _mediaParser = mediaParser ?: [VLCMediaParser sharedParser];
        _mutableItems = [[NSMutableArray alloc] init];
        _mediaList = [[VLCMediaList alloc] init];
        _rootMedia = media;
        _rootMedia.delegate = self;
        NSMutableDictionary *mediaOptionsNoFilter = [mediaOptions mutableCopy];
        [mediaOptionsNoFilter setObject:@" " forKey:@":ignore-filetypes"];
        _mediaOptions = [mediaOptionsNoFilter copy];

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
    [_mediaParser cancelParsingForMedia:_rootMedia];
}

- (void)customDialogCompletionHandlerWithStatus:(VLCCustomDialogRendererHandlerCompletionType)status
{
    if (status == VLCCustomDialogRendererHandlerCompletionTypeStop) {
        [_mediaParser cancelParsingForMedia:_rootMedia];
    }
}

- (void)_rebuildItemList
{
    [self.mutableItems removeAllObjects];
    while (self.mediaList.count > 0) {
        [self.mediaList removeMediaAtIndex:0];
    }

    VLCMediaList *rootItems = self.rootMedia.subitems;
    [rootItems lock];
    NSUInteger count = rootItems.count;
    for (NSUInteger i = 0; i < count; i++) {
        VLCMedia *media = [rootItems mediaAtIndex:i];
        [media addOptions:self.mediaOptions];
        NSInteger mediaIndex = self.mutableItems.count;
        [self.mediaList insertMedia:media atIndex:mediaIndex];
        [self.mutableItems insertObject:[[VLCNetworkServerBrowserItemVLCMedia alloc] initWithMedia:media
                                                                                           options:self.mediaOptions
                                                                                       mediaParser:_mediaParser]
                                atIndex:mediaIndex];
    }
    [rootItems unlock];
}

- (void)update {
    int ret = [_mediaParser queueMedia:self.rootMedia options:VLCMediaParse];
    if (ret == -1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate networkServerBrowserDidUpdate:self];
        });
    }
}

- (NSString *)title {
    return self.rootMedia.metaData.title;
}

- (NSArray<id<VLCNetworkServerBrowserItem>> *)items {
    return self.mutableItems.copy;
}

- (VLCMediaParsedStatus)retrieveParsedStatus
{
    return _rootMedia.parsedStatus;
}

#pragma mark - media delegate

- (void)mediaDidChangeSubitems:(VLCMedia *)aMedia
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _rebuildItemList];
        [self.delegate networkServerBrowserDidUpdate:self];
    });
}

- (void)mediaDidFinishParsing:(VLCMedia *)aMedia
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _rebuildItemList];

        if (self.mediaList.count != 0) {
            [self.delegate networkServerBrowserDidUpdate:self];
        } else {
            if ([self.delegate respondsToSelector:@selector(networkServerBrowserEndParsing:)]) {
                [self.delegate networkServerBrowserEndParsing:self];
            }
        }
    });
}

@end

@interface VLCNetworkServerBrowserItemVLCMedia () <VLCMediaDelegate>
{
    VLCMediaParser *_mediaParser;
}
@property (nonatomic, readonly) NSDictionary *mediaOptions;

@end
@implementation VLCNetworkServerBrowserItemVLCMedia
@synthesize name = _name, container = _container, fileSizeBytes = _fileSizeBytes, URL = _URL, media = _media, downloadable = _downloadable;

- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)mediaOptions
{
    return [self initWithMedia:media options:mediaOptions mediaParser:nil];
}

- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)mediaOptions mediaParser:(VLCMediaParser *)mediaParser
{
    self = [super init];
    if (self) {
        _mediaParser = mediaParser;
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
        uint64_t fileSize;
        [media fileStatValueForType:VLCMediaFileStatTypeSize value:&fileSize];
        if (fileSize > 0) {
            _fileSizeBytes = [NSNumber numberWithUnsignedLongLong:fileSize];
        }
    }
    return self;
}

- (id<VLCNetworkServerBrowser>)containerBrowser {
    return [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:self.media
                                                          options:self.mediaOptions
                                                      mediaParser:_mediaParser];
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
