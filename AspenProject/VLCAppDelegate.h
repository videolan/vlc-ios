//
//  VLCAppDelegate.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VLCPlaylistViewController.h"

@interface VLCAppDelegate : UIResponder <UIApplicationDelegate>
{
    VLCPlaylistViewController *_playlistViewController;
}

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) UINavigationController *navigationController;

@end
