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

#define CONTENT_INSET 20.
#define MINIMAL_CONTENT_SIZE 420.

@class VLCPlaybackService;
@protocol VLCPlaybackInfoPanelTVViewController <NSObject>

+ (BOOL)shouldBeVisibleForPlaybackController:(VLCPlaybackService *)vpc;

@end

@interface VLCPlaybackInfoPanelTVViewController : UIViewController <VLCPlaybackInfoPanelTVViewController>


// subclasses should override preferred content size to enable
// correct sizing of the info VC
- (CGSize)preferredContentSize;

@end
