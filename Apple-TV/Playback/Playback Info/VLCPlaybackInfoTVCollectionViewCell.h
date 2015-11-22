/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCPlaybackInfoTVCollectionViewCell : UICollectionViewCell
@property (nonatomic) IBOutlet UILabel *selectionMarkerView;
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) BOOL selectionMarkerVisible;

+(NSString *)identifier;
@end
