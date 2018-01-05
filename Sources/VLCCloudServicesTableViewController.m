/*****************************************************************************
 * VLCCloudServicesTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudServicesTableViewController.h"
#import "VLCDropboxTableViewController.h"
#import "VLCGoogleDriveTableViewController.h"
#import "VLCBoxTableViewController.h"
#import "VLCBoxController.h"
#import "VLCOneDriveTableViewController.h"
#import "VLCOneDriveController.h"
#import "VLCDocumentPickerController.h"
#import "VLCCloudServiceCell.h"

#import "VLCGoogleDriveController.h"
#import "VLC_iOS-Swift.h"

@interface VLCCloudServicesTableViewController ()

@property (nonatomic) VLCDropboxTableViewController *dropboxTableViewController;
@property (nonatomic) VLCGoogleDriveTableViewController *googleDriveTableViewController;
@property (nonatomic) VLCBoxTableViewController *boxTableViewController;
@property (nonatomic) VLCOneDriveTableViewController *oneDriveTableViewController;
@property (nonatomic) VLCDocumentPickerController *documentPickerController;

@end

@implementation VLCCloudServicesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"VLCCloudServiceCell" bundle:nil] forCellReuseIdentifier:@"CloudServiceCell"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];
    [self themeDidChange];

    self.dropboxTableViewController = [[VLCDropboxTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];
    self.googleDriveTableViewController = [[VLCGoogleDriveTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];
    [[VLCBoxController sharedInstance] startSession];
    self.boxTableViewController = [[VLCBoxTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];
    self.oneDriveTableViewController = [[VLCOneDriveTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];
    self.documentPickerController = [VLCDocumentPickerController new];
}

- (void)themeDidChange
{
    self.tableView.separatorColor = PresentationTheme.current.colors.background;
    self.tableView.backgroundColor = PresentationTheme.current.colors.background;
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationSessionsChanged:) name:VLCOneDriveControllerSessionUpdated object:nil];
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (void)authenticationSessionsChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? PresentationTheme.current.colors.cellBackgroundA: PresentationTheme.current.colors.cellBackgroundB;
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [cell setPreservesSuperviewLayoutMargins:NO];
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    VLCCloudServiceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CloudServiceCell" forIndexPath:indexPath];
    cell.cloudTitle.textColor = cell.cloudInformation.textColor = cell.lonesomeCloudTitle.textColor = PresentationTheme.current.colors.cellTextColor;
    cell.icon.tintColor = PresentationTheme.current.colors.cellTextColor;
    switch (indexPath.row) {
        case 0: {
            //Dropbox
            BOOL isAuthorized = [[VLCDropboxController sharedInstance] isAuthorized];
            cell.icon.image = [UIImage imageNamed:@"Dropbox"];
            cell.cloudTitle.text = @"Dropbox";
            cell.cloudInformation.text = isAuthorized ? NSLocalizedString(@"LOGGED_IN", "") : NSLocalizedString(@"LOGIN", "");
            cell.lonesomeCloudTitle.text = @"";
            break;
        }
        case 1: {
            //GoogleDrive
            BOOL isAuthorized = [[VLCGoogleDriveController sharedInstance] isAuthorized];
            cell.icon.image = [UIImage imageNamed:@"Drive"];
            cell.cloudTitle.text = @"Google Drive";
            cell.cloudInformation.text = isAuthorized ? NSLocalizedString(@"LOGGED_IN", "") : NSLocalizedString(@"LOGIN", "");
            cell.lonesomeCloudTitle.text = @"";
            break;
        }
        case 2: {
            //Box
            BOOL isAuthorized = [[BoxSDK sharedSDK].OAuth2Session isAuthorized];
            cell.icon.image = [UIImage imageNamed:@"Box"];
            cell.cloudTitle.text = @"Box";
            cell.cloudInformation.text = isAuthorized ? NSLocalizedString(@"LOGGED_IN", "") : NSLocalizedString(@"LOGIN", "");
            cell.lonesomeCloudTitle.text = @"";
            break;
        }
        case 3: {
            //OneDrive
            BOOL isAuthorized = [[VLCOneDriveController sharedInstance] isAuthorized];
            cell.icon.image = [UIImage imageNamed:@"OneDrive"];
            cell.cloudTitle.text = @"OneDrive";
            cell.cloudInformation.text = isAuthorized ? NSLocalizedString(@"LOGGED_IN", "") : NSLocalizedString(@"LOGIN", "");
            cell.lonesomeCloudTitle.text = @"";
            break;
        }
        case 4:
            //Cloud Drives
            cell.icon.image = [UIImage imageNamed:@"iCloud"];
            cell.lonesomeCloudTitle.text = NSLocalizedString(@"CLOUD_SERVICES", nil);
            cell.cloudTitle.text = cell.cloudInformation.text = @"";
            break;
        default:
            break;
    }

    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 66.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            //dropBox
            [self.navigationController pushViewController:self.dropboxTableViewController animated:YES];
            break;
        case 1:
            //GoogleDrive
            [self.navigationController pushViewController:self.googleDriveTableViewController animated:YES];
            break;
        case 2:
            //Box
           [self.navigationController pushViewController:self.boxTableViewController animated:YES];
            break;
        case 3:
            //OneDrive
            [self.navigationController pushViewController:self.oneDriveTableViewController animated:YES];
            break;
        case 4:
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                [self.documentPickerController showDocumentMenuViewController:[(VLCCloudServiceCell *)[self.tableView cellForRowAtIndexPath:indexPath] icon]];
            else
                [self.documentPickerController showDocumentMenuViewController:nil];
            break;
        default:
            break;
    }
}

@end
