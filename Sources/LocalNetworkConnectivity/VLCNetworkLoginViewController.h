/*****************************************************************************
 * VLCNetworkLoginViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VLCServerProtocol) {
    VLCServerProtocolSMB,
    VLCServerProtocolFTP,
    VLCServerProtocolPLEX,
    VLCServerProtocolUndefined,
};

@protocol VLCNetworkLoginViewControllerDelegate <NSObject>
@required
- (void)loginToServer:(NSString *)server
                 port:(NSString *)port
             protocol:(VLCServerProtocol)protocol
confirmedWithUsername:(NSString *)username
          andPassword:(NSString *)password;
@end

@interface VLCNetworkLoginViewController : UIViewController

@property (nonatomic, strong) IBOutlet UISegmentedControl *protocolSegmentedControl;
@property (nonatomic, strong) IBOutlet UITextField *serverField;
@property (nonatomic, strong) IBOutlet UILabel *serverLabel;
@property (nonatomic, strong) IBOutlet UITextField *portField;
@property (nonatomic, strong) IBOutlet UILabel *portLabel;
@property (nonatomic, strong) IBOutlet UIButton *connectButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic, strong) IBOutlet UILabel *loginHelpLabel;
@property (nonatomic, strong) IBOutlet UITableView *storedServersTableView;
@property (nonatomic, strong) IBOutlet UIButton *saveButton;

@property (nonatomic, readwrite) NSInteger serverProtocol;
@property (nonatomic, retain) NSString *hostname;
@property (nonatomic, retain) NSString *port;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

@property (nonatomic, retain) id delegate;

- (IBAction)connectToServer:(id)sender;
- (IBAction)saveServer:(id)sender;
- (IBAction)protocolSelectionChanged:(id)sender;

@end
