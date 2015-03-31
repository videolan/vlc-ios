//
//  VLCRowController.h
//  VLC for iOS
//
//  Created by Tobias Conradi on 31.03.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import <WatchKit/WatchKit.h>
@interface VLCRowController : NSObject
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *titleLabel;
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *durationLabel;
@property (nonatomic, weak) IBOutlet WKInterfaceGroup *group;
@end
