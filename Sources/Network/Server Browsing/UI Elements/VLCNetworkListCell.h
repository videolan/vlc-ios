/*****************************************************************************
 * VLCNetworkListCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "VLCNetworkImageView.h"
#import "VLCServerBrowsingController.h"


@class VLCStatusLabel;

@interface VLCNetworkListCell : UITableViewCell

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *folderTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet VLCNetworkImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UIButton *downloadButton;
@property (nonatomic, strong) IBOutlet VLCStatusLabel *statusLabel;
@property (nonatomic, strong) IBOutlet UIButton *favoriteButton;

@property (nonatomic, readwrite) BOOL isDirectory;

/// When there is no subtitle content, you might want to enable this
@property (nonatomic, getter = isTitleLabelCentered) BOOL titleLabelCentered;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) UIImage *icon;
@property (nonatomic, retain) NSURL *iconURL;
@property (nonatomic, readwrite) BOOL isDownloadable;
@property (nonatomic, readwrite) BOOL isFavorable;
@property (nonatomic, readwrite) BOOL isFavorite;

@property (nonatomic, readonly) CGFloat edgePadding;
@property (nonatomic, readonly) CGFloat interItemPadding;

+ (VLCNetworkListCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

- (IBAction)triggerDownload:(id)sender;
- (IBAction)triggerFavorite:(id)sender;

@end

@protocol VLCNetworkListCellDelegate <NSObject>

- (void)triggerDownloadForCell:(VLCNetworkListCell *)cell;
- (void)triggerFavoriteForCell:(VLCNetworkListCell *)cell;

@end


@interface VLCNetworkListCell (CellConfigurator) <VLCRemoteBrowsingCell>

@end
