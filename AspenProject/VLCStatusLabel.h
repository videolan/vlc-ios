//
//  VLCStatusLabel.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 17.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <UIKit/UIKit.h>

@interface VLCStatusLabel : UILabel
{
    NSTimer *_displayTimer;
}

- (void)showStatusMessage:(NSString *)message;

@end
