//
//  VLCOpenInActivity.h
//  VLC for iOS
//
//  Created by Marc Etcheverry on 6/26/14.
//  Copyright (c) 2014 VideoLAN. All rights reserved.
//

/// A UIActivity that handles multiple files and presents them in a UIDocumentInteractionController
/// This class is inspired by https://github.com/honkmaster/TTOpenInAppActivity
@interface VLCOpenInActivity : UIActivity

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, weak) UIBarButtonItem *presentingBarButtonItem;

@end
