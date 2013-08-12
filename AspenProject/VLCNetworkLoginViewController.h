//
//  VLCNetworkLoginViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 11.08.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <UIKit/UIKit.h>

@protocol VLCNetworkLoginViewController <NSObject>
@required
- (void)loginToURL:(NSURL *)url confirmedWithUsername:(NSString *)username andPassword:(NSString *)password;
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

@property (nonatomic, retain) id delegate;

- (IBAction)dismiss:(id)sender;
- (IBAction)dismissWithAnimation:(id)sender;
- (IBAction)connectToServer:(id)sender;

@end
