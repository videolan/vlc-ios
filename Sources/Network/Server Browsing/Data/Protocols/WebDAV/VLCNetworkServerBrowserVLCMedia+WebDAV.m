/*****************************************************************************
 * VLCNetworkServerBrowserVLCMedia+WebDAV.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowserVLCMedia+WebDAV.h"
#import "VLCNetworkServerLoginInformation.h"

NSString *const VLCNetworkServerProtocolIdentifierWebDAV = @"WEBDAV";

@implementation VLCNetworkServerBrowserVLCMedia (WebDAV)

+ (instancetype)WebDAVNetworkServerBrowserWithLogin:(VLCNetworkServerLoginInformation *)login
{
    NSURLComponents *components = [NSURLComponents componentsWithString:login.address];
    if (components.scheme == nil) {
        components = [NSURLComponents componentsWithString:
                      [@"webdavs://" stringByAppendingString:login.address]];
    }
    if (login.username.length) {
        components.user = login.username;
    }
    if (login.password.length) {
        components.password = login.password;
    }
    if (login.port) {
        components.port = login.port;
    }

    return [self WebDAVNetworkServerBrowserWithURL:components.URL];
}

+ (instancetype)WebDAVNetworkServerBrowserWithURL:(NSURL *)url
{
    VLCMedia *media = [VLCMedia mediaWithURL:url];
    return [[self alloc] initWithMedia:media options:@{}];
}
@end
