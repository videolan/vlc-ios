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

#import "VLCOpenManagedServersViewController.h"
#import "VLCPlaybackService.h"
#import "VLCPlayerDisplayController.h"
#import "VLCFullscreenMovieTVViewController.h"
#import "CAAnimation+VLCWiggle.h"

@interface VLCOpenManagedServersViewController ()
{
    NSMutableArray *_serverList;
    NSDictionary *_managedConf;
}
@property (nonatomic) NSIndexPath *currentlyFocusedIndexPath;
@property (nonatomic) NSMutableArray *serverList;
@end

@implementation VLCOpenManagedServersViewController

- (NSString *)title
{
    return NSLocalizedString(@"MANAGED_SERVERS", nil);
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    NSDictionary *_managedConf = [NSUserDefaults.standardUserDefaults dictionaryForKey:@"com.apple.configuration.managed"];
    
    if (_managedConf == nil) {
        _managedConf = @{};
    }
    
    _serverList = [_managedConf mutableArrayValueForKey:@"server-list"];

    return [super initWithNibName:@"VLCOpenManagedServersViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(tvOS 13.0, *)) {
        self.navigationController.navigationBarHidden = YES;
    }

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(ubiquitousKeyValueStoreDidChange:)
                               name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                             object:[NSUbiquitousKeyValueStore defaultStore]];

    self.managedServersTableView.backgroundColor = [UIColor clearColor];
    self.managedServersTableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.managedServersTableView reloadData];
    [super viewWillAppear:animated];
}

- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(ubiquitousKeyValueStoreDidChange:) withObject:notification waitUntilDone:NO];
        return;
    }

    [self.managedServersTableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    /* force update before we leave */
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentlyPlayedURLsTableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"RecentlyPlayedURLsTableViewCell"];
    }
    
    NSString *content = [_serverList[indexPath.row] objectForKey:@"url"];
    NSString *possibleTitle = [_serverList[indexPath.row] objectForKey:@"name"];

    cell.detailTextLabel.text = content;
    cell.textLabel.text = (possibleTitle != nil) ? possibleTitle : [content lastPathComponent];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *_url = [_serverList[indexPath.row] objectForKey:@"url"];
    
    [self.managedServersTableView deselectRowAtIndexPath:indexPath animated:NO];
    [self _openURLStringAndDismiss:_url];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = _serverList.count;
    return count;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentlyFocusedIndexPath = indexPath;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)_openURLStringAndDismiss:(NSString *)urlString
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:urlString]];
    VLCMediaList *medialist = [[VLCMediaList alloc] init];
    [medialist addMedia:media];

    [vpc playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
    [self presentViewController:[VLCFullscreenMovieTVViewController fullscreenMovieTVViewController]
                       animated:YES
                     completion:nil];
}

- (BOOL)hasManagedServers {
    NSInteger count = _serverList.count;
    if (count > 0) return YES;
    else return NO;
}

@end
