//
//  VLCServerListTableViewController.m
//  VLC for iOS
//
//  Created by Tobias Conradi on 27.10.15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import "VLCServerListTVTableViewController.h"
#import "VLCLocalNetworkServerTVCell.h"
#import "VLCServerBrowsingTVTableViewController.h"

@interface VLCServerListTVTableViewController ()

@end

@implementation VLCServerListTVTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    UINib *nib = [UINib nibWithNibName:@"VLCLocalNetworkServerTVCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:VLCLocalServerTVCell];
    self.tableView.rowHeight = 150;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.discoveryController startDiscovery];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.discoveryController stopDiscovery];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.discoveryController.numberOfSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    VLCLocalServerDiscoveryController *discoverer = self.discoveryController;
    if (discoverer.numberOfSections > 1 && [discoverer numberOfItemsInSection:section] > 0) {
        return [self.discoveryController titleForSection:section];
    }
    return nil;
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

- (void)showWIP:(NSString *)todo {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Work in Progress\nFeature not (yet) implemented."
                                                                             message:todo
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Please fix this!"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Nevermind"
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    id<VLCLocalNetworkService> service = [self.discoveryController networkServiceForIndexPath:indexPath];
    if ([service respondsToSelector:@selector(serverBrowser)]) {
        id <VLCNetworkServerBrowser> browser = [service serverBrowser];
        if (browser) {
            VLCServerBrowsingTVTableViewController *browsingViewController = [[VLCServerBrowsingTVTableViewController alloc] initWithServerBrowser:browser];
            [self showViewController:browsingViewController sender:nil];
            return;
        }
    }

    if ([service respondsToSelector:@selector(loginInformation)]) {
        [self showWIP:@"Login"];
        return;
    }
    if ([service respondsToSelector:@selector(directPlaybackURL)]) {
        [self showWIP:@"Direct playback form URL"];
        return;
    }

}

#pragma mark - VLCLocalServerDiscoveryController
- (void)discoveryFoundSomethingNew {
    [self.tableView reloadData];
    NSLog(@"%s",__PRETTY_FUNCTION__);
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
