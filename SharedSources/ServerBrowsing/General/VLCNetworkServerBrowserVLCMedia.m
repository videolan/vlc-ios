/*****************************************************************************
 * VLCNetworkServerBrowserVLCMedia.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowserVLCMedia.h"
#import "NSString+SupportedMedia.h"

@interface VLCNetworkServerBrowserVLCMedia () <VLCMediaListDelegate, VLCMediaDelegate>
{
    BOOL _needsNotifyDelegate;
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
        [media parseWithOptions:VLCMediaParseNetwork];
        _mediaListUnfiltered = [_rootMedia subitems];
        _mediaListUnfiltered.delegate = self;
        NSMutableDictionary *mediaOptionsNoFilter = [mediaOptions mutableCopy];
        [mediaOptionsNoFilter setObject:@" " forKey:@":ignore-filetypes"];
        _mediaOptions = [mediaOptionsNoFilter copy];
        [self _addMediaListRootItemsToList];
    }
    return self;
}

- (BOOL)shouldFilterMedia:(VLCMedia *)media
{
    NSString *absoluteString = media.url.absoluteString;
    return ![absoluteString isSupportedAudioMediaFormat] && ![absoluteString isSupportedMediaFormat] && ![absoluteString isSupportedPlaylistFormat] && media.mediaType != VLCMediaTypeDirectory;
}

- (void)_addMediaListRootItemsToList
{
    VLCMediaList *rootItems = _rootMedia.subitems;
    [rootItems lock];
    NSUInteger count = rootItems.count;
    for (NSUInteger i = 0; i < count; i++) {
        VLCMedia *media = [rootItems mediaAtIndex:i];
        if (![self shouldFilterMedia:media]) {
            NSInteger mediaIndex = self.mutableItems.count;
            [self.mediaList insertMedia:media atIndex:mediaIndex];
            [self.mutableItems insertObject:[[VLCNetworkServerBrowserItemVLCMedia alloc] initWithMedia:media options:self.mediaOptions] atIndex:mediaIndex];
        }
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
    return [self.rootMedia metadataForKey:VLCMetaInformationTitle];
}

- (NSArray<id<VLCNetworkServerBrowserItem>> *)items {
    return self.mutableItems.copy;
}

#pragma mark - media list delegate

- (void)mediaList:(VLCMediaList *)aMediaList mediaAdded:(VLCMedia *)media atIndex:(NSInteger)index
{
    [media addOptions:self.mediaOptions];
    if (![self shouldFilterMedia:media]) {
        NSInteger mediaIndex = self.mutableItems.count;
        [self.mediaList insertMedia:media atIndex:mediaIndex];
        [self.mutableItems insertObject:[[VLCNetworkServerBrowserItemVLCMedia alloc] initWithMedia:media options:self.mediaOptions] atIndex:mediaIndex];
    }

    [self.delegate networkServerBrowserDidUpdate:self];
}

- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSInteger)index
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
    [self setNeedsNotifyDelegateForDidUpdate];
}
- (void)mediaMetaDataDidChange:(VLCMedia *)aMedia
{
    [self setNeedsNotifyDelegateForDidUpdate];
}

- (void)setNeedsNotifyDelegateForDidUpdate
{
    if (_needsNotifyDelegate) {
        return;
    }
    _needsNotifyDelegate = YES;

    double amountOfSeconds = 0.1;
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(amountOfSeconds * NSEC_PER_SEC));
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        _needsNotifyDelegate = NO;
        [self.delegate networkServerBrowserDidUpdate:self];
    });
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
        NSString *title = [media metadataForKey:VLCMetaInformationTitle];
        if (!title) {
            title = [media.url.lastPathComponent stringByRemovingPercentEncoding];
        }
        if (!title) {
            title = [media.url.absoluteString stringByRemovingPercentEncoding];
        }
        _name = title;
        _URL = media.url;
        _mediaOptions = [mediaOptions copy];
        _downloadable = NO;
    }
    return self;
}

- (id<VLCNetworkServerBrowser>)containerBrowser {
    return [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:self.media options:self.mediaOptions];
}

@end
