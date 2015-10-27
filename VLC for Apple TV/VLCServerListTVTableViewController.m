//
//  VLCServerListTableViewController.m
//  VLC for iOS
//
//  Created by Tobias Conradi on 27.10.15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import "VLCServerListTVTableViewController.h"
#import "VLCLocalNetworkServerTVCell.h"

@interface VLCServerListTVTableViewController ()

@end

@implementation VLCServerListTVTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    UINib *nib = [UINib nibWithNibName:@"VLCLocalNetworkServerTVCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:VLCLocalServerTVCell];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.discoveryController.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.discoveryController numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCLocalServerTVCell forIndexPath:indexPath];
    id<VLCLocalNetworkService> service = [self.discoveryController networkServiceForIndexPath:indexPath];
    cell.textLabel.text = service.title;
    cell.imageView.image = service.icon;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

#pragma mark - VLCLocalServerDiscoveryController
- (void)discoveryFoundSomethingNew {
    [self.tableView reloadData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
