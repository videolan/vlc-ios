/*****************************************************************************
 * VLCBaseInterfaceController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCBaseInterfaceController.h"

NSString *const VLCDBUpdateNotification = @"VLCUpdateDatabase";

@interface VLCBaseInterfaceController()
@property (nonatomic) BOOL needsUpdate;

@end

@implementation VLCBaseInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNeedsUpdateData) name:VLCDBUpdateNotification object:nil];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VLCDBUpdateNotification object:nil];
}


- (void)addNowPlayingMenu {
    [self addMenuItemWithItemIcon:WKMenuItemIconMore title: NSLocalizedString(@"NOW_PLAYING", nil) action:@selector(showNowPlaying:)];
}

- (void)showNowPlaying:(id)sender {
    [self presentControllerWithName:@"nowPlaying" context:nil];
}


- (void)willActivate {
    [super willActivate];
    _activated = YES;

    [self updateDataIfNeeded];
}
- (void)didDeactivate {
    [super didDeactivate];
    _activated = NO;
}

- (void)setNeedsUpdateData
{
    self.needsUpdate = YES;
    [self updateDataIfNeeded];
}
- (void)updateDataIfNeeded
{
    // if not activated/visible we defer the update til activation
    if (self.needsUpdate && self.activated) {
        [self updateData];
        self.needsUpdate = NO;
    }
}

- (void)updateData
{
    self.needsUpdate = NO;
}

@end
