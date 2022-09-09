/*****************************************************************************
 * VLCStreamingHistoryCell.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Adam Viaud <mcnight # mcnight.fr>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCStreamingHistoryCell.h"
#import "VLC-Swift.h"

@implementation VLCStreamingHistoryCell

+ (VLCStreamingHistoryCell *)cellWithReuseIdentifier:(NSString *)ident
{
    NSArray *nibContentArray = [[NSBundle mainBundle] loadNibNamed:@"VLCStreamingHistoryCell" owner:nil options:nil];
    NSAssert([nibContentArray count] == 1, @"meh");
    NSAssert([[nibContentArray lastObject] isKindOfClass:[VLCStreamingHistoryCell class]], @"meh meh");
    VLCStreamingHistoryCell *cell = (VLCStreamingHistoryCell *)[nibContentArray lastObject];

    return cell;
}

- (void)awakeFromNib
{
    self.titleLabel.text = @"";
    self.subtitleLabel.text = @"";
    self.thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
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
    ColorPalette *colors = PresentationTheme.current.colors;
    self.titleLabel.textColor = colors.cellTextColor;
    self.subtitleLabel.textColor = colors.cellDetailTextColor;
    self.titleLabel.highlightedTextColor = colors.cellTextColor;
    self.subtitleLabel.highlightedTextColor = colors.cellDetailTextColor;

    UIColor *backgroundColor = colors.background;

    if (@available(iOS 13.0, *)) {
        backgroundColor = UIColor.clearColor;
    }

    self.backgroundColor = backgroundColor;
    self.titleLabel.backgroundColor = backgroundColor;
    self.subtitleLabel.backgroundColor = backgroundColor;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copy:) || action == @selector(renameStream:)) || [super canPerformAction:action withSender:sender];
}

- (void)customizeAppearance {
    self.textLabel.textColor = [UIColor whiteColor];
    self.detailTextLabel.textColor = [UIColor VLCLightTextColor];
}

- (void)renameStream:(id)sender {
    [self.delegate renameStreamFromCell:self];
}

+ (CGFloat)heightOfCell
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 80.;

    return 68.;
}

@end
