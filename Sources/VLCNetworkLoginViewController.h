/*****************************************************************************
 * VLCNetworkLoginViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@protocol VLCNetworkLoginViewController <NSObject>
@required
- (void)loginToURL:(NSURL *)url confirmedWithUsername:(NSString *)username andPassword:(NSString *)thePassword;
@end

@interface VLCNetworkLoginViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITextField *serverAddressField;
@property (nonatomic, strong) IBOutlet UIButton *connectButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UILabel *usernameLabel;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic, strong) IBOutlet UILabel *passwordLabel;
@property (nonatomic, strong) IBOutlet UILabel *serverAddressHelpLabel;
@property (nonatomic, strong) IBOutlet UILabel *loginHelpLabel;
@property (weak, nonatomic) IBOutlet UITableView *historyLogin;
@property (nonatomic, retain) NSString *hostname;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

@property (nonatomic, retain) id delegate;

- (IBAction)dismiss:(id)sender;
- (IBAction)dismissWithAnimation:(id)sender;
- (IBAction)connectToServer:(id)sender;
- (IBAction)saveFTP:(id)sender;


@end
