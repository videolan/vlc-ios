/*****************************************************************************
 * VLCOpenInActivity.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Marc Etcheverry <marc # taplightsoftware com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

/// A UIActivity that handles multiple files and presents them in a UIDocumentInteractionController
/// This class is inspired by https://github.com/honkmaster/TTOpenInAppActivity
@interface VLCOpenInActivity : UIActivity

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, weak) UIBarButtonItem *presentingBarButtonItem;

@end
