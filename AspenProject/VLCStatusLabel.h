//
//  VLCStatusLabel.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 17.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VLCStatusLabel : UILabel
{
    NSTimer *_displayTimer;
}

- (void)showStatusMessage:(NSString *)message;

@end
