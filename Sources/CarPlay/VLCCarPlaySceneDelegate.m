/*****************************************************************************
 * VLCCarPlaySceneDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022-2023, 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlaySceneDelegate.h"

#import <CarPlay/CarPlay.h>

#import "VLCCarPlayLibraryController.h"
#import "CPInterfaceController+VLCTemplateStack.h"
#import "CPListTemplate+NetworkStreams.h"
#import "VLCCarPlayPlaylistsController.h"
#import "VLCCarPlayBrowserController.h"
#import "VLCNowPlayingTemplateObserver.h"
#import "VLCFavoriteService.h"
#import "VLCRadioService.h"

#import "VLC-Swift.h"

@interface VLCCarPlaySceneDelegate() <CPTemplateApplicationSceneDelegate, CPMediaLibraryObserverDelegate, CPListTemplateDelegate>
{
    CPInterfaceController *_interfaceController;
    CarPlayMediaLibraryObserver *_mediaLibraryObserver;
    VLCNowPlayingTemplateObserver *_nowPlayingTemplateObserver;
    VLCCarPlayLibraryController *_libraryController;
    VLCCarPlayPlaylistsController *_playlistsController;
    CPListTemplate *_streamListTemplate;
    CPListTemplate *_playQueueTemplate;
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

    [_interfaceController setRootTemplate:[self generateRootTemplate] animated:YES completion:nil];

    _nowPlayingTemplateObserver = [VLCNowPlayingTemplateObserver new];
    [[CPNowPlayingTemplate sharedTemplate] addObserver:_nowPlayingTemplateObserver];
    [_nowPlayingTemplateObserver configureNowPlayingTemplate];

    _playbackService = [VLCPlaybackService sharedInstance];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(displayPlayQueueTemplate) name:VLCDisplayPlayQueueCarPlay object:nil];
    [notificationCenter addObserver:self selector:@selector(resetPlayQueueTemplate) name:VLCPlaybackServicePlaybackDidStop object:nil];
    [notificationCenter addObserver:self selector:@selector(resetPlayQueueTemplate) name:VLCPlaybackServiceShuffleModeUpdated object:nil];
    [notificationCenter addObserver:self selector:@selector(streamListNeedsUpdate) name:VLCFavoriteServiceContentDidChange object:nil];
    [notificationCenter addObserver:self selector:@selector(streamListNeedsUpdate) name:VLCRadioRecentStreamsDidChangeNotification object:nil];
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
    _libraryController = nil;
    _playlistsController = nil;
    _streamListTemplate = nil;
    _playQueueTemplate = nil;
    _playbackService = nil;
    _templateUpdateScheduled = NO;
}

- (CPTabBarTemplate *)generateRootTemplate
{
    _libraryController = [[VLCCarPlayLibraryController alloc] init];
    _libraryController.interfaceController = _interfaceController;
    _playlistsController = [[VLCCarPlayPlaylistsController alloc] init];
    _playlistsController.interfaceController = _interfaceController;

    CPGridTemplate *library = [_libraryController libraryTemplate];
    CPListTemplate *playlists = [_playlistsController playlists];
    _streamListTemplate = [CPListTemplate streamList];

    return [[CPTabBarTemplate alloc] initWithTemplates:@[library, playlists, _streamListTemplate]];
}

- (void)streamListNeedsUpdate
{
    if (_streamListTemplate) {
        [_streamListTemplate updateSections:[CPListTemplate streamSections]];
        return;
    }

    [self templatesNeedUpdate];
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

        [self->_interfaceController setRootTemplate:[self generateRootTemplate] animated:NO completion:nil];
    });
}

- (CPListSection *)createListSection
{
    VLCMediaList *mediaList = _playbackService.isShuffleMode ? _playbackService.shuffledList : _playbackService.mediaList;
    NSUInteger itemCount = MIN((NSUInteger)mediaList.count, [VLCCarPlayBrowserController maximumItemCount]);
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
    NSIndexPath *indexPath = [listTemplate indexPathForItem:item];
    if (indexPath) {
        selectedIndex = (NSUInteger)indexPath.row;
    }

    if (selectedIndex == NSNotFound || selectedIndex >= (NSUInteger)mediaList.count) {
        completionHandler();
        return;
    }

    [_playbackService playItemAtIndex:selectedIndex];
    completionHandler();

    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_interfaceController popTemplateAnimated:YES completion:nil];
    });
}

- (void)displayPlayQueueTemplate
{
    if (!_playQueueTemplate) {
        CPListSection *section = [self createListSection];
        _playQueueTemplate = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"QUEUE_LABEL", "") sections:@[section]];
        _playQueueTemplate.delegate = self;
    }

    [_interfaceController pushTemplateWithinDepthLimit:_playQueueTemplate animated:YES];
}

- (void)resetPlayQueueTemplate
{
    _playQueueTemplate = nil;
}

@end
