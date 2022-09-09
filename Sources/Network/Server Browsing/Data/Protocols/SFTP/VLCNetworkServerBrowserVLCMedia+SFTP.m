/*****************************************************************************
 * VLCNetworkServerBrowserVLCMedia+FTP.m
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

#import "VLCNetworkServerBrowserVLCMedia+SFTP.h"
#import "VLCNetworkServerLoginInformation.h"

NSString *const VLCNetworkServerProtocolIdentifierSFTP = @"sftp";

@implementation VLCNetworkServerBrowserVLCMedia (SFTP)

+ (instancetype)SFTPNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login
{
    NSString *path = [NSString stringWithFormat:@"//%@", login.address];
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:path];
    components.scheme = @"sftp";
    components.port = login.port;
    NSURL *url = components.URL;

    return [self SFTPNetworkServerBrowserWithURL:url
                                        username:login.username
                                        password:login.password];
}

+ (instancetype)SFTPNetworkServerBrowserWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password
{
	VLCMedia *media = [VLCMedia mediaWithURL:url];
	NSDictionary *mediaOptions = @{@"sftp-user" : username ?: @"",
                                   @"sftp-pwd" : password ?: @""};
	[media addOptions:mediaOptions];
	return [[self alloc] initWithMedia:media options:mediaOptions];
}
@end
