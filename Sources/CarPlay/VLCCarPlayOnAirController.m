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

@implementation VLCCarPlayOnAirController
{
    CPListTemplate *_radioListTemplate;
}

- (CPGridTemplate *)onAirTemplate
{
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

@end
