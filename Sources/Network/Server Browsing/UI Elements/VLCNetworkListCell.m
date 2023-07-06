/*****************************************************************************
 * VLCNetworkListCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkListCell.h"

#import "VLCStatusLabel.h"

#import "VLC-Swift.h"

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
    self.favoriteButton.hidden = YES;
    self.isFavorite = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange)
                                                 name:kVLCThemeDidChangeNotification object:nil];
    // If a tableViewCell is highlighted, one needs to manualy set the opaque property
    if (@available(iOS 13.0, *)) {
        self.opaque = NO;
    }
    [self themeDidChange];
    [super awakeFromNib];
}

- (void)themeDidChange
{
    self.titleLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    self.subtitleLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor;
    self.folderTitleLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor;
    self.titleLabel.highlightedTextColor = PresentationTheme.current.colors.cellTextColor;
    self.subtitleLabel.highlightedTextColor = PresentationTheme.current.colors.cellDetailTextColor;
    self.folderTitleLabel.highlightedTextColor = PresentationTheme.current.colors.cellTextColor;

    UIColor *backgroundColor = PresentationTheme.current.colors.background;

    if (@available(iOS 13.0, *)) {
        backgroundColor = UIColor.clearColor;
    }

    self.backgroundColor = backgroundColor;
    self.titleLabel.backgroundColor = backgroundColor;
    self.folderTitleLabel.backgroundColor = backgroundColor;
    self.subtitleLabel.backgroundColor = backgroundColor;
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

- (void)setIsFavorable:(BOOL)isFavorable
{
    self.favoriteButton.hidden = !isFavorable;
}

- (void)setIsFavorite:(BOOL)isFavorite
{
    if (isFavorite) {
        [self.favoriteButton setImage:[UIImage imageNamed:@"heart.fill"] forState:UIControlStateNormal];
    } else {
        [self.favoriteButton setImage:[UIImage imageNamed:@"heart"] forState:UIControlStateNormal];
    }
    _isFavorite = isFavorite;
}

- (void)triggerDownload:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(triggerDownloadForCell:)])
        [self.delegate triggerDownloadForCell:self];
}

- (void)triggerFavorite:(id)sender
{
    if([self.delegate respondsToSelector:@selector(triggerFavoriteForCell:)])
        [self.delegate triggerFavoriteForCell:self];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.thumbnailView cancelLoading];
    self.isDownloadable = NO;
    self.isFavorable = NO;
    self.subtitle = nil;
    self.title = nil;
    self.iconURL = nil;
    self.icon = nil;
}

+ (CGFloat)heightOfCell
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 80.;

    return 68.;
}

- (CGFloat)edgePadding
{
    return 15.0;
}

- (CGFloat)interItemPadding
{
    return 5.0;
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
