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

@interface VLCNetworkServerBrowserVLCMedia () <VLCMediaListDelegate>
@property (nonatomic) VLCMedia *rootMedia;
@property (nonatomic) VLCMediaList *mediaList;
@property (nonatomic) NSMutableArray<id<VLCNetworkServerBrowserItem>> *mutableItems;
@end
@implementation VLCNetworkServerBrowserVLCMedia
@synthesize delegate = _delegate;

- (instancetype)initWithMedia:(VLCMedia *)media
{
    self = [super init];
    if (self) {
        _mutableItems = [[NSMutableArray alloc] init];
        _rootMedia = media;
        [media parseWithOptions:VLCMediaParseNetwork];
        _mediaList = [_rootMedia subitems];
        _mediaList.delegate = self;
    }
    return self;
}
- (void)update {
    [self.rootMedia parseWithOptions:VLCMediaParseNetwork];
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
    [media parseWithOptions:VLCMediaParseNetwork];
    [self.mutableItems addObject:[[VLCNetworkServerBrowserItemVLCMedia alloc] initWithMedia:media]];
    [self.delegate networkServerBrowserDidUpdate:self];
}

- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSInteger)index {
    [self.mutableItems removeObjectAtIndex:index];
    [self.delegate networkServerBrowserDidUpdate:self];
}

@end


@interface VLCNetworkServerBrowserItemVLCMedia ()
@property (nonatomic, readonly) VLCMedia *media;
@end
@implementation VLCNetworkServerBrowserItemVLCMedia
@synthesize name = _name, container = _container, fileSizeBytes = _fileSizeBytes, URL = _URL;

- (instancetype)initWithMedia:(VLCMedia *)media
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
//        _downloadable = NO; //TODO: add property for downloadable?
    }
    return self;
}

- (id<VLCNetworkServerBrowser>)containerBrowser {
    return [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:self.media];
}

@end


@implementation VLCNetworkServerBrowserVLCMedia (SMB)
+ (instancetype)SMBNetworkServerBrowserWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password workgroup:(NSString *)workgroup {

    VLCMedia *media = [VLCMedia mediaWithURL:url];
    NSDictionary *mediaOptions = @{@"smb-user" : username ?: @"",
                                   @"smb-pwd" : password ?: @"",
                                   @"smb-domain" : workgroup?: @"WORKGROUP"};
    [media addOptions:mediaOptions];
    return [[self alloc] initWithMedia:media];
}
@end


