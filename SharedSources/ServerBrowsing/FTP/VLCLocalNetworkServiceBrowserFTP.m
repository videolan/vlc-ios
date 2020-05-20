/*****************************************************************************
 * VLCLocalNetworkServiceBrowserFTP.m
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

#import "VLCLocalNetworkServiceBrowserFTP.h"
#import "VLCNetworkServerLoginInformation.h"

@interface VLCLocalNetworkServiceFTP ()
+ (void)registerLoginInformation;
@end

@implementation VLCLocalNetworkServiceBrowserFTP

- (instancetype)init {
#if TARGET_OS_TV
    NSString *name = NSLocalizedString(@"FTP_SHORT", nil);
#else
    NSString *name = NSLocalizedString(@"FTP_LONG", nil);
#endif

    return [super initWithName:name
            serviceServiceName:@"ftp"];
}
- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index {
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[VLCLocalNetworkServiceFTP alloc] initWithMediaItem:media serviceName:self.name];
    return nil;
}

+ (void)initialize
{
    [super initialize];
    [VLCLocalNetworkServiceFTP registerLoginInformation];
}

@end


NSString *const VLCNetworkServerProtocolIdentifierFTP = @"ftp";

@implementation VLCLocalNetworkServiceFTP

+ (void)registerLoginInformation
{
    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    login.protocolIdentifier = VLCNetworkServerProtocolIdentifierFTP;

    [VLCNetworkServerLoginInformation registerTemplateLoginInformation:login];
}

- (UIImage *)icon {
    return [UIImage imageNamed:@"serverIcon"];
}

- (VLCNetworkServerLoginInformation *)loginInformation {
    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory) {
        return nil;
    }

    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation newLoginInformationForProtocol:VLCNetworkServerProtocolIdentifierFTP];
    login.address = self.mediaItem.url.host;
    return login;
}

@end


@implementation VLCNetworkServerBrowserVLCMedia (FTP)

+ (instancetype)FTPNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login
{
    NSString *path = [NSString stringWithFormat:@"//%@", login.address];
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:path];
    components.scheme = @"ftp";
    components.port = login.port;
    NSURL *url = components.URL;

    return [self FTPNetworkServerBrowserWithURL:url
                                       username:login.username
                                       password:login.password];
}

+ (instancetype)FTPNetworkServerBrowserWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password
{
	VLCMedia *media = [VLCMedia mediaWithURL:url];
	NSDictionary *mediaOptions = @{@"ftp-user" : username ?: @"",
                                   @"ftp-pwd" : password ?: @""};
	[media addOptions:mediaOptions];
	return [[self alloc] initWithMedia:media options:mediaOptions];
}
@end
