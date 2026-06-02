/*****************************************************************************
 * VLCActiveDownloadCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Jean-Romain Bouquet <cabbry # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCActiveDownloadCell : UITableViewCell

@property (nonatomic, strong, nullable) NSString *name;
@property (nonatomic, strong, nullable) NSString *statsText;

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL progressKnown;

- (void)applyTheme;

@end
