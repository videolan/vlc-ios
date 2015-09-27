/*****************************************************************************
 * VLCRowController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <WatchKit/WatchKit.h>
@interface VLCRowController : NSObject
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *titleLabel;
@property (nonatomic, weak) IBOutlet WKInterfaceGroup *group;
@property (nonatomic, weak) IBOutlet WKInterfaceObject *progressObject;


@property (nonatomic, copy) NSString *mediaTitle;
@property (nonatomic) CGFloat playbackProgress;

@property (nonatomic, weak, readonly) NSManagedObject *mediaLibraryObject;

- (void) configureWithMediaLibraryObject:(NSManagedObject *)object;

@end
