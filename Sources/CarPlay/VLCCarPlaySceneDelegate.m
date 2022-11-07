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
#import "VLCNowPlayingTemplateObserver.h"

#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@interface VLCCarPlaySceneDelegate() <CPTemplateApplicationSceneDelegate, CPMediaLibraryObserverDelegate>
{
    CPInterfaceController *_interfaceController;
    CarPlayMediaLibraryObserver *_mediaLibraryObserver;
    VLCNowPlayingTemplateObserver *_nowPlayingTemplateObserver;
}

@end

@implementation VLCCarPlaySceneDelegate

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene
   didConnectInterfaceController:(CPInterfaceController *)interfaceController
{
    _interfaceController = interfaceController;
    _mediaLibraryObserver = [[CarPlayMediaLibraryObserver alloc] init];
    _mediaLibraryObserver.observerDelegate = self;
    [_mediaLibraryObserver observeLibrary];

    [_interfaceController setRootTemplate:[self generateRootTemplate] animated:YES];

    _nowPlayingTemplateObserver = [VLCNowPlayingTemplateObserver new];
    [[CPNowPlayingTemplate sharedTemplate] addObserver:_nowPlayingTemplateObserver];
    [_nowPlayingTemplateObserver configureNowPlayingTemplate];
}

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene
didDisconnectInterfaceController:(CPInterfaceController *)interfaceController
{
    _interfaceController = nil;
    [_mediaLibraryObserver unobserveLibrary];
    _mediaLibraryObserver = nil;
    [[CPNowPlayingTemplate sharedTemplate] removeObserver:_nowPlayingTemplateObserver];
    _nowPlayingTemplateObserver = nil;
}

- (CPTabBarTemplate *)generateRootTemplate
{
    CPListTemplate *artists = [CPListTemplate artistList];
    CPListTemplate *genres = [CPListTemplate genreList];
    CPListTemplate *streams = [CPListTemplate streamList];
    CPListTemplate *playlists = [CPListTemplate playlists];

    return [[CPTabBarTemplate alloc] initWithTemplates:@[artists, genres, streams, playlists]];
}

- (void)templatesNeedUpdate
{
    [_interfaceController setRootTemplate:[self generateRootTemplate] animated:YES];
}

@end

#pragma clang diagnostic pop
