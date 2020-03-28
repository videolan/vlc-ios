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

@property (readwrite, retain) UILabel *priceLabel;

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

    UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 250., 50.)];
    priceLabel.textColor = colors.orangeUI;
    priceLabel.font = [UIFont boldSystemFontOfSize:17.];
    self.priceLabel = priceLabel;
    [self.contentView addSubview:priceLabel];
    priceLabel.center = self.contentView.center;

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
        self.priceLabel.textColor = [UIColor whiteColor];
        self.backgroundColor = colors.orangeUI;
    } else {
        self.priceLabel.textColor = colors.orangeUI;
        self.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.];
    }

    [super setSelected:selected];
}

- (void)setPrice:(NSString *)price
{
    self.priceLabel.text = price;
}

@end
