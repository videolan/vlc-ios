/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServerBrowsingTVCell.h"

NSString *const VLCServerBrowsingTVCellIdentifier = @"VLCServerBrowsingTVCell";

@implementation VLCServerBrowsingTVCell
@synthesize thumbnailURL = _thumbnailURL, isDirectory = _isDirectory;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}
- (void)setThumbnailURL:(NSURL *)thumbnailURL {
    _thumbnailURL = thumbnailURL;
    [self.thumbnailImageView setImageWithURL:thumbnailURL];
}
- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    [self.thumbnailImageView setImage:thumbnailImage];
}
-(UIImage *)thumbnailImage {
    return self.thumbnailImageView.image;
}
- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}
- (NSString *)title {
    return self.titleLabel.text;
}
- (void)setSubtitle:(NSString *)subtitle {
    self.subtitleLabel.text = subtitle;
}
- (NSString *)subtitle {
    return self.subtitleLabel.text;
}

@end


