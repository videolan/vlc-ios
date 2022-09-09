/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCDeletionCapableViewController : UIViewController

@property (nonatomic, weak, nullable) IBOutlet UIView *deleteHintView;
@property (nonatomic, readonly, nullable) NSIndexPath *indexPathToDelete;
@property (nonatomic, readonly, nullable) NSString *itemToDelete;

- (void)deleteFileAtIndex:(NSIndexPath * _Nullable)indexPathToDelete;

@end
