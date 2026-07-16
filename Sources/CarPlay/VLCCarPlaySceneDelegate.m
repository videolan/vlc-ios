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

#import "VLCCarPlayLibraryController.h"
#import "CPListTemplate+NetworkStreams.h"
#import "VLCCarPlayPlaylistsController.h"
#import "VLCCarPlayListLimit.h"
#import "VLCNowPlayingTemplateObserver.h"
#import "VLCFavoriteService.h"

#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@interface VLCCarPlaySceneDelegate() <CPTemplateApplicationSceneDelegate, CPMediaLibraryObserverDelegate, CPListTemplateDelegate>
{
    CPInterfaceController *_interfaceController;
    CarPlayMediaLibraryObserver *_mediaLibraryObserver;
    VLCNowPlayingTemplateObserver *_nowPlayingTemplateObserver;
    VLCCarPlayLibraryController *_libraryController;
    VLCCarPlayPlaylistsController *_playlistsController;
    CPListTemplate *_playQueueTemplate;
    CPListSection *_section;
    VLCPlaybackService *_playbackService;
    BOOL _templateUpdateScheduled;
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
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(displayPlayQueueTemplate) name:VLCDisplayPlayQueueCarPlay object:nil];
    [notificationCenter addObserver:self selector:@selector(resetPlayQueueTemplate) name:VLCPlaybackServicePlaybackDidStop object:nil];
    [notificationCenter addObserver:self selector:@selector(resetPlayQueueTemplate) name:VLCPlaybackServiceShuffleModeUpdated object:nil];
    [notificationCenter addObserver:self selector:@selector(templatesNeedUpdate) name:VLCFavoriteServiceContentDidChange object:nil];
}

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene
didDisconnectInterfaceController:(CPInterfaceController *)interfaceController
{
    _interfaceController = nil;
    [_mediaLibraryObserver unobserveLibrary];
    _mediaLibraryObserver = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[CPNowPlayingTemplate sharedTemplate] removeObserver:_nowPlayingTemplateObserver];
    _nowPlayingTemplateObserver = nil;
    _playQueueTemplate = nil;
    _section = nil;
    _playbackService = nil;
    _templateUpdateScheduled = NO;
}

- (CPTabBarTemplate *)generateRootTemplate
{
    if (!_libraryController) {
        _libraryController = [[VLCCarPlayLibraryController alloc] init];
        _libraryController.interfaceController = _interfaceController;
    }
    if (!_playlistsController) {
        _playlistsController = [[VLCCarPlayPlaylistsController alloc] init];
        _playlistsController.interfaceController = _interfaceController;
    }

    CPGridTemplate *library = [_libraryController libraryTemplate];
    CPListTemplate *playlists = [_playlistsController playlists];
    CPListTemplate *streams = [CPListTemplate streamList];

    return [[CPTabBarTemplate alloc] initWithTemplates:@[library, playlists, streams]];
}

- (void)templatesNeedUpdate
{
    if (!_interfaceController || _templateUpdateScheduled) {
        return;
    }

    _templateUpdateScheduled = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->_templateUpdateScheduled = NO;

        if (!self->_interfaceController) {
            return;
        }

        [self->_interfaceController setRootTemplate:[self generateRootTemplate] animated:NO];
    });
}

- (CPListSection *)createListSection
{
    VLCMediaList *mediaList = _playbackService.isShuffleMode ? _playbackService.shuffledList : _playbackService.mediaList;
    NSUInteger maximumItemCount = VLCCarPlayMaximumItemCountLimit();
    NSUInteger itemCount = MIN((NSUInteger)mediaList.count, maximumItemCount);
    NSMutableArray<CPListItem *> *items = [NSMutableArray arrayWithCapacity:itemCount];

    for (NSUInteger index = 0; index < itemCount; index++) {
        VLCMLMedia *media = [VLCMLMedia mediaForPlayingMedia:[mediaList mediaAtIndex:index]];
        CPListItem *listItem = [[CPListItem alloc] initWithText:media.title detailText:media.artist.name];

        [items addObject:listItem];
    }

    return [[CPListSection alloc] initWithItems:items];
}

- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:(CPListItem *)item completionHandler:(void (^)(void))completionHandler
{
    VLCMediaList *mediaList = _playbackService.isShuffleMode ? _playbackService.shuffledList : _playbackService.mediaList;
    NSUInteger selectedIndex = NSNotFound;
    if (@available(iOS 14.0, *)) {
        NSIndexPath *indexPath = [listTemplate indexPathForItem:item];
        if (indexPath) {
            selectedIndex = (NSUInteger)indexPath.row;
        }
    } else {
        selectedIndex = [_section indexOfItem:item];
    }

    if (selectedIndex == NSNotFound || selectedIndex >= (NSUInteger)mediaList.count) {
        completionHandler();
        return;
    }

    [_playbackService playItemAtIndex:selectedIndex];
    completionHandler();

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
