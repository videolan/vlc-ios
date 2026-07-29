/*****************************************************************************
 * VLCNetworkServerBrowserFactory.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowserFactory.h"

#import "VLCNetworkServerLoginInformation.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCNetworkServerBrowserVLCMedia+FTP.h"
#import "VLCNetworkServerBrowserVLCMedia+SFTP.h"
#import "VLCNetworkServerBrowserVLCMedia+WebDAV.h"
#import "VLCNetworkServerBrowserPlex.h"
#import "VLCLocalNetworkServiceBrowserUPnP.h"
#import "VLCLocalNetworkServiceBrowserPlex.h"
#import "VLCLocalNetworkServiceBrowserDSM.h"
#import "VLCLocalNetworkServiceBrowserNFS.h"

@implementation VLCNetworkServerBrowserFactory

+ (id<VLCNetworkServerBrowser>)browserForLogin:(VLCNetworkServerLoginInformation *)login
{
    NSString *identifier = login.protocolIdentifier;

    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierUPnP]) {
        if (login.rootMedia != nil) {
            return [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:login.rootMedia options:login.options];
        }
        return [VLCNetworkServerBrowserVLCMedia UPnPNetworkServerBrowserWithLogin:login];
    }
    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierFTP]) {
        return [VLCNetworkServerBrowserVLCMedia FTPNetworkServerBrowserWithLogin:login];
    }
    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierPlex]) {
        return [[VLCNetworkServerBrowserPlex alloc] initWithLogin:login];
    }
    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierSMB]) {
        return [VLCNetworkServerBrowserVLCMedia SMBNetworkServerBrowserWithLogin:login];
    }
    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierNFS]) {
        return [VLCNetworkServerBrowserVLCMedia NFSNetworkServerBrowserWithLogin:login];
    }
    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierSFTP]) {
        return [VLCNetworkServerBrowserVLCMedia SFTPNetworkServerBrowserWithLogin:login];
    }
    if ([identifier isEqualToString:VLCNetworkServerProtocolIdentifierWebDAV]) {
        return [VLCNetworkServerBrowserVLCMedia WebDAVNetworkServerBrowserWithLogin:login];
    }

    APLog(@"Unsupported URL Scheme requested %@", identifier);
    return nil;
}

@end
