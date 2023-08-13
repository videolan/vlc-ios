/*****************************************************************************
 * VLCMLMedia+Podcast.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMLMedia+Podcast.h"

long const PODCAST_THRESHOLD = 900000L;
long const PODCAST_ABSOLUTE = 1800000L;

@implementation VLCMLMedia(PodcastExtension)

- (BOOL)isPodcast
{
    NSString *genre = self.genre.name;
    SInt64 duration = self.duration;

    return self.type == VLCMLMediaTypeAudio && (duration > PODCAST_ABSOLUTE
                                                || (self.album == nil && duration > PODCAST_THRESHOLD)
                                                || [genre caseInsensitiveCompare:@"podcast"] == NSOrderedSame
                                                || [genre caseInsensitiveCompare:@"audiobooks"] == NSOrderedSame
                                                || [genre caseInsensitiveCompare:@"audiobook"] == NSOrderedSame
                                                || [genre caseInsensitiveCompare:@"speech"] == NSOrderedSame
                                                || [genre caseInsensitiveCompare:@"vocal"] == NSOrderedSame);
}

@end
