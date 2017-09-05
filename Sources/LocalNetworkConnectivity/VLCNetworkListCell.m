/*****************************************************************************
 * VLCNetworkListCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkListCell.h"

#import "VLCStatusLabel.h"

@implementation VLCNetworkListCell

+ (VLCNetworkListCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCNetworkListCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCNetworkListCell class]], @"meh meh");
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[nibContentArray lastObject];

    return cell;
}

- (void)awakeFromNib
{
    self.titleLabel.text = @"";
    self.subtitleLabel.text = @"";
    self.thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    self.downloadButton.hidden = YES;
    self.titleLabel.highlightedTextColor = [UIColor blackColor];
    self.folderTitleLabel.highlightedTextColor = [UIColor blackColor];
    self.subtitleLabel.highlightedTextColor = [UIColor blackColor];
    self.statusLabel.highlightedTextColor = [UIColor blackColor];
    [super awakeFromNib];
}

- (void)setTitleLabelCentered:(BOOL)titleLabelCentered
{
    self.titleLabel.hidden = self.subtitleLabel.hidden = titleLabelCentered;
    self.folderTitleLabel.hidden = !titleLabelCentered;

    _titleLabelCentered = titleLabelCentered;
}

- (void)setIsDirectory:(BOOL)isDirectory
{
    self.titleLabelCentered = isDirectory;

    _isDirectory = isDirectory;
}

- (void)setTitle:(NSString *)title
{
    BOOL isDirOrCentered = self.isDirectory || [self isTitleLabelCentered];

    self.folderTitleLabel.text = self.titleLabel.text = title;

    self.titleLabel.hidden = self.subtitleLabel.hidden = isDirOrCentered;
    self.folderTitleLabel.hidden = !isDirOrCentered;

    _title = title;
}

- (void)setSubtitle:(NSString *)subtitle
{
    self.subtitleLabel.text = subtitle;
}

- (void)setIcon:(UIImage *)icon
{
    self.thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    self.thumbnailView.image = icon;
}

- (void)setIconURL:(NSURL *)iconURL
{
    _iconURL = iconURL;
    [self.thumbnailView setImageWithURL:iconURL];
}

- (void)setIsDownloadable:(BOOL)isDownloadable
{
    self.downloadButton.hidden = !isDownloadable;
}

- (void)triggerDownload:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(triggerDownloadForCell:)])
        [self.delegate triggerDownloadForCell:self];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.thumbnailView cancelLoading];
    self.isDownloadable = NO;
    self.subtitle = nil;
    self.title = nil;
}

+ (CGFloat)heightOfCell
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 80.;

    return 68.;
}

@end



@implementation VLCNetworkListCell (CellConfigurator)

@dynamic couldBeAudioOnlyMedia;

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    self.icon = thumbnailImage;
}
- (UIImage *)thumbnailImage {
    return self.icon;
}
- (void)setThumbnailURL:(NSURL *)thumbnailURL {
    self.iconURL = thumbnailURL;
}
- (NSURL *)thumbnailURL {
    return self.iconURL;
}

@end
