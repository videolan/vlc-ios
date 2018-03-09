/*****************************************************************************
 * VLCNetworkServerBrowserUPnP.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowserUPnP.h"

#import "MediaServerBasicObjectParser.h"
#import "MediaServer1ItemObject.h"
#import "MediaServer1ContainerObject.h"
#import "MediaServer1Device.h"
#import "BasicUPnPDevice+VLC.h"

@interface VLCNetworkServerBrowserUPnP ()
@property (nonatomic, readonly) MediaServer1Device *upnpDevice;
@property (nonatomic, readonly) NSString *upnpRootID;
@property (nonatomic, readonly) NSOperationQueue *upnpQueue;

@property (nonatomic, readwrite) NSArray<id<VLCNetworkServerBrowserItem>> *items;

@end

@implementation VLCNetworkServerBrowserUPnP
@synthesize title = _title, delegate = _delegate, items = _items, mediaList = _mediaList;

- (instancetype)initWithUPNPDevice:(MediaServer1Device *)device header:(NSString *)header andRootID:(NSString *)upnpRootID
{
    self = [super init];
    if (self) {
        _upnpDevice = device;
        _title = header;
        _upnpRootID = upnpRootID;
        _upnpQueue = [[NSOperationQueue alloc] init];
        _upnpQueue.maxConcurrentOperationCount = 1;
        _upnpQueue.name = @"org.videolan.vlc-ios.upnp.update";
        _items = [NSArray array];
    }
    return self;
}
- (void)update {
    [self.upnpQueue addOperationWithBlock:^{

        NSString *sortCriteria = @"";
        NSMutableString *outSortCaps = [[NSMutableString alloc] init];
        [[self.upnpDevice contentDirectory] GetSortCapabilitiesWithOutSortCaps:outSortCaps];

        if ([outSortCaps rangeOfString:@"dc:title"].location != NSNotFound)
        {
            sortCriteria = @"+dc:title";
        }

        NSMutableString *outResult = [[NSMutableString alloc] init];
        NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
        NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
        NSMutableString *outUpdateID = [[NSMutableString alloc] init];

        [[self.upnpDevice contentDirectory] BrowseWithObjectID:self.upnpRootID BrowseFlag:@"BrowseDirectChildren" Filter:@"*" StartingIndex:@"0" RequestedCount:@"0" SortCriteria:sortCriteria OutResult:outResult OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];

        NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];
        MediaServerBasicObjectParser *parser;
        NSMutableArray *objectsArray = [[NSMutableArray alloc] init];
        parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:objectsArray itemsOnly:NO];
        [parser parseFromData:didl];

        NSMutableArray *itemsArray = [[NSMutableArray alloc] init];

        for (MediaServer1BasicObject *object in objectsArray) {
            [itemsArray addObject:[[VLCNetworkServerBrowserItemUPnP alloc] initWithBasicObject:object device:self.upnpDevice]];
        }

        @synchronized(_items) {
            _items = [itemsArray copy];
        }
        _mediaList = [self buildMediaList];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.delegate networkServerBrowserDidUpdate:self];
        }];
    }];
}

- (VLCMediaList *)buildMediaList
{
    NSMutableArray *mediaArray;
    @synchronized(_items) {
        mediaArray = [NSMutableArray new];
        for (id<VLCNetworkServerBrowserItem> item in _items) {
            VLCMedia *media = [item media];
            if (media)
                [mediaArray addObject:media];
        }
    }
    VLCMediaList *mediaList = [[VLCMediaList alloc] initWithArray:mediaArray];
    return mediaList;
}

@end


@interface MediaServer1ItemObject (VLC)
@end

@implementation MediaServer1ItemObject (VLC)

- (id)vlc_ressourceItemForKey:(NSString *)key urlString:(NSString *)urlString device:(MediaServer1Device *)device {

    // Provide users with a descriptive action sheet for them to choose based on the multiple resources advertised by DLNA devices (HDHomeRun for example)

    NSRange position = [key rangeOfString:kVLCUPnPVideoProtocolKey];

    if (position.location == NSNotFound)
        return nil;

    NSString *orgPNValue;
    NSString *transcodeValue;

    // Attempt to parse DLNA.ORG_PN first
    NSArray *components = [key componentsSeparatedByString:@";"];
    NSArray *nonFlagsComponents = [components[0] componentsSeparatedByString:@":"];
    NSString *orgPN = [nonFlagsComponents lastObject];

    // Check to see if we are where we should be
    NSRange orgPNRange = [orgPN rangeOfString:@"DLNA.ORG_PN="];
    if (orgPNRange.location == 0) {
        orgPNValue = [orgPN substringFromIndex:orgPNRange.length];
    }

    // HDHomeRun: Get the transcode profile from the HTTP API if possible
    if ([device VLC_isHDHomeRunMediaServer]) {
        NSRange transcodeRange = [urlString rangeOfString:@"transcode="];
        if (transcodeRange.location != NSNotFound) {
            transcodeValue = [urlString substringFromIndex:transcodeRange.location + transcodeRange.length];
            // Check that there are no more parameters
            NSRange ampersandRange = [transcodeValue rangeOfString:@"&"];
            if (ampersandRange.location != NSNotFound) {
                transcodeValue = [transcodeValue substringToIndex:transcodeRange.location];
            }

            transcodeValue = [transcodeValue capitalizedString];
        }
    }

    // Fallbacks to get the most descriptive resource title
    NSString *profileTitle;
    if ([transcodeValue length] && [orgPNValue length]) {
        profileTitle = [NSString stringWithFormat:@"%@ (%@)", transcodeValue, orgPNValue];
    } else if ([transcodeValue length]) {
        profileTitle = transcodeValue;
    } else if ([orgPNValue length]) {
        profileTitle = orgPNValue;
    } else if ([key length]) {
        profileTitle = key;
    } else if ([urlString length]) {
        profileTitle = urlString;
    } else  {
        profileTitle = NSLocalizedString(@"UNKNOWN", nil);
    }

    return [[VLCNetworkServerBrowserItemUPnPMultiRessource alloc] initWithTitle:profileTitle url:[NSURL URLWithString:urlString]];
}

- (NSArray *)vlc_ressourceItemsForDevice:(MediaServer1Device *)device {

    // Store it so we can act on the action sheet callback.

    NSMutableArray *array = [NSMutableArray array];
    [uriCollection enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *  _Nonnull urlString, BOOL * _Nonnull stop) {
        id item = [self vlc_ressourceItemForKey:key urlString:urlString device:device];
        if (item) {
            [array addObject:item];
        }
    }];
    return [array copy];
}

@end

@interface VLCNetworkServerBrowserItemUPnP ()
@property (nonatomic, readonly) MediaServer1BasicObject *mediaServerObject;
@property (nonatomic, readonly) MediaServer1Device *upnpDevice;

@end

@implementation VLCNetworkServerBrowserItemUPnP
@synthesize container = _container, name = _name, URL = _URL, fileSizeBytes = _fileSizeBytes;
- (instancetype)initWithBasicObject:(MediaServer1BasicObject *)basicObject device:(nonnull MediaServer1Device *)device
{
    self = [super init];
    if (self) {
        _mediaServerObject = basicObject;
        _upnpDevice = device;
        _name = basicObject.title;
        _thumbnailURL = [NSURL URLWithString:basicObject.albumArt];

        _fileSizeBytes = nil;
        _duration = nil;
        _URL = nil;

        _container = basicObject.isContainer;
        if (!_container && [basicObject isKindOfClass:[MediaServer1ItemObject class]]) {
            MediaServer1ItemObject *mediaItem = (MediaServer1ItemObject *)basicObject;

            long long mediaSize = 0;
            unsigned int durationInSeconds = 0;
            unsigned int bitrate = 0;

            for (MediaServer1ItemRes *resource in mediaItem.resources) {
                if (resource.bitrate > 0 && resource.durationInSeconds > 0) {
                    mediaSize = resource.size;
                    durationInSeconds = resource.durationInSeconds;
                    bitrate = resource.bitrate;
                }
            }
            if (mediaSize < 1)
                mediaSize = [mediaItem.size integerValue];

            if (mediaSize < 1)
                mediaSize = (bitrate * durationInSeconds);

            // object.item.videoItem.videoBroadcast items (like the HDHomeRun) may not have this information. Center the title (this makes channel names look better for the HDHomeRun)
            if (mediaSize > 0) {
                _fileSizeBytes = @(mediaSize);
            }
            if (durationInSeconds > 0) {
                _duration = [VLCTime timeWithInt:durationInSeconds * 1000].stringValue;
            }

            NSArray<NSString *>* protocolStrings = [[mediaItem uriCollection] allKeys];
            protocolStrings = [protocolStrings filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString * _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                if (evaluatedObject == nil || ![evaluatedObject isKindOfClass:[NSString class]])
                    return NO;

                if ([evaluatedObject respondsToSelector:@selector(containsString:)]) {
                    if ([evaluatedObject containsString:kVLCUPnPVideoProtocolKey])
                        return YES;
                    if ([evaluatedObject containsString:kVLCUPnPAudioProtocolKey])
                        return YES;
                } else {
                    NSRange foundRange = [evaluatedObject rangeOfString:kVLCUPnPVideoProtocolKey];
                    if (foundRange.location != NSNotFound)
                        return YES;
                    foundRange = [evaluatedObject rangeOfString:kVLCUPnPAudioProtocolKey];
                    if (foundRange.location != NSNotFound)
                        return YES;
                }
                return NO;
            }]];

            // Check for multiple URIs.
            if ([mediaItem.uriCollection count] > 1) {
                for (NSString *key in mediaItem.uriCollection) {
                    if ([key respondsToSelector:@selector(containsString:)]) {
                        if ([key containsString:kVLCUPnPVideoProtocolKey] || [key containsString:kVLCUPnPAudioProtocolKey]) {
                            mediaItem.uri = [mediaItem.uriCollection objectForKey:key];
                        }
                    } else {
                        NSRange foundRage = [key rangeOfString:kVLCUPnPVideoProtocolKey];
                        if (foundRage.location != NSNotFound) {
                            mediaItem.uri = [mediaItem.uriCollection objectForKey:key];
                        } else {
                            foundRage = [key rangeOfString:kVLCUPnPAudioProtocolKey];
                            if (foundRage.location != NSNotFound) {
                                mediaItem.uri = [mediaItem.uriCollection objectForKey:key];
                            }
                        }
                    }
                }
            }
            _URL = [NSURL URLWithString:[mediaItem uri]];
        }
    }
    return self;
}

- (BOOL)isContainer {
    return self.mediaServerObject.isContainer;
}
- (BOOL)isDownloadable {
    // Disable downloading for the HDHomeRun for now to avoid infinite downloads (URI needs a duration parameter, otherwise you are just downloading a live stream). VLC also needs an extension in the file name for this to work.
    BOOL downloadable = ![self.upnpDevice VLC_isHDHomeRunMediaServer];
    return downloadable;
}

- (id<VLCNetworkServerBrowser>)containerBrowser {
    MediaServer1BasicObject *basicObject = self.mediaServerObject;
    if (basicObject.isContainer) {
        return [[VLCNetworkServerBrowserUPnP alloc] initWithUPNPDevice:self.upnpDevice header:self.mediaServerObject.title andRootID:self.mediaServerObject.objectID];
    } else if ([basicObject isKindOfClass:[MediaServer1ItemObject class]]) {
        return [[VLCNetworkServerBrowserUPnPMultiRessource alloc] initWithItem:(MediaServer1ItemObject *)self.mediaServerObject device:self.upnpDevice];
    } else {
        return nil;
    }
}

- (UIImage *)image {
    UIImage *broadcastImage = nil;
    // Custom TV icon for video broadcasts
    if ([[self.mediaServerObject objectClass] isEqualToString:@"object.item.videoItem.videoBroadcast"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            broadcastImage = [UIImage imageNamed:@"TVBroadcastIcon"];
        } else {
            broadcastImage = [UIImage imageNamed:@"TVBroadcastIcon~ipad"];
        }
    }
    return broadcastImage;
}

- (VLCMedia *)media
{
    if (!_URL)
        return [VLCMedia mediaAsNodeWithName:self.name];

    VLCMedia *media = [VLCMedia mediaWithURL:_URL];
    NSString *title = self.name;
    if (title.length) {
        [media setMetadata:self.name forKey:VLCMetaInformationTitle];
    }

    return media;
}

@end

#pragma mark - Multi Ressource

@implementation VLCNetworkServerBrowserUPnPMultiRessource
@synthesize items = _items, title = _title, delegate = _delegate, mediaList = _mediaList;

- (instancetype)initWithItem:(MediaServer1ItemObject *)itemObject device:(MediaServer1Device *)device
{
    self = [super init];
    if (self) {
        _title = [itemObject title];
        _items = [itemObject vlc_ressourceItemsForDevice:device];
        _mediaList = [self buildMediaList];
    }
    return self;
}

- (void) update {
    [self.delegate networkServerBrowserDidUpdate:self];
}

- (VLCMediaList *)buildMediaList
{
    VLCMediaList *mediaList = [[VLCMediaList alloc] init];
    @synchronized(_items) {
        for (id<VLCNetworkServerBrowserItem> browseritem in _items) {
            VLCMedia *media = [browseritem media];
            if (media)
                [mediaList addMedia:media];
        }
    }
    return mediaList;
}

@end


@implementation VLCNetworkServerBrowserItemUPnPMultiRessource
@synthesize URL = _URL, container = _container, fileSizeBytes = _fileSizeBytes, name =_name;

- (instancetype)initWithTitle:(NSString *)title url:(NSURL *)url
{
    self = [super init];
    if (self) {
        _name = title;
        _URL = url;
        _container = NO;
        _fileSizeBytes = nil;
    }
    return self;
}

- (id<VLCNetworkServerBrowser>)containerBrowser {
    return nil;
}

- (VLCMedia *)media
{
    if (!_URL)
        return nil;

    VLCMedia *media = [VLCMedia mediaWithURL:_URL];
    NSString *title = self.name;
    if (title.length) {
        [media setMetadata:self.name forKey:VLCMetaInformationTitle];
    }

    return media;
}

@end
