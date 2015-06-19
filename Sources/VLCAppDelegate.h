/*****************************************************************************
 * VLCAppDelegate.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
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

#import "VLCHTTPUploaderController.h"
#import "GHRevealViewController.h"
#import "VLCMenuTableViewController.h"
#import "VLCDownloadViewController.h"

@class VLCPlaylistViewController;
@class VLCPlayerDisplayController;

extern NSString *const VLCDropboxSessionWasAuthorized;
extern NSString *const VLCPasscodeValidated;

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
- (void)openMovieWithExternalSubtitleFromURL:(NSURL *)url externalSubURL:(NSString *)SubtitlePath;

@property (nonatomic, readonly) VLCPlaylistViewController *playlistViewController;
@property (nonatomic, readonly) VLCDownloadViewController *downloadViewController;

@property (nonatomic, readonly) VLCPlayerDisplayController *playerDisplayController;

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) GHRevealViewController *revealController;
@property (nonatomic, strong) VLCMenuTableViewController *menuViewController;

@property (nonatomic) VLCHTTPUploaderController *uploadController;
@property (nonatomic, readonly) BOOL passcodeValidated;

@end
