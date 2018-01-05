/*****************************************************************************
 * VLCLocalNetworkServiceBrowserHTTP.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalNetworkServiceBrowserHTTP.h"
#import "VLCSharedLibraryParser.h"
#import "VLCHTTPUploaderController.h"
#import "VLCNetworkServerBrowserSharedLibrary.h"

@interface VLCLocalNetworkServiceBrowserHTTP()
@property (nonatomic) VLCSharedLibraryParser *httpParser;
@end
@implementation VLCLocalNetworkServiceBrowserHTTP
- (instancetype)init {
    return [super initWithName:NSLocalizedString(@"SHARED_VLC_IOS_LIBRARY", nil)
                   serviceType:@"_http._tcp."
                        domain:@""];
}

- (VLCSharedLibraryParser *)httpParser {
    if (!_httpParser) {
        _httpParser = [[VLCSharedLibraryParser alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sharedLibraryFound:)
                                                     name:VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance
                                                   object:_httpParser];
    }
    return _httpParser;
}
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
#if !TARGET_OS_TV
    NSString *ownHostname = [[VLCHTTPUploaderController sharedInstance] hostname];
    if ([[sender hostName] rangeOfString:ownHostname].location != NSNotFound) {
        return;
    }
#endif
    [self.httpParser checkNetserviceForVLCService:sender];
}

- (void)sharedLibraryFound:(NSNotification *)aNotification {
    NSNetService *netService = [aNotification.userInfo objectForKey:@"aNetService"];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self addResolvedLocalNetworkService:[self localServiceForNetService:netService]];
    }];
}

- (VLCLocalNetworkServiceNetService *)localServiceForNetService:(NSNetService *)netService {
    return [[VLCLocalNetworkServiceHTTP alloc] initWithNetService:netService serviceName:self.name];
}
@end



@implementation VLCLocalNetworkServiceHTTP

- (UIImage *)icon {
    return [UIImage imageNamed:@"vlc-sharing"];
}

- (id<VLCNetworkServerBrowser>)serverBrowser {

    NSNetService *service = self.netService;
    if (service.hostName == nil || service.port == 0) {
        return nil;
    }

    NSString *name = service.name;
    NSString *hostName = service.hostName;
    NSUInteger portNum = service.port;
    VLCNetworkServerBrowserSharedLibrary *serverBrowser = [[VLCNetworkServerBrowserSharedLibrary alloc] initWithName:name host:hostName portNumber:portNum];
    return serverBrowser;
}

@end