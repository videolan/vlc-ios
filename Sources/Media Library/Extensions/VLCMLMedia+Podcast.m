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
long const PODCAST_ABSOLUTE = 3600000L;

@implementation VLCMLMedia(PodcastExtension)

- (BOOL)isPodcast
{
    NSString *genre = self.genre.name;
    return self.type == VLCMLMediaTypeAudio && (self.duration > PODCAST_ABSOLUTE
                                                || (self.album == nil && self.duration > PODCAST_THRESHOLD)
                                                || [genre caseInsensitiveCompare:@"podcast"]
                                                || [genre caseInsensitiveCompare:@"audiobooks"]
                                                || [genre caseInsensitiveCompare:@"audiobook"]
                                                || [genre caseInsensitiveCompare:@"speech"]
                                                || [genre caseInsensitiveCompare:@"vocal"]);
}

@end
