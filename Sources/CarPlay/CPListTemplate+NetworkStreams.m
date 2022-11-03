/*****************************************************************************
 * CPListTemplate+NetworkStreams.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "CPListTemplate+NetworkStreams.h"
#import "VLCPlaybackService.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation CPListTemplate (NetworkStreams)

+ (CPListTemplate *)streamList
{
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self listOfNetworkStreams]];
    CPListTemplate *template = [[CPListTemplate alloc] initWithTitle:NSLocalizedString(@"NETWORK_TITLE", nil)
                                                            sections:@[listSection]];
    template.tabTitle = NSLocalizedString(@"NETWORK", nil);
    template.tabImage = [UIImage imageNamed:@"cp-Stream"];
    return template;
}

+ (NSArray *)listOfNetworkStreams
{
    NSArray *recentURLs;
    NSDictionary *recentURLTitles;

    if ([[NSFileManager defaultManager] ubiquityIdentityToken] != nil) {
        /* force store update */
        NSUbiquitousKeyValueStore *ubiquitousKeyValueStore = [NSUbiquitousKeyValueStore defaultStore];
        [ubiquitousKeyValueStore synchronize];

        /* fetch data from cloud */
        recentURLs = [ubiquitousKeyValueStore arrayForKey:kVLCRecentURLs];
        recentURLTitles = [ubiquitousKeyValueStore dictionaryForKey:kVLCRecentURLTitles];
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        recentURLs = [defaults objectForKey:kVLCRecentURLs];
        recentURLTitles = [defaults objectForKey:kVLCRecentURLTitles];
    }

    NSUInteger count = recentURLs.count;
    NSMutableArray *itemList = [[NSMutableArray alloc] initWithCapacity:count];

    for (NSUInteger x = 0; x < count; x++) {
        CPListItem *listItem;

        NSString *recentURLString = recentURLs[x];
        NSString *content = [recentURLString stringByRemovingPercentEncoding];
        NSString *possibleTitle = recentURLTitles[[@(x) stringValue]];

        listItem = [[CPListItem alloc] initWithText:possibleTitle ?: [content lastPathComponent]
                                         detailText:content
                                              image:[UIImage imageNamed:@"cp-Stream"]];
        listItem.userInfo = [NSURL URLWithString:recentURLString];
        listItem.handler = ^(id <CPSelectableListItem> item,
                             dispatch_block_t completionBlock) {
            NSURL *playbackURL = item.userInfo;

            VLCMedia *media = [VLCMedia mediaWithURL:playbackURL];
            VLCMediaList *medialist = [[VLCMediaList alloc] init];
            [medialist addMedia:media];

            [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
            completionBlock();
        };
        [itemList addObject:listItem];
    }

    return itemList;
}

@end

#pragma clang diagnostic pop
