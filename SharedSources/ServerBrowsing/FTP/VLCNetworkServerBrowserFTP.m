/*****************************************************************************
 * VLCNetworkServerBrowserFTP.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowserFTP.h"
#import "WhiteRaccoon.h"

@interface VLCNetworkServerBrowserFTP () <WRRequestDelegate>
@property (nonatomic) NSURL *url;
@property (nonatomic) WRRequestListDirectory *FTPListDirRequest;

@end

@implementation VLCNetworkServerBrowserFTP
@synthesize delegate = _delegate, items = _items;

#pragma mark - Protocol conformance
- (NSString *)title {
    if ([_url.path isEqualToString:@"/"])
        return _url.host;
    else
        return [_url.path lastPathComponent];
}

- (void)update {
    if (_FTPListDirRequest)
        return;

    _FTPListDirRequest = [[WRRequestListDirectory alloc] init];
    _FTPListDirRequest.delegate = self;
    _FTPListDirRequest.hostname = _url.host;
    _FTPListDirRequest.username = _url.user;
    _FTPListDirRequest.password = _url.password;
    _FTPListDirRequest.path = _url.path;
    _FTPListDirRequest.passive = YES;

    [_FTPListDirRequest start];
}

#pragma mark -

- (instancetype)initWithFTPServer:(NSString *)serverAddress userName:(NSString *)username andPassword:(NSString *)password atPath:(NSString *)path
{
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = @"ftp";
    components.host = serverAddress;
    components.user = username.length ? username : @"anonymous";
    components.password = password.length ? password : nil;
    components.path = path;
    return [self initWithURL:components.URL];
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

- (VLCMediaList *)mediaList
{
    NSMutableArray *mediaArray = [NSMutableArray array];
    @synchronized(_items) {
        NSUInteger count = _items.count;
        for (NSUInteger i = 0; i < count; i++) {
            VLCMedia *media = [_items[i] media];
            if (media)
                [mediaArray addObject:media];
        }
    }
    return [[VLCMediaList alloc] initWithArray:mediaArray];
}

#pragma mark - white raccoon delegation

- (void)requestCompleted:(WRRequest *)request
{
    if (request == _FTPListDirRequest) {
        NSMutableArray *filteredList = [[NSMutableArray alloc] init];
        NSArray *rawList = [(WRRequestListDirectory*)request filesInfo];
        NSUInteger count = rawList.count;

        for (NSUInteger x = 0; x < count; x++) {
            NSDictionary *dict = rawList[x];
            if (![[dict objectForKey:(id)kCFFTPResourceName] hasPrefix:@"."])
                [filteredList addObject:[[VLCNetworkServerBrowserItemFTP alloc] initWithDictionary:dict baseURL:self.url]];
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            @synchronized(_items) {
                _items = [NSArray arrayWithArray:filteredList];
            }
            [self.delegate networkServerBrowserDidUpdate:self];
        }];
    } else
        APLog(@"unknown request %@ completed", request);
}

- (void)requestFailed:(WRRequest *)request
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSDictionary *userInfo = nil;
        if (request.error.message) {
            userInfo = @{ NSLocalizedDescriptionKey : request.error.message };
        }
        NSError *error = [NSError errorWithDomain:@"org.videolan.whiteracoon" code:request.error.errorCode userInfo:userInfo];
        [self.delegate networkServerBrowser:self requestDidFailWithError:error];
        APLog(@"request %@ failed with error %i", request, request.error.errorCode);
    }];
}

@end

@implementation VLCNetworkServerBrowserItemFTP
@synthesize name = _name, container = _container, fileSizeBytes = _fileSizeBytes, URL = _URL;

- (instancetype)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL
{
    self = [super init];
    if (self) {
        NSString *rawFileName = [dict objectForKey:(id)kCFFTPResourceName];
        NSData *flippedData = [rawFileName dataUsingEncoding:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingFTPTextEncoding] intValue] allowLossyConversion:YES];
        if (flippedData != nil) {
            _name = [[NSString alloc] initWithData:flippedData encoding:NSUTF8StringEncoding];
            if (_name == nil) {
                /* this can happen if our string conversation failed */
                _name = rawFileName;
            }
            _container = [dict[(id)kCFFTPResourceType] intValue] == 4;
            _fileSizeBytes = dict[(id)kCFFTPResourceSize];
            _URL = [baseURL URLByAppendingPathComponent:_name];
        }
    }
    return self;
}

- (id<VLCNetworkServerBrowser>)containerBrowser {
    return [[VLCNetworkServerBrowserFTP alloc] initWithURL:self.URL];
}

- (VLCMedia *)media
{
    if (_URL)
        return [VLCMedia mediaWithURL:_URL];
    return nil;
}

@end
