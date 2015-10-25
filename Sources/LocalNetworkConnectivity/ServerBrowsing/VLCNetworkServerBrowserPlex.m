/*****************************************************************************
 * VLCNetworkServerBrowserPlex.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowserPlex.h"
#import "VLCPlexParser.h"
#import "VLCPlexWebAPI.h"

@interface VLCNetworkServerBrowserPlex ()
@property (nonatomic, readonly) NSString *addressOrName;
@property (nonatomic, readonly) NSUInteger port;

@property (nonatomic, readwrite) NSString *title;
@property (nonatomic, readonly) NSString *plexServerAddress;
@property (nonatomic, readonly) NSNumber *plexServerPort;
@property (nonatomic, readonly) NSString *plexServerPath;

@property (nonatomic) NSString *plexAuthentification;

@property (nonatomic, readonly) VLCPlexParser *plexParser;
@property (nonatomic, readonly) VLCPlexWebAPI *plexWebAPI;

@property (nonatomic, readonly) NSOperationQueue *plexQueue;

@property (nonatomic, readwrite) NSArray<id<VLCNetworkServerBrowserItem>> *items;
@end

@implementation VLCNetworkServerBrowserPlex
@synthesize title = _title, delegate = _delegate, items = _items;

- (instancetype)initWithName:(NSString *)name host:(NSString *)addressOrName portNumber:(NSNumber *)portNumber path:(NSString *)path authentificication:(NSString *)auth
{
    self = [super init];
    if (self) {
        _title = name;
        _plexServerAddress = addressOrName;
        _plexServerPort = portNumber;
        _plexServerPath = path;

        _plexAuthentification = auth;

        _plexParser = [[VLCPlexParser alloc] init];
        _plexWebAPI = [[VLCPlexWebAPI alloc] init];

        _plexQueue = [[NSOperationQueue alloc] init];
        _plexQueue.maxConcurrentOperationCount = 1;
        _plexQueue.name = @"org.videolan.vlc-ios.plex.update";

        _items = [NSArray new];

    }
    return self;
}

- (instancetype)initWithName:(NSString *)name url:(NSURL *)url auth:(NSString *)auth {
    return [self initWithName:name host:url.host portNumber:url.port path:url.path authentificication:auth];
}

- (void)update {
    [self.plexQueue addOperationWithBlock:^{
        [self loadContents];
    }];
}

- (void)loadContents
{
    NSArray *dicts = [self.plexParser PlexMediaServerParser:self.plexServerAddress port:self.plexServerPort navigationPath:self.plexServerPath authentification:self.plexAuthentification];

    NSDictionary *firstObject = [dicts firstObject];
    NSString *newAuth = firstObject[@"authentification"] ?: @"";

    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = @"http";
    components.host = self.plexServerAddress;
    components.port = self.plexServerPort;
    components.path = self.plexServerPath;
    NSURL *url = components.URL;

    NSMutableArray *newItems = [NSMutableArray new];
    for (NSDictionary *dict in dicts) {
        VLCNetworkServerBrowserItemPlex *item = [[VLCNetworkServerBrowserItemPlex alloc] initWithDictionary:dict currentURL:url authentificication:newAuth];
        [newItems addObject:item];
    }

    NSString *titleValue = firstObject[@"libTitle"];
    if (titleValue.length) {
        self.title = titleValue;
    }
    self.plexAuthentification = newAuth;
    self.items = [newItems copy];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.delegate networkServerBrowserDidUpdate:self];
    }];
}


- (NSString *)_urlAuth:(NSString *)url
{
    return [self.plexWebAPI urlAuth:url authentification:self.plexAuthentification];
}
@end


@interface VLCNetworkServerBrowserItemPlex()

@property (nonatomic) NSString *plexAuthentification;
@end
@implementation VLCNetworkServerBrowserItemPlex
@synthesize name = _name, URL = _URL, fileSizeBytes = _fileSizeBytes, container = _container;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary currentURL:(NSURL *)currentURL authentificication:(NSString *)auth
{
    self = [super init];
    if (self) {

        _plexAuthentification = auth;
        
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:currentURL resolvingAgainstBaseURL:NO];

        NSString *path = components.path;
        components.path = nil;
        NSURL *baseURL = components.URL;

        _container = ![dictionary[@"container"] isEqualToString:@"item"];
        NSString *urlPath;
        if (_container) {
            NSString *keyPath = nil;
            NSString *keyValue = dictionary[@"key"];
            if ([keyValue rangeOfString:@"library"].location == NSNotFound) {
                keyPath = [path stringByAppendingPathComponent:keyValue];
            } else {
                keyPath = keyValue;
            }
            urlPath = [baseURL URLByAppendingPathComponent:keyPath].absoluteString;
        } else {
            urlPath = dictionary[@"keyMedia"];
        }

        urlPath = [VLCPlexWebAPI urlAuth:urlPath authentification:auth];
        _URL = [NSURL URLWithString:urlPath];

        _name = dictionary[@"title"];
        NSString *thumbPath = dictionary[@"thumb"];
        if (thumbPath) {
            thumbPath = [VLCPlexWebAPI urlAuth:thumbPath authentification:auth];
        }
        _thumbnailURL = thumbPath.length ? [baseURL URLByAppendingPathComponent:thumbPath] : nil;


        _duration = dictionary[@"duration"];
        _fileSizeBytes = dictionary[@"size"];

        NSString *subtitleURLString = dictionary[@"keySubtitle"];
        if (subtitleURLString) {
            subtitleURLString = [VLCPlexWebAPI urlAuth:subtitleURLString authentification:auth];
        }

        _subtitleURL = subtitleURLString.length ? [baseURL URLByAppendingPathComponent:subtitleURLString] : nil;
    }
    return self;
}

- (id<VLCNetworkServerBrowser>)containerBrowser {
    return [[VLCNetworkServerBrowserPlex alloc] initWithName:self.name url:self.URL auth:self.plexAuthentification];
}

@end