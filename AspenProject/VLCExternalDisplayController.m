//
//  VLCExternalDisplayController.m
//  AspenProject
//
//  Created by Gleb on 4/6/13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCExternalDisplayController.h"

@interface VLCExternalDisplayController ()

@end

@implementation VLCExternalDisplayController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return NO;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return ~UIInterfaceOrientationMaskAll;
}

@end
