//
//  VLCMenuButton.m
//  VLC for iOS
//
//  Created by Gleb on 6/17/13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCMenuButton.h"

@implementation VLCMenuButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIImage *background = [[UIImage imageNamed:@"menuButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
        [self setBackgroundImage:background forState:UIControlStateNormal];
    }
    
    return self;
}

@end
