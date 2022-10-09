/*****************************************************************************
 * VLCCarPlaySceneDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlaySceneDelegate.h"

#import <CarPlay/CarPlay.h>

#import "CPListTemplate+Artists.h"
#import "CPListTemplate+Genres.h"
#import "CPListTemplate+NetworkStreams.h"
#import "CPListTemplate+Playlists.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@interface VLCCarPlaySceneDelegate() <CPTemplateApplicationSceneDelegate>
{
    CPInterfaceController *_interfaceController;
}

@end

@implementation VLCCarPlaySceneDelegate

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene
   didConnectInterfaceController:(CPInterfaceController *)interfaceController
{
    _interfaceController = interfaceController;

    CPListTemplate *artists = [CPListTemplate artistList];
    CPListTemplate *genres = [CPListTemplate genreList];
    CPListTemplate *streams = [CPListTemplate streamList];
    CPListTemplate *playlists = [CPListTemplate playlists];

    CPTabBarTemplate *rootTemplate = [[CPTabBarTemplate alloc] initWithTemplates:@[artists, genres, streams, playlists]];
    [_interfaceController setRootTemplate:rootTemplate animated:YES];

    APLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene
didDisconnectInterfaceController:(CPInterfaceController *)interfaceController
{
    APLog(@"%s", __PRETTY_FUNCTION__);
}

@end

#pragma clang diagnostic pop
