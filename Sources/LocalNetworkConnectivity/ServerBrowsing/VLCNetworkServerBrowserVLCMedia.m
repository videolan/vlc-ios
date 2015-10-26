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

@interface VLCNetworkServerBrowserVLCMedia () <VLCMediaListDelegate, VLCMediaDelegate>
@property (nonatomic) VLCMedia *rootMedia;
@property (nonatomic) VLCMediaList *mediaList;
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
        _rootMedia = media;
        _rootMedia.delegate = self;
        [media parseWithOptions:VLCMediaParseNetwork];
        _mediaList = [_rootMedia subitems];
        _mediaList.delegate = self;
        _mediaOptions = [mediaOptions copy];
    }
    return self;
}

- (void)update {
    int ret = [self.rootMedia parseWithOptions:VLCMediaParseNetwork | VLCMediaFetchNetwork];
    APLog(@"%s: %i", __PRETTY_FUNCTION__, ret);
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
    APLog(@"%s", __PRETTY_FUNCTION__);
    [media parseWithOptions:VLCMediaParseNetwork];
    [media addOptions:self.mediaOptions];
    [self.mutableItems addObject:[[VLCNetworkServerBrowserItemVLCMedia alloc] initWithMedia:media options:self.mediaOptions]];
    [self.delegate networkServerBrowserDidUpdate:self];
}

- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSInteger)index {
    APLog(@"%s", __PRETTY_FUNCTION__);
    [self.mutableItems removeObjectAtIndex:index];
    [self.delegate networkServerBrowserDidUpdate:self];
}

#pragma mark - media delegate

- (void)mediaDidFinishParsing:(VLCMedia *)aMedia
{
    APLog(@"%s", __PRETTY_FUNCTION__);
    [self.delegate networkServerBrowserDidUpdate:self];
}

- (void)mediaMetaDataDidChange:(VLCMedia *)aMedia
{
    APLog(@"%s", __PRETTY_FUNCTION__);
    [self.delegate networkServerBrowserDidUpdate:self];
}

@end

@interface VLCNetworkServerBrowserItemVLCMedia ()
@property (nonatomic, readonly) VLCMedia *media;
@property (nonatomic, readonly) NSDictionary *mediaOptions;

@end
@implementation VLCNetworkServerBrowserItemVLCMedia
@synthesize name = _name, container = _container, fileSizeBytes = _fileSizeBytes, URL = _URL;

- (instancetype)initWithMedia:(VLCMedia *)media options:(NSDictionary *)mediaOptions;
{
    self = [super init];
    if (self) {
        _media = media;
        _container = media.mediaType == VLCMediaTypeDirectory;
        NSString *title = [media metadataForKey:VLCMetaInformationTitle];
        if (!title) {
            title = media.url.lastPathComponent;
        }
        if (!title) {
            title = media.url.absoluteString;
        }
        _name = title;
        _URL = media.url;
        _mediaOptions = [mediaOptions copy];
//        _downloadable = NO; //TODO: add property for downloadable?
    }
    return self;
}

- (id<VLCNetworkServerBrowser>)containerBrowser {
    return [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:self.media options:self.mediaOptions];
}

@end


@implementation VLCNetworkServerBrowserVLCMedia (SMB)
+ (instancetype)SMBNetworkServerBrowserWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password workgroup:(NSString *)workgroup {

    VLCMedia *media = [VLCMedia mediaWithURL:url];
    NSDictionary *mediaOptions = @{@"smb-user" : username ?: @"",
                                   @"smb-pwd" : password ?: @"",
                                   @"smb-domain" : workgroup?: @"WORKGROUP"};
    [media addOptions:mediaOptions];
    return [[self alloc] initWithMedia:media options:mediaOptions];
}
@end
