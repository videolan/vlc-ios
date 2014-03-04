/*****************************************************************************
 * VLCLocalNetworkListCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class VLCStatusLabel;

@interface VLCLocalNetworkListCell : UITableViewCell

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *folderTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UIButton *downloadButton;
@property (nonatomic, strong) IBOutlet VLCStatusLabel *statusLabel;

@property (nonatomic, readwrite) BOOL isDirectory;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) UIImage *icon;
@property (nonatomic, retain) NSURL *iconURL;
@property (nonatomic, readwrite) BOOL isDownloadable;

+ (VLCLocalNetworkListCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

- (IBAction)triggerDownload:(id)sender;

@end

@protocol VLCLocalNetworkListCell <NSObject>

- (void)triggerDownloadForCell:(VLCLocalNetworkListCell *)cell;

@end
