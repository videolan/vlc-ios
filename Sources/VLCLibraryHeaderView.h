/*****************************************************************************
 * VLCLibraryHeaderView.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCLibraryHeaderView : UICollectionReusableView

+ (CGFloat)headerHeight;

- (id)initWithPredefinedFrame;

@property (strong, nonatomic, readwrite) UISearchBar *searchBar;

@end
