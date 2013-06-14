//
//  VLCHorizontalSwipeGestureRecognizer.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 26.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <UIKit/UIKit.h>

@protocol VLCHorizontalSwipeGestureRecognizer
@required
- (void)horizontalSwipePercentage:(CGFloat)percentage inView:(UIView *)view;

@end

@interface VLCHorizontalSwipeGestureRecognizer : UISwipeGestureRecognizer
@property (nonatomic, retain) id delegate;

@end
