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

@implementation VLCPlaybackService (MediaLibrary)

- (void)playMediaAtIndex:(NSInteger)index fromCollection:(NSArray<VLCMLMedia *> *)collection
{
    [self configureMediaListWithMLMedia:collection indexToPlay:(int) index];
}

- (void)playMedia:(VLCMLMedia *)media
{
    [self configureMediaListWithMLMedia:@[media] indexToPlay:0];
}

- (void)configureMediaListWithMLMedia:(NSArray<VLCMLMedia *> *)mlMedia indexToPlay:(int)index {
    NSAssert(index >= 0, @"The index should never be negative");
    VLCMediaList *list = [[VLCMediaList alloc] init];
    VLCMedia *media;
    for (VLCMLMedia *file in mlMedia) {
        media = [VLCMedia mediaWithURL: file.mainFile.mrl];
        [media addOptions:self.mediaOptionsDictionary];
        [list addMedia:media];
    }
    [self configureMediaList:list atIndex:index];
}

- (void)configureMediaList:(VLCMediaList *)list atIndex:(int)index
{
    [self playMediaList:list firstIndex:index subtitlesFilePath:nil];
}

@end
