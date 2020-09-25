/*****************************************************************************
* VLCStoreCollectionViewCell.m
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
* $Id$
*
* Authors: Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

#import "VLCStoreCollectionViewCell.h"
#import "VLC-Swift.h"

@interface VLCStoreCollectionViewCell()
{
    UILabel *_priceLabel;
    UIColor *_lightBackgroundColor;
    UIColor *_darkBackgroundColor;
}
@end

@implementation VLCStoreCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    ColorPalette *colors = PresentationTheme.current.colors;

    _priceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _priceLabel.textColor = colors.orangeUI;
    _priceLabel.font = [UIFont boldSystemFontOfSize:17.];
    _priceLabel.textAlignment = NSTextAlignmentCenter;
    _priceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_priceLabel];

    NSDictionary *viewDict = @{ @"priceLabel" : _priceLabel };
    NSArray *controlPanelHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[priceLabel]|"
                                                                                      options:0
                                                                                      metrics:nil
                                                                                        views:viewDict];

    NSArray *controlPanelVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[priceLabel]|"
                                                                                       options:0
                                                                                       metrics:nil
                                                                                         views:viewDict];
    [self.contentView addConstraints:controlPanelHorizontalConstraints];
    [self.contentView addConstraints:controlPanelVerticalConstraints];

    _lightBackgroundColor = [UIColor colorWithWhite:0.98 alpha:1.];
    _darkBackgroundColor = [UIColor colorWithWhite:0.02 alpha:1.];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeDidChange)
                                                 name:kVLCThemeDidChangeNotification
                                               object:nil];
    [self themeDidChange];
}

- (void)themeDidChange
{
    self.backgroundColor = PresentationTheme.current.colors.isDark ? _darkBackgroundColor : _lightBackgroundColor;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self setSelected:NO];
}

- (void)setSelected:(BOOL)selected
{
    ColorPalette *colors = PresentationTheme.current.colors;

    if (selected) {
        _priceLabel.textColor = [UIColor whiteColor];
        self.backgroundColor = colors.orangeUI;
    } else {
        _priceLabel.textColor = colors.orangeUI;
        [self themeDidChange];
    }

    [super setSelected:selected];
}

- (void)setPrice:(NSString *)price
{
    _priceLabel.text = price;
}

@end
