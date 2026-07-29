/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 - 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkLoginDataSourceSavedLogins.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>
#import "VLCNetworkServerLoginInformation+Keychain.h"
#import "VLCSavedServerList.h"
#import "VLCAppCoordinator.h"
#import "VLC-Swift.h"

static NSString *const VLCNetworkLoginSavedLoginCellIdentifier = @"VLCNetworkLoginSavedLoginCell";

@interface VLCNetworkLoginSavedLoginCell : UITableViewCell
@end

@interface VLCNetworkLoginDataSourceSavedLogins ()
@property (nonatomic) VLCSavedServerList *savedServerList;
@property (nonatomic, weak) UITableView *tableView;
@end
@implementation VLCNetworkLoginDataSourceSavedLogins
@synthesize sectionIndex = _sectionIndex;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _savedServerList = [[VLCAppCoordinator sharedInstance] savedServerList];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(savedServerListDidChange)
                                                     name:VLCSavedServerListDidChange
                                                   object:nil];
    }
    return self;
}

- (void)savedServerListDidChange
{
    [self.tableView reloadData];
}

#pragma mark - API

- (BOOL)saveLogin:(VLCNetworkServerLoginInformation *)login error:(NSError * _Nullable __autoreleasing *)error
{
    BOOL success = [_savedServerList addLogin:login error:error];
    [self.tableView reloadData];
    return success;
}

- (BOOL)deleteItemAtRow:(NSUInteger)row error:(NSError * _Nullable __autoreleasing *)error
{
    BOOL success = [_savedServerList removeServerAtIndex:row error:error];
    [self.tableView reloadData];
    return success;
}

#pragma mark -

- (void)configureWithTableView:(UITableView *)tableView
{
    [tableView registerClass:[VLCNetworkLoginSavedLoginCell class] forCellReuseIdentifier:VLCNetworkLoginSavedLoginCellIdentifier];
    self.tableView = tableView;
}

- (NSUInteger)numberOfRowsInTableView:(UITableView *)tableView
{
    return _savedServerList.serverIdentifiers.count;
}

- (NSString *)cellIdentifierForRow:(NSUInteger)row
{
    return VLCNetworkLoginSavedLoginCellIdentifier;
}

- (void)configureCell:(UITableViewCell *)cell forRow:(NSUInteger)row
{
    NSString *serviceString = _savedServerList.serverIdentifiers[row];
    NSURL *service = [NSURL URLWithString:serviceString];
    NSString *serviceHost = [NSString stringWithFormat:@"%@%@", service.host, service.path];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ [%@]", serviceHost, [service.scheme uppercaseString]];
    XKKeychainGenericPasswordItem *keychainItem = [XKKeychainGenericPasswordItem itemsForService:serviceString error:nil].firstObject;
    if (keychainItem) {
        cell.detailTextLabel.text = keychainItem.account;
    } else {
        cell.detailTextLabel.text = @"";
    }
}

- (void)commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRow:(NSUInteger)row
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteItemAtRow:row error:nil];
    }
}

- (void)didSelectRow:(NSUInteger)row
{
    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:self.sectionIndex] animated:YES];
    NSError *error = nil;
    VLCNetworkServerLoginInformation *login = [_savedServerList loginAtIndex:row error:&error];
    if (login) {
        [self.delegate loginsDataSource:self selectedLogin:login];
    } else {
        [self showKeychainLoadError:error forLogin:login];
    }
}

- (void)showKeychainLoadError:(NSError *)error forLogin:(VLCNetworkServerLoginInformation *)login
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];

    UIViewController *presentingVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    presentingVC = presentingVC.presentedViewController ?: presentingVC;
    [presentingVC presentViewController:alertController animated:YES completion:nil];
}

@end


@implementation VLCNetworkLoginSavedLoginCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];
        [self themeDidChange];
    }
    return self;
}

- (void)themeDidChange
{
    self.backgroundColor = PresentationTheme.current.colors.background;
    self.textLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    self.detailTextLabel.textColor = PresentationTheme.current.colors.lightTextColor;
}

@end
