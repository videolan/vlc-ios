/*****************************************************************************
 * VLCPlaybackService+MediaLibrary.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz     <caro #videolan.org>
 *          Tobias Conradi  <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackService+MediaLibrary.h"
#import <VLCMediaLibraryKit/VLCMLFile.h>
#import <VLCMediaLibraryKit/VLCMLMedia.h>
#import "VLC-Swift.h"

@interface VLCPlaybackService ()
{
    BOOL _openInMiniPlayer;
}
@end

@implementation VLCPlaybackService (MediaLibrary)

- (void)playMediaAtIndex:(NSInteger)index fromCollection:(NSArray<VLCMLMedia *> *)collection
{
    VLCMediaList *list = [self configureMediaListWithMLMedia:collection indexToPlay:(int) index];
    [self playMediaList:list firstIndex:index subtitlesFilePath:nil];
}

- (void)playMedia:(VLCMLMedia *)media
{
    VLCMediaList *list = [self configureMediaListWithMLMedia:@[media] indexToPlay:0];
    [self playMediaList:list firstIndex:0 subtitlesFilePath:nil];
}

- (void)playMedia:(VLCMLMedia *)media openInMiniPlayer:(BOOL)openInMiniPlayer
{
    _openInMiniPlayer = openInMiniPlayer;
    [self playMedia:media];
}

- (void)playMedia:(VLCMLMedia *)media withMode:(EditButtonType)mode
{
    VLCMediaList *list = self.isShuffleMode ? self.shuffledList : self.mediaList;
    
    if ([list count] > 0) {
        VLCMedia *vlcmedia = [VLCMedia mediaWithURL:media.mainFile.mrl];

        [vlcmedia addOptions:self.mediaOptionsDictionary];
        switch (mode) {
            case EditButtonTypePlayNextInQueue:
                [self.mediaList insertMedia:vlcmedia atIndex:[self.mediaList indexOfMedia:self.currentlyPlayingMedia] + 1];
                [self.shuffledList insertMedia:vlcmedia atIndex:[self.shuffledList indexOfMedia:self.currentlyPlayingMedia] + 1];
                break;
            case EditButtonTypeAppendToQueue:
                [self.mediaList addMedia:vlcmedia];
                [self.shuffledList addMedia:vlcmedia];
                break;
            default:
                break;
        }
    } else {
        [self playMedia:media];
    }
}

- (void)playMediaNextInQueue:(VLCMLMedia *)media
{
    [self playMedia:media withMode:EditButtonTypePlayNextInQueue];
    [VLCPlaybackService.sharedInstance.playerDisplayController hintPlayqueueWithDelay:0.5];
}

- (void)appendMediaToQueue:(VLCMLMedia *)media
{
    [self playMedia:media withMode:EditButtonTypeAppendToQueue];
    [VLCPlaybackService.sharedInstance.playerDisplayController hintPlayqueueWithDelay:0.5];
}

- (void)playCollection:(NSArray<VLCMLMedia *> *)collection
{
    [self playMediaAtIndex:-1 fromCollection:collection];
}

- (void)playCollection:(NSArray<VLCMLMedia *> *)collection withMode:(EditButtonType)mode
{
    if ([self.mediaList count] > 0) {
        switch (mode) {
            case EditButtonTypePlayNextInQueue:
                for (VLCMLMedia *media in [collection reverseObjectEnumerator]) {
                    [self playMedia:media withMode:EditButtonTypePlayNextInQueue];
                }
                break;
            case EditButtonTypeAppendToQueue:
                for (VLCMLMedia *media in collection) {
                    [self playMedia:media withMode:EditButtonTypeAppendToQueue];
                }
                break;
            default:
                break;
        }
    } else {
        [self playCollection:collection];
    }
}

- (void)playCollectionNextInQueue:(NSArray<VLCMLMedia *> *)collection
{
    [self playCollection:collection withMode:EditButtonTypePlayNextInQueue];
    [VLCPlaybackService.sharedInstance.playerDisplayController hintPlayqueueWithDelay:0.5];
}

- (void)appendCollectionToQueue:(NSArray<VLCMLMedia *> *)collection
{
    [self playCollection:collection withMode:EditButtonTypeAppendToQueue];
    [VLCPlaybackService.sharedInstance.playerDisplayController hintPlayqueueWithDelay:0.5];
}

- (VLCMediaList *)configureMediaListWithMLMedia:(NSArray<VLCMLMedia *> *)mlMedia indexToPlay:(int)index {
    VLCMediaList *list = [[VLCMediaList alloc] init];

    VLCMedia *media;
    for (VLCMLMedia *file in mlMedia) {
        media = [VLCMedia mediaWithURL: file.mainFile.mrl];
        [media addOptions:self.mediaOptionsDictionary];
        [list addMedia:media];
    }

    return list;
}

@end
