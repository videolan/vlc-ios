//
//  VLCAppDelegate.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCDropboxTableViewController.h"

@class VLCPlaylistViewController;
@class PAPasscodeViewController;
@interface VLCAppDelegate : UIResponder <UIApplicationDelegate>

- (void)updateMediaList;

@property (nonatomic, readonly) VLCPlaylistViewController *playlistViewController;
@property (nonatomic, readonly) VLCDropboxTableViewController *dropboxTableViewController;

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) UINavigationController *navigationController;

@property (nonatomic, retain) NSDate *nextPasscodeCheckDate;

@end
