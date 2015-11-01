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

#import "VLCPlaybackInfoAudioTVViewController.h"

@interface VLCPlaybackInfoAudioTVViewController ()

@end

@implementation VLCPlaybackInfoAudioTVViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"AUDIO_INFO_VC_TITLE", nil);
    }
    return self;
}
- (CGSize)preferredContentSize
{
    return CGSizeMake(CGRectGetWidth(self.view.bounds), 300);
}
@end
