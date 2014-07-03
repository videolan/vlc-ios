/*****************************************************************************
 * VLCLocalNetworkListCell.m
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

#import "VLCLocalNetworkListCell.h"

#import "VLCStatusLabel.h"

@implementation VLCLocalNetworkListCell

+ (VLCLocalNetworkListCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCLocalNetworkListCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCLocalNetworkListCell class]], @"meh meh");
    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[nibContentArray lastObject];

    return cell;
}

- (void)awakeFromNib
{
    self.titleLabel.text = @"";
    self.subtitleLabel.text = @"";
    self.thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    self.downloadButton.hidden = YES;

    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        self.titleLabel.highlightedTextColor = [UIColor blackColor];
        self.folderTitleLabel.highlightedTextColor = [UIColor blackColor];
        self.subtitleLabel.highlightedTextColor = [UIColor blackColor];
        self.statusLabel.highlightedTextColor = [UIColor blackColor];
    }
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
    self.thumbnailView.image = icon;
}

- (void)setIconURL:(NSURL *)iconURL
{
    _iconURL = iconURL;
    [self performSelectorInBackground:@selector(_updateIconFromURL) withObject:@""];
}

- (void)_updateIconFromURL
{
    NSData* imageData = [[NSData alloc]initWithContentsOfURL:self.iconURL];
    UIImage* image = [[UIImage alloc] initWithData:imageData];
    [self setIcon:image];
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

+ (CGFloat)heightOfCell
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 80.;

    return 68.;
}

@end
