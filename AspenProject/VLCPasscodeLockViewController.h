//
//  VLCPasscodeLockViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 18.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLCPasscodeLockViewController : UIViewController
{
    NSString *_passcode;
}

@property (nonatomic, strong) IBOutlet UILabel *enterPasscodeLabel;
@property (nonatomic, strong) IBOutlet UITextField *enterCodeField;

- (IBAction)textFieldValueChanged:(id)sender;

@end
