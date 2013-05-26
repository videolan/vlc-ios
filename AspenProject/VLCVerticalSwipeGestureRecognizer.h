//
//  VLCVerticalSwipeGestureRecognizer.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 26.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VLCVerticalSwipeGestureRecognizer
@required
- (void)verticalSwipePercentage:(CGFloat)percentage inView:(UIView *)view half:(NSUInteger)half;
@end

@interface VLCVerticalSwipeGestureRecognizer : UISwipeGestureRecognizer
@property (nonatomic, retain) id delegate;

@end
