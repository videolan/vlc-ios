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
#import "NSString+SupportedMedia.h"

@interface VLCNetworkServerBrowserFTP () <WRRequestDelegate>
@property (nonatomic) NSURL *url;
@property (nonatomic) WRRequestListDirectory *FTPListDirRequest;

@end

@implementation VLCNetworkServerBrowserFTP
@synthesize delegate = _delegate, items = _items, mediaList = _mediaList;

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
    _FTPListDirRequest.password = [_url.password stringByRemovingPercentEncoding];
    _FTPListDirRequest.path = _url.path;
    _FTPListDirRequest.passive = YES;

    [_FTPListDirRequest start];
}

#pragma mark -

- (instancetype)initWithLogin:(VLCNetworkServerLoginInformation *)login
{
    return [self initWithFTPServer:login.address
                          userName:login.username
                       andPassword:login.password
                            atPath:@"/"];
}

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

#pragma mark - white raccoon delegation

- (NSURL*)searchSubtitleForFile:(NSString *)filename inSubtitleList:(NSArray *)subtitleList
{
    NSString *filenameNoExt = [[filename lastPathComponent] stringByDeletingPathExtension];

    for (NSString *subtitle in subtitleList) {
        if ([[[subtitle lastPathComponent] stringByDeletingPathExtension] isEqualToString:filenameNoExt])
            return [self.url URLByAppendingPathComponent:subtitle];
    }

    return nil;
}

- (void)requestCompleted:(WRRequest *)request
{
    if (request == _FTPListDirRequest) {
        NSMutableArray *subtitleList = [[NSMutableArray alloc] init];
        NSMutableArray *filteredList = [[NSMutableArray alloc] init];
        NSArray *rawList = [(WRRequestListDirectory*)request filesInfo];
        NSUInteger count = rawList.count;

        for (NSUInteger x = 0; x < count; x++) {
            NSDictionary *dict = rawList[x];

            if ([[dict objectForKey:(id)kCFFTPResourceName] isSupportedSubtitleFormat])
                [subtitleList addObject:[dict objectForKey:(id)kCFFTPResourceName]];
        }

        for (NSUInteger x = 0; x < count; x++) {
            NSDictionary *dict = rawList[x];
            NSString *filename = [dict objectForKey:(id)kCFFTPResourceName];
            BOOL container = [[dict objectForKey:(id)kCFFTPResourceType] intValue] == 4;

            if (![filename hasPrefix:@"."])
            {
                NSURL *subtitleURL = nil;

                if ([filename isSupportedAudioMediaFormat] || [filename isSupportedMediaFormat])
                    subtitleURL = [self searchSubtitleForFile:filename inSubtitleList:subtitleList];
                else if ((!container) && ![filename isSupportedSubtitleFormat])
                    continue;

                [filteredList addObject:[[VLCNetworkServerBrowserItemFTP alloc] initWithDictionary:dict baseURL:self.url subtitleURL:subtitleURL]];
            }
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            @synchronized(_items) {
                _items = [NSArray arrayWithArray:filteredList];
            }
            _mediaList = [self buildMediaList];
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

- (instancetype)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL subtitleURL:(NSURL *)subtitleURL
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
            _subtitleURL = subtitleURL;
        }
    }
    return self;
}

- (id<VLCNetworkServerBrowser>)containerBrowser {
    return [[VLCNetworkServerBrowserFTP alloc] initWithURL:self.URL];
}

- (BOOL)isDownloadable
{
    //VLC also needs an extension in the filename for this to work.
    return YES;
}

- (VLCMedia *)media
{
    if (_URL)
        return [VLCMedia mediaWithURL:_URL];
    return [VLCMedia mediaAsNodeWithName:self.name];
}

@end
