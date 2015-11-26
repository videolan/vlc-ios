/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class VLCPlaybackController;
@protocol VLCPlaybackInfoPanelTVViewController <NSObject>

+ (BOOL)shouldBeVisibleForPlaybackController:(VLCPlaybackController *)vpc;

@end

@interface VLCPlaybackInfoPanelTVViewController : UIViewController <VLCPlaybackInfoPanelTVViewController>


// subclasses should override preferred content size to enable
// correct sizing of the info VC
- (CGSize)preferredContentSize;

@end
