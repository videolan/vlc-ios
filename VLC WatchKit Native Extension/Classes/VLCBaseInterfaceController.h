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

extern NSString *const VLCDBUpdateNotification;

@interface VLCBaseInterfaceController : WKInterfaceController
@property (nonatomic, assign, readonly, getter=isActivated) BOOL activated;

- (void)addNowPlayingMenu;
- (void)showNowPlaying:(id)sender;


// calls updataData if interface is currenlty active
// otherwise it sets a flag so update data when the interface is activated
- (void)setNeedsUpdateData;

// actual update logic should be overwritten by subclasses that needs an update logic
- (void)updateData;

@end
