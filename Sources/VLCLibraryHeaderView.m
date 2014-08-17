/*****************************************************************************
 * VLCLibraryHeaderView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLibraryHeaderView.h"

@interface VLCLibraryHeaderView ()
{
    UISearchBar *_searchbar;
}

@end

@implementation VLCLibraryHeaderView

+ (CGFloat)headerHeight
{
    return 40.;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithPredefinedFrame];
}

- (id)initWithPredefinedFrame
{
    self = [super initWithFrame:CGRectMake(0., 0., 320., [VLCLibraryHeaderView headerHeight])];

    if (self)
        self.backgroundColor = [UIColor VLCDarkBackgroundColor];

    return self;
}

- (void)setSearchBar:(UISearchBar *)searchBar
{
    if (searchBar == nil) {
        if (_searchbar)
            [_searchbar removeFromSuperview];
        _searchbar = nil;
        return;
    }

    _searchbar = searchBar;

    CGRect contentFrame = self.frame;
    _searchbar.frame = contentFrame;
    [self addSubview:_searchbar];
}

- (UISearchBar *)searchBar
{
    return _searchbar;
}

@end
