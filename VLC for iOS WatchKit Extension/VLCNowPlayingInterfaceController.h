//
//  VLCNowPlayingInterfaceController.h
//  VLC for iOS
//
//  Created by Tobias Conradi on 02.04.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface VLCNowPlayingInterfaceController : WKInterfaceController
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *durationLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *playPauseButton;

- (IBAction)playPausePressed;
- (IBAction)skipForward;
- (IBAction)skipBackward;


@end
