/*****************************************************************************
 * VLCCarPlayOnAirController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCarPlayOnAirController.h"
#import "CPListTemplate+NetworkStreams.h"
#import "VLC-Swift.h"

@implementation VLCCarPlayOnAirController
{
    CPListTemplate *_radioListTemplate;
    CarPlayPodcastsController *_podcastsController;
}

- (CPGridTemplate *)onAirTemplate
{
    _podcastsController = [[CarPlayPodcastsController alloc] init];
    _podcastsController.interfaceController = self.interfaceController;

    NSString *radioSymbol = @"antenna.radiowaves.left.and.right";
    if (@available(iOS 16.0, *)) {
        radioSymbol = @"radio";
    }

    NSArray<CPGridButton *> *buttons = @[
        [self buttonWithTitle:NSLocalizedString(@"RADIO", nil)
                       symbol:radioSymbol
                     template:^{
            self->_radioListTemplate = [CPListTemplate streamList];
            return self->_radioListTemplate;
        }],
        [self buttonWithTitle:NSLocalizedString(@"ONAIR_PODCASTS", nil)
                       symbol:@"mic"
                     template:^{ return [self->_podcastsController podcastList]; }],
    ];

    CPGridTemplate *template = [[CPGridTemplate alloc] initWithTitle:NSLocalizedString(@"ONAIR", nil)
                                                         gridButtons:buttons];
    template.tabTitle = NSLocalizedString(@"ONAIR", nil);
    template.tabImage = [UIImage systemImageNamed:@"dot.radiowaves.right"];
    return template;
}

- (void)radioListNeedsUpdate
{
    [_radioListTemplate updateSections:[CPListTemplate streamSections]];
}

- (void)podcastsNeedUpdate
{
    [_podcastsController podcastsNeedUpdate];
}

@end
