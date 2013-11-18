/*****************************************************************************
 * VLCAboutViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCAboutViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) IBOutlet UIWebView *webView;

@end
