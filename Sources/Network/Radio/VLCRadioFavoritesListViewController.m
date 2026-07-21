/*****************************************************************************
 * VLCRadioFavoritesListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioFavoritesListViewController.h"
#import "VLCPlaceholderArtwork.h"
#import "VLCFavoriteService.h"
#import "VLCAppCoordinator.h"
#import "VLCNetworkListCell.h"
#import "VLCPlaybackService.h"

#import "VLC-Swift.h"

@interface VLCRadioFavoritesListViewController ()
{
    VLCFavoriteService *_favoriteService;
    NSArray<VLCFavorite *> *_favorites;
}
@end

@implementation VLCRadioFavoritesListViewController

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

    self.title = NSLocalizedString(@"FAVORITES", nil);
    [self removePlayAllAction];
    self.navigationItem.searchController = nil;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    if (@available(iOS 13.0, *)) {
        self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    }

    _favoriteService = [[VLCAppCoordinator sharedInstance] favoriteService];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

    _favorites = [_favoriteService favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = NO;
}

#pragma mark - table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _favorites.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCNetworkListCellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCNetworkListCellIdentifier];

    VLCFavorite *favorite = _favorites[indexPath.row];

    [cell setIsDirectory:NO];
    [cell setTitleLabelCentered:favorite.mediaDescription.length == 0];
    [cell setTitle:favorite.userVisibleName];
    [cell setSubtitle:favorite.mediaDescription];

    cell.thumbnailView.layer.cornerRadius = 9.0;
    cell.thumbnailView.clipsToBounds = YES;
    [cell setIcon:[VLCPlaceholderArtwork placeholderImageForName:favorite.userVisibleName
                                                      size:CGSizeMake(44.0, 44.0)
                                              cornerRadius:9.0
                                                  fontSize:13.0]];
    cell.thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
    if (favorite.artworkURL) {
        [cell setIconURL:favorite.artworkURL];
    }

    cell.accessoryView = [self moreButtonForFavorite:favorite];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];

    ColorPalette *themeColors = PresentationTheme.current.colors;
    cell.titleLabel.textColor = cell.folderTitleLabel.textColor = themeColors.cellTextColor;
    cell.subtitleLabel.textColor = themeColors.cellDetailTextColor;
}

#pragma mark - actions

- (UIButton *)moreButtonForFavorite:(VLCFavorite *)favorite
{
    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    moreButton.tintColor = PresentationTheme.current.colors.cellDetailTextColor;
    if (@available(iOS 13.0, *)) {
        [moreButton setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
    } else {
        [moreButton setTitle:@"•••" forState:UIControlStateNormal];
    }
    [moreButton sizeToFit];

    if (@available(iOS 14.0, *)) {
        __weak typeof(self) weakSelf = self;
        UIAction *removeAction = [UIAction actionWithTitle:NSLocalizedString(@"REMOVE_FAVORITE", nil)
                                                     image:[UIImage systemImageNamed:@"heart.slash"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf removeFavorite:favorite];
        }];
        removeAction.attributes = UIMenuElementAttributesDestructive;
        moreButton.menu = [UIMenu menuWithTitle:@"" children:@[removeAction]];
        moreButton.showsMenuAsPrimaryAction = YES;
    }

    return moreButton;
}

- (void)removeFavorite:(VLCFavorite *)favorite
{
    [_favoriteService removeFavorite:favorite];
    _favorites = [_favoriteService favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio];
    [self.tableView reloadData];

    if (_favorites.count == 0)
        [self.navigationController popViewControllerAnimated:YES];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCFavorite *favorite = _favorites[indexPath.row];
    UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                              title:NSLocalizedString(@"REMOVE_FAVORITE", nil)
                                                                            handler:^(UIContextualAction * _Nonnull action,
                                                                                      UIView * _Nonnull sourceView,
                                                                                      void (^ _Nonnull completionHandler)(BOOL)) {
        [self removeFavorite:favorite];
        completionHandler(YES);
    }];
    removeAction.backgroundColor = PresentationTheme.current.colors.orangeUI;
    if (@available(iOS 13.0, *)) {
        removeAction.image = [UIImage systemImageNamed:@"heart.slash"];
    }
    return [UISwipeActionsConfiguration configurationWithActions:@[removeAction]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    VLCFavorite *favorite = _favorites[indexPath.row];
    VLCMedia *media = [VLCMedia mediaWithURL:favorite.url];
    if (!media)
        return;

    media.metaData.title = favorite.userVisibleName;
    if (favorite.artworkURL) {
        media.metaData.artworkURL = favorite.artworkURL;
    }

    VLCMediaList *mediaList = [[VLCMediaList alloc] init];
    [mediaList addMedia:media];
    [[VLCPlaybackService sharedInstance] playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil];

    [_favoriteService moveFavoriteToFront:favorite];
    _favorites = [_favoriteService favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio];
    [self.tableView reloadData];
}

@end
