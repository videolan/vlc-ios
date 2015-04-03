//
//  VLCDetailInterfaceController.h
//  VLC for iOS
//
//  Created by Tobias Conradi on 03.04.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "VLCBaseInterfaceController.h"

@interface VLCDetailInterfaceController : VLCBaseInterfaceController
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *durationLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *playNowButton;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *imageView;

- (IBAction)playNow;
@end
