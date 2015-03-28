/*****************************************************************************
 * VLCPlexConnectServerViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCPlexConnectServerViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UITextField *serverAddressField;
@property (nonatomic, strong) IBOutlet UIButton *connectButton;
@property (nonatomic, strong) IBOutlet UITextField *portField;
@property (nonatomic, strong) IBOutlet UILabel *serverAddressLabel;
@property (nonatomic, strong) IBOutlet UILabel *portLabel;
@property (nonatomic, strong) IBOutlet UILabel *serverAddressHelpLabel;
@property (nonatomic, strong) IBOutlet UITableView *serverPlexBookmark;
@property (nonatomic, strong) IBOutlet UIButton *bookmarkButton;
@property (strong, nonatomic) IBOutlet UILabel *bookmarkLabel;

- (IBAction)connectToServer:(id)sender;
- (IBAction)savePlexServer:(id)sender;

@end