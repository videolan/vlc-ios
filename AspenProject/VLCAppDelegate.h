//
//  VLCAppDelegate.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VLCPlaylistViewController;
@class PAPasscodeViewController;
@interface VLCAppDelegate : UIResponder <UIApplicationDelegate>
{
    NSURL *_tempURL;
    PAPasscodeViewController *_passcodeLockController;
}

- (void)updateMediaList;

@property (nonatomic, readonly) VLCPlaylistViewController *playlistViewController;

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) UINavigationController *navigationController;

@property (nonatomic, retain) NSDate *nextPasscodeCheckDate;

@end
