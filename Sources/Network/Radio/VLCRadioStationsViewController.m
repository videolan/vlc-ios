/*****************************************************************************
 * VLCRadioStationsViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioStationsViewController.h"
#import "VLCPlaceholderArtwork.h"
#import "VLCRadioErrorView.h"
#import "VLCNetworkListCell.h"

#import "VLC-Swift.h"

static NSTimeInterval const kVLCRadioStationsDiscoveryTimeout = 20.0;

@interface VLCRadioStationsViewController ()
{
    NSTimer *_timeoutTimer;
    UIView *_errorView;
}
@end

@implementation VLCRadioStationsViewController

- (void)dealloc
{
    [_timeoutTimer invalidate];
}

- (UITableViewStyle)tableViewStyle
{
    if (@available(iOS 13.0, *)) {
        return UITableViewStyleInsetGrouped;
    }
    return UITableViewStyleGrouped;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    if (@available(iOS 13.0, *)) {
        self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

    [self startTimeout];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = NO;

    [self cancelTimeout];
}

#pragma mark - loading timeout

- (BOOL)hasStations
{
    return [self.tableView numberOfRowsInSection:0] > 0;
}

- (void)startTimeout
{
    [_timeoutTimer invalidate];

    if ([self hasStations])
        return;

    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kVLCRadioStationsDiscoveryTimeout
                                                     target:self
                                                   selector:@selector(discoveryTimedOut)
                                                   userInfo:nil
                                                    repeats:NO];
}

- (void)cancelTimeout
{
    [_timeoutTimer invalidate];
    _timeoutTimer = nil;
}

- (void)discoveryTimedOut
{
    _timeoutTimer = nil;

    if ([self hasStations])
        return;

    [self stopActivityIndicator];
    self.tableView.backgroundView = self.errorView;
}

- (void)networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser
{
    [super networkServerBrowserDidUpdate:networkBrowser];

    if ([self hasStations]) {
        [self cancelTimeout];
        self.tableView.backgroundView = nil;
    }
}

- (void)networkServerBrowserEndParsing:(id<VLCNetworkServerBrowser>)networkBrowser
{
    [super networkServerBrowserEndParsing:networkBrowser];

    [self cancelTimeout];
}

- (void)networkServerBrowser:(id<VLCNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error
{
    [self cancelTimeout];
    [self stopActivityIndicator];
    self.tableView.backgroundView = self.errorView;
}

- (UIView *)errorView
{
    if (_errorView)
        return _errorView;

    _errorView = [[VLCRadioErrorView alloc] initWithMessage:NSLocalizedString(@"RADIO_STATIONS_LOADING_FAILED", nil)
                                                retryTarget:self
                                                retryAction:@selector(retryButtonTapped)];
    return _errorView;
}

- (void)retryButtonTapped
{
    self.tableView.backgroundView = nil;
    [self startActivityIndicator];
    [self startTimeout];
    [self update];
}

#pragma mark - cell configuration

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];

    if (![cell isKindOfClass:[VLCNetworkListCell class]])
        return;

    [self applyBrandArtworkToCell:cell];
    [self applyMoreButtonToCell:cell];
}

- (void)applyBrandArtworkToCell:(VLCNetworkListCell *)cell
{
    cell.thumbnailView.layer.cornerRadius = 9.0;
    cell.thumbnailView.clipsToBounds = YES;
    cell.thumbnailView.contentMode = UIViewContentModeScaleAspectFill;

    NSURL *iconURL = cell.iconURL;
    UIImage *cachedArtwork = iconURL ? [[VLCNetworkImageView sharedImageCache] objectForKey:iconURL] : nil;
    if (cachedArtwork) {
        cell.thumbnailView.image = cachedArtwork;
        return;
    }

    NSString *name = cell.titleLabel.text.length > 0 ? cell.titleLabel.text : cell.folderTitleLabel.text;
    cell.thumbnailView.image = [VLCPlaceholderArtwork placeholderImageForName:name
                                                                   size:CGSizeMake(44.0, 44.0)
                                                           cornerRadius:9.0
                                                               fontSize:13.0];
}

- (void)applyMoreButtonToCell:(VLCNetworkListCell *)cell
{
    if (!cell.isFavorable) {
        cell.accessoryView = nil;
        return;
    }

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    moreButton.tintColor = PresentationTheme.current.colors.cellDetailTextColor;
    if (@available(iOS 13.0, *)) {
        [moreButton setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
    } else {
        [moreButton setTitle:@"•••" forState:UIControlStateNormal];
    }
    [moreButton sizeToFit];

    if (@available(iOS 14.0, *)) {
        BOOL isFavorite = cell.isFavorite;
        NSString *title = isFavorite ? NSLocalizedString(@"REMOVE_FAVORITE", nil)
                                     : NSLocalizedString(@"ADD_FAVORITE", nil);
        UIImage *image = [UIImage systemImageNamed:isFavorite ? @"heart.slash" : @"heart.fill"];
        __weak VLCNetworkListCell *weakCell = cell;
        UIAction *favoriteAction = [UIAction actionWithTitle:title
                                                       image:image
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
            [weakCell triggerFavorite:nil];
        }];
        moreButton.menu = [UIMenu menuWithTitle:@"" children:@[favoriteAction]];
        moreButton.showsMenuAsPrimaryAction = YES;
    } else {
        [moreButton addTarget:cell action:@selector(triggerFavorite:) forControlEvents:UIControlEventTouchUpInside];
    }

    cell.accessoryView = moreButton;
}

@end
