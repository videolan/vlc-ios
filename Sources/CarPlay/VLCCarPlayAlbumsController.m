/*****************************************************************************
 * VLCCarPlayAlbumsController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlayAlbumsController.h"
#import "VLC-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation VLCCarPlayAlbumsController

- (CPListTemplate *)albumList
{
    NSArray *albums = [[VLCAppCoordinator sharedInstance].mediaLibraryService albumsWithSortingCriteria:VLCMLSortingCriteriaAlpha
                                                                                                   desc:NO];
    CPListSection *listSection = [[CPListSection alloc] initWithItems:[self albumItems:albums]];
    return [self tabTemplateWithTitle:NSLocalizedString(@"ALBUMS", nil)
                               symbol:@"square.stack"
                             sections:@[listSection]];
}

@end

#pragma clang diagnostic pop
