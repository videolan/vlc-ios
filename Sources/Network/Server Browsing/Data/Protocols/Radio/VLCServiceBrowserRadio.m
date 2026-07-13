/*****************************************************************************
 * VLCServiceBrowserRadio.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServiceBrowserRadio.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCFavoriteService.h"

static NSString *const VLCRadioServiceName = @"radio";

@implementation VLCServiceBrowserRadio

- (instancetype)init
{
    return [super initWithName:NSLocalizedString(@"RADIO", nil)
            serviceServiceName:VLCRadioServiceName];
}

- (id<VLCLocalNetworkService>)networkServiceForIndex:(NSUInteger)index
{
    VLCMedia *media = [self.mediaDiscoverer.discoveredMedia mediaAtIndex:index];
    if (media)
        return [[VLCServiceRadio alloc] initWithMediaItem:media serviceName:VLCRadioServiceName];
    return nil;
}

@end

@implementation VLCServiceRadio

- (id<VLCNetworkServerBrowser>)serverBrowser
{
    VLCMedia *media = self.mediaItem;
    if (media.mediaType != VLCMediaTypeDirectory)
        return nil;

    VLCNetworkServerBrowserVLCMedia *browser = [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:media options:@{}];
    browser.favoriteGroupName = VLCFavoriteGroupRadio;
    return browser;
}

@end
