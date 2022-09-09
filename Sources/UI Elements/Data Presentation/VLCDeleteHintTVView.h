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

@interface VLCDeleteHintTVView : UIView
@property (nonatomic) UIVisualEffectView *effectView;
@property (nonatomic) UILabel *leadingLabel;
@property (nonatomic) UIImageView *glyphImageView;
@property (nonatomic) UILabel *trailingLabel;
@end
