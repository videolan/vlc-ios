//
//  VLCAboutViewController.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 07.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLCAboutViewController : UIViewController
{
    UITextView *_textContents;
    UILabel *_aspenVersion;
    UILabel *_vlckitVersion;
    UIBarButtonItem *_dismissButton;
}
@property (nonatomic, retain) IBOutlet UITextView *textContents;
@property (nonatomic, retain) IBOutlet UILabel *aspenVersion;
@property (nonatomic, retain) IBOutlet UILabel *vlckitVersion;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *dismissButton;
- (IBAction)dismiss:(id)sender;

@end
