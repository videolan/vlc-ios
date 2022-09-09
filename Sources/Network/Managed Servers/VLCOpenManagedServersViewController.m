/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Justin Osborne <justin # eblah.com>
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
}
@property (nonatomic) NSMutableArray *serverList;
@end

@implementation VLCOpenManagedServersViewController

- (NSString *)title
{
    return NSLocalizedString(@"MANAGED_SERVERS", nil);
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:@"VLCOpenManagedServersViewController" bundle:nil];
    
    if (self) {
        NSDictionary *managedConf = [NSUserDefaults.standardUserDefaults dictionaryForKey:@"com.apple.configuration.managed"];
        
        if (managedConf != nil) {
            _serverList = [managedConf mutableArrayValueForKey:@"server-list"];
        } else {
            managedConf = @{};
        }
    }

    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ManagedServersURLsTableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ManagedServersURLsTableViewCell"];
    }
    
    NSDictionary *serverItem = _serverList[indexPath.row];
    
    if (serverItem != nil) {
        NSString *serverUrl = [serverItem objectForKey:@"url"];
        cell.detailTextLabel.text = serverUrl;

        NSString *possibleTitle = [serverItem objectForKey:@"name"];
        cell.textLabel.text = (possibleTitle != nil) ? possibleTitle : [serverUrl lastPathComponent];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *url = [_serverList[indexPath.row] objectForKey:@"url"];
    [self.managedServersTableView deselectRowAtIndexPath:indexPath animated:NO];
    [self _openURLStringAndDismiss:(url == nil) ? @"" : url];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _serverList.count;
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
    return _serverList.count > 0;
}

@end
