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
#import "VLC-Swift.h"

static NSString *const VLCNetworkLoginSavedLoginCellIdentifier = @"VLCNetworkLoginSavedLoginCell";

@interface VLCNetworkLoginSavedLoginCell : UITableViewCell
@end

@interface VLCNetworkLoginDataSourceSavedLogins ()
@property (nonatomic) NSMutableArray<NSString *> *serverList;
@property (nonatomic, weak) UITableView *tableView;
@end
@implementation VLCNetworkLoginDataSourceSavedLogins
@synthesize sectionIndex = _sectionIndex;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _serverList = [NSMutableArray array];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(ubiquitousKeyValueStoreDidChange:)
                                   name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                 object:[NSUbiquitousKeyValueStore defaultStore]];

        NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
        [ukvStore synchronize];
        NSArray *ukvServerList = [ukvStore arrayForKey:kVLCStoredServerList];
        if (ukvServerList) {
            [_serverList addObjectsFromArray:ukvServerList];
        }
        [self migrateServerlistToCloudIfNeeded];
    }
    return self;
}


- (void)migrateServerlistToCloudIfNeeded
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (![defaults boolForKey:kVLCMigratedToUbiquitousStoredServerList]) {
        /* we need to migrate from previous, insecure storage fields */
        NSArray *ftpServerList = [defaults objectForKey:kVLCFTPServer];
        NSArray *ftpLoginList = [defaults objectForKey:kVLCFTPLogin];
        NSArray *ftpPasswordList = [defaults objectForKey:kVLCFTPPassword];
        NSUInteger count = ftpServerList.count;

        if (count > 0) {
            for (NSUInteger i = 0; i < count; i++) {
                XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
                keychainItem.service = ftpServerList[i];
                keychainItem.account = ftpLoginList[i];
                keychainItem.secret.stringValue = ftpPasswordList[i];
                [keychainItem saveWithError:nil];
                [_serverList addObject:ftpServerList[i]];
            }
        }

        NSArray *plexServerList = [defaults objectForKey:kVLCPLEXServer];
        NSArray *plexPortList = [defaults objectForKey:kVLCPLEXPort];
        count = plexServerList.count;
        if (count > 0) {
            for (NSUInteger i = 0; i < count; i++) {
                [_serverList addObject:[NSString stringWithFormat:@"plex://%@:%@", plexServerList[i], plexPortList[i]]];
            }
        }

        NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
        [ukvStore setArray:_serverList forKey:kVLCStoredServerList];
        [ukvStore synchronize];
        [defaults setBool:YES forKey:kVLCMigratedToUbiquitousStoredServerList];
    }

}


- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(ubiquitousKeyValueStoreDidChange:) withObject:notification waitUntilDone:NO];
        return;
    }

    /* TODO: don't blindly trust that the Cloud knows best */
    _serverList = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:kVLCStoredServerList]];
    // TODO: Vincent: array diff with insert and delete
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];;
}

#pragma mark - API

- (BOOL)saveLogin:(VLCNetworkServerLoginInformation *)login error:(NSError * _Nullable __autoreleasing *)error
{
    NSError *innerError = nil;
    BOOL success = [login saveLoginInformationToKeychainWithError:&innerError];
    if(!success) {
        NSLog(@"Failed to save login with error: %@",innerError);
        if (error) {
            *error = innerError;
        }
    }
    // even if the save fails we want to add the server identifier to the iCloud list
    NSString *serviceIdentifier = [login keychainServiceIdentifier];
    if (!serviceIdentifier) {
        *error = [NSError errorWithDomain:NSURLErrorDomain
                                     code:NSURLErrorBadURL
                                 userInfo:nil];
        return NO;
    }
    [_serverList addObject:serviceIdentifier];
    NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
    [ukvStore setArray:_serverList forKey:kVLCStoredServerList];
    [ukvStore synchronize];

    // TODO: Vincent: add row directly instead of section reload
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];

    return success;
}

- (BOOL)deleteItemAtRow:(NSUInteger)row error:(NSError * _Nullable __autoreleasing *)error
{
    NSString *serviceString = _serverList[row];
    NSError *innerError = nil;
    BOOL success = [XKKeychainGenericPasswordItem removeItemsForService:serviceString error:&innerError];
    if (!success) {
        NSLog(@"Failed to delete login with error: %@",innerError);
    }
    if (error) {
        *error = innerError;
    }

    [_serverList removeObject:serviceString];
    NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
    [ukvStore setArray:_serverList forKey:kVLCStoredServerList];
    [ukvStore synchronize];

    // TODO: Vincent: add row directly instead of section reload
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
    return self.serverList.count;
}

- (NSString *)cellIdentifierForRow:(NSUInteger)row
{
    return VLCNetworkLoginSavedLoginCellIdentifier;
}

- (void)configureCell:(UITableViewCell *)cell forRow:(NSUInteger)row
{
    NSString *serviceString = _serverList[row];
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
    VLCNetworkServerLoginInformation *login = [VLCNetworkServerLoginInformation loginInformationWithKeychainIdentifier:self.serverList[row]];
    NSError *error = nil;
    if ([login loadLoginInformationFromKeychainWithError:&error]) {
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
