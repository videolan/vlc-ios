//
//  VLCAboutViewController.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 07.04.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLCAboutViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITextView *textContents;
@property (nonatomic, strong) IBOutlet UILabel *aspenVersion;
@property (nonatomic, strong) IBOutlet UILabel *vlckitVersion;

@end
