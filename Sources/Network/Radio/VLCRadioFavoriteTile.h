/*****************************************************************************
 * VLCRadioFavoriteTile.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCRadioFavoriteTile : UICollectionViewCell

@property (class, readonly) NSString *reuseIdentifier;

- (void)configureWithName:(nullable NSString *)name artworkURL:(nullable NSURL *)artworkURL;

@end

NS_ASSUME_NONNULL_END
