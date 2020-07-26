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

    self.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.];
}

- (void)prepareForReuse
{
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
        self.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.];
    }

    [super setSelected:selected];
}

- (void)setPrice:(NSString *)price
{
    _priceLabel.text = price;
}

@end
