/*****************************************************************************
 * VLCCarPlaySceneDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlaySceneDelegate.h"

#import <CarPlay/CarPlay.h>

#import "VLCCarPlayArtistsController.h"
#import "CPListTemplate+Genres.h"
#import "CPListTemplate+NetworkStreams.h"
#import "VLCCarPlayPlaylistsController.h"
#import "VLCNowPlayingTemplateObserver.h"

#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@interface VLCCarPlaySceneDelegate() <CPTemplateApplicationSceneDelegate, CPMediaLibraryObserverDelegate, CPListTemplateDelegate>
{
    CPInterfaceController *_interfaceController;
    CarPlayMediaLibraryObserver *_mediaLibraryObserver;
    VLCNowPlayingTemplateObserver *_nowPlayingTemplateObserver;
    VLCCarPlayArtistsController *_artistsController;
    VLCCarPlayPlaylistsController *_playlistsController;
    CPListTemplate *_playQueueTemplate;
    CPListSection *_section;
    VLCPlaybackService *_playbackService;
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

    _playbackService = [VLCPlaybackService sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayPlayQueueTemplate) name:VLCDisplayPlayQueueCarPlay object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetPlayQueueTemplate) name:VLCPlaybackServicePlaybackDidStop object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetPlayQueueTemplate) name:VLCPlaybackServiceShuffleModeUpdated object:nil];
}

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene
didDisconnectInterfaceController:(CPInterfaceController *)interfaceController
{
    _interfaceController = nil;
    [_mediaLibraryObserver unobserveLibrary];
    _mediaLibraryObserver = nil;
    [[CPNowPlayingTemplate sharedTemplate] removeObserver:_nowPlayingTemplateObserver];
    _nowPlayingTemplateObserver = nil;
    _playQueueTemplate = nil;
    _section = nil;
    _playbackService = nil;
}

- (CPTabBarTemplate *)generateRootTemplate
{
    if (!_artistsController) {
        _artistsController = [[VLCCarPlayArtistsController alloc] init];
        _artistsController.interfaceController = _interfaceController;
    }
    if (!_playlistsController) {
        _playlistsController = [[VLCCarPlayPlaylistsController alloc] init];
        _playlistsController.interfaceController = _interfaceController;
    }

    CPListTemplate *artists = [_artistsController artistList];
    CPListTemplate *genres = [CPListTemplate genreList];
    CPListTemplate *streams = [CPListTemplate streamList];
    CPListTemplate *playlists = [_playlistsController playlists];

    return [[CPTabBarTemplate alloc] initWithTemplates:@[artists, genres, streams, playlists]];
}

- (void)templatesNeedUpdate
{
    [_interfaceController setRootTemplate:[self generateRootTemplate] animated:YES];
}

- (CPListSection *)createListSection
{
    VLCMediaList *mediaList = _playbackService.isShuffleMode ? _playbackService.shuffledList : _playbackService.mediaList;
    NSInteger mediaListCount = mediaList.count;
    NSMutableArray<CPListItem *> *items = [NSMutableArray new];

    for (NSInteger index = 0; index < mediaListCount; index++) {
        VLCMLMedia *media = [VLCMLMedia mediaForPlayingMedia:[mediaList mediaAtIndex:index]];
        CPListItem *listItem = [[CPListItem alloc] initWithText:media.title detailText:media.artist.name];

        [items addObject:listItem];
    }

    return [[CPListSection alloc] initWithItems:items];
}

- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:(CPListItem *)item completionHandler:(void (^)(void))completionHandler
{
    VLCMediaList *mediaList = _playbackService.isShuffleMode ? _playbackService.shuffledList : _playbackService.mediaList;
    NSIndexPath *index = [listTemplate indexPathForItem:item];
    if (index.row >= mediaList.count) {
        return;
    }

    [_playbackService playItemAtIndex:index.row];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_interfaceController popTemplateAnimated:YES];
    });
}

- (void)displayPlayQueueTemplate
{
    if (!_playQueueTemplate) {
        _section = [self createListSection];
        _playQueueTemplate = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"QUEUE_LABEL", "") sections:@[_section]];
        _playQueueTemplate.delegate = self;
    }

    [_interfaceController pushTemplate:_playQueueTemplate animated:YES];
}

- (void)resetPlayQueueTemplate
{
    _playQueueTemplate = nil;
    _section = nil;
}

@end

#pragma clang diagnostic pop
