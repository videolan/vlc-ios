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
#import "VLCHTTPUploaderController.h"
#import "GHRevealViewController.h"
#import "VLCMenuTableViewController.h"
#import "VLCDownloadViewController.h"

@class VLCPlaylistViewController;
@class PAPasscodeViewController;
@interface VLCAppDelegate : UIResponder <UIApplicationDelegate>

- (void)updateMediaList;
- (void)disableIdleTimer;
- (void)activateIdleTimer;

@property (nonatomic, readonly) VLCPlaylistViewController *playlistViewController;
@property (nonatomic, readonly) VLCDropboxTableViewController *dropboxTableViewController;
@property (nonatomic, readonly) VLCDownloadViewController *downloadViewController;

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) GHRevealViewController *revealController;
@property (nonatomic, strong) VLCMenuTableViewController *menuViewController;

@property (nonatomic, retain) NSDate *nextPasscodeCheckDate;

@property (nonatomic) VLCHTTPUploaderController *uploadController;

@end
