/*****************************************************************************
 * VLCBaseInterfaceController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <WatchKit/WatchKit.h>

@interface VLCBaseInterfaceController : WKInterfaceController
@property (nonatomic, assign, readonly, getter=isActivated) BOOL activated;

- (void)addNowPlayingMenu;
- (void)showNowPlaying:(id)sender;

@end
