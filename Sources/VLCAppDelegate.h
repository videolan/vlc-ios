/*****************************************************************************
 * VLCAppDelegate.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import "VLCDropboxTableViewController.h"
#import "VLCHTTPUploaderController.h"
#import "GHRevealViewController.h"
#import "VLCMenuTableViewController.h"
#import "VLCDownloadViewController.h"
#import "BWQuincyManager.h"

@class VLCPlaylistViewController;
@class PAPasscodeViewController;
@interface VLCAppDelegate : UIResponder <UIApplicationDelegate>

- (void)updateMediaList;
- (void)disableIdleTimer;
- (void)activateIdleTimer;

- (void)networkActivityStarted;
- (BOOL)haveNetworkActivity;
- (void)networkActivityStopped;

- (void)cleanCache;

- (void)openMediaFromManagedObject:(NSManagedObject *)file;
- (void)openMovieFromURL:(NSURL *)url;
- (void)openMediaList:(VLCMediaList*)list atIndex:(int)index;
- (void)openMovieWithExternalSubtitleFromURL:(NSURL *)url externalSubURL:(NSString *)SubtitlePath;

@property (nonatomic, readonly) VLCPlaylistViewController *playlistViewController;
@property (nonatomic, readonly) VLCDropboxTableViewController *dropboxTableViewController;
@property (nonatomic, readonly) VLCDownloadViewController *downloadViewController;

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) GHRevealViewController *revealController;
@property (nonatomic, strong) VLCMenuTableViewController *menuViewController;

@property (nonatomic) VLCHTTPUploaderController *uploadController;

@end
