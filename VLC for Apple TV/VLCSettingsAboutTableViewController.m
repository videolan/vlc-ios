//
//  VLCSettingsAboutTableTableViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 20/10/15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import "VLCSettingsAboutTableViewController.h"
#import "VLCAboutTVViewController.h"

@interface VLCSettingsAboutTableViewController ()
{
    VLCAboutTVViewController *_aboutVC;
}
@end

@implementation VLCSettingsAboutTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    _aboutVC = [[VLCAboutTVViewController alloc] initWithNibName:nil bundle:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.parentViewController showDetailViewController:_aboutVC sender:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentlyPlayedURLsTableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RecentlyPlayedURLsTableViewCell"];
    }

    cell.textLabel.text = @"text";
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

@end
