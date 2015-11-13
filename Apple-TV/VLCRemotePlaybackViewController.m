/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemotePlaybackViewController.h"
#import "Reachability.h"
#import "VLCHTTPUploaderController.h"
#import "VLCMediaFileDiscoverer.h"

#define remotePlaybackReuseIdentifer @"remotePlaybackReuseIdentifer"

@interface VLCRemotePlaybackViewController () <UITableViewDataSource, UITableViewDelegate, VLCMediaFileDiscovererDelegate>
{
    Reachability *_reachability;
    NSMutableArray *_discoveredFiles;
}
@end

@implementation VLCRemotePlaybackViewController

- (NSString *)title
{
    return NSLocalizedString(@"WEBINTF_TITLE_ATV", nil);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _reachability = [Reachability reachabilityForLocalWiFi];
    self.httpServerLabel.textColor = [UIColor VLCDarkBackgroundColor];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(reachabilityChanged)
                               name:kReachabilityChangedNotification
                             object:nil];

    VLCMediaFileDiscoverer *discoverer = [VLCMediaFileDiscoverer sharedInstance];

    _discoveredFiles = [NSMutableArray array];

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    discoverer.directoryPath = [[searchPaths firstObject] stringByAppendingPathComponent:@"Upload"];
    [discoverer addObserver:self];
    [discoverer startDiscovering];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];

    [_reachability startNotifier];
    [self updateHTTPServerAddress];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_reachability stopNotifier];
}

- (void)reachabilityChanged
{
    [self updateHTTPServerAddress];
}

- (void)updateHTTPServerAddress
{
    BOOL connectedViaWifi = _reachability.currentReachabilityStatus == ReachableViaWiFi;
    self.toggleHTTPServerButton.enabled = connectedViaWifi;
    NSString *uploadText = connectedViaWifi ? [[VLCHTTPUploaderController sharedInstance] httpStatus] : NSLocalizedString(@"HTTP_UPLOAD_NO_CONNECTIVITY", nil);
    self.httpServerLabel.text = uploadText;
    if (connectedViaWifi && [VLCHTTPUploaderController sharedInstance].isServerRunning)
        [self.toggleHTTPServerButton setTitle:NSLocalizedString(@"HTTP_SERVER_ON", nil) forState:UIControlStateNormal];
    else
        [self.toggleHTTPServerButton setTitle:NSLocalizedString(@"HTTP_SERVER_OFF", nil) forState:UIControlStateNormal];
}

- (void)toggleHTTPServer:(id)sender
{
    BOOL futureHTTPServerState = ![VLCHTTPUploaderController sharedInstance].isServerRunning ;
    [[NSUserDefaults standardUserDefaults] setBool:futureHTTPServerState forKey:kVLCSettingSaveHTTPUploadServerStatus];
    [[VLCHTTPUploaderController sharedInstance] changeHTTPServerState:futureHTTPServerState];
    [self updateHTTPServerAddress];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:remotePlaybackReuseIdentifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:remotePlaybackReuseIdentifer];
    }

    NSString *cellTitle;
    NSUInteger row = indexPath.row;
    @synchronized(_discoveredFiles) {
        if (_discoveredFiles.count > row) {
            cellTitle = [_discoveredFiles[row] lastPathComponent];
        }
    }

    cell.textLabel.text = cellTitle;
    cell.imageView.image = [UIImage imageNamed:@"blank"];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger ret;

    @synchronized(_discoveredFiles) {
        ret = _discoveredFiles.count;
    }

    return ret;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSURL *url;
    @synchronized(_discoveredFiles) {
        url = [NSURL fileURLWithPath:_discoveredFiles[indexPath.row]];
    }
    [vpc playURL:url subtitlesFilePath:nil];
    [self presentViewController:[VLCFullscreenMovieTVViewController fullscreenMovieTVViewController]
                       animated:YES
                     completion:nil];
}

#pragma mark - media file discovery
- (void)mediaFilesFoundRequiringAdditionToStorageBackend:(NSArray<NSString *> *)foundFiles
{
    NSLog(@"Found files %@", foundFiles);

    @synchronized(_discoveredFiles) {
        _discoveredFiles = [NSMutableArray arrayWithArray:foundFiles];
    }
    [self.cachedMediaTableView reloadData];
}

- (void)mediaFileAdded:(NSString *)filePath loading:(BOOL)isLoading
{
    @synchronized(_discoveredFiles) {
        if ([_discoveredFiles indexOfObjectIdenticalTo:filePath] == NSNotFound) {
            [_discoveredFiles addObject:filePath];
        }
    }
    [self.cachedMediaTableView reloadData];
}

- (void)mediaFileDeleted:(NSString *)filePath
{
    NSLog(@"removed file %@", filePath);
    @synchronized(_discoveredFiles) {
        [_discoveredFiles removeObjectIdenticalTo:filePath];
    }
    [self.cachedMediaTableView reloadData];
}

@end
