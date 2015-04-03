//
//  VLCBaseInterfaceController.m
//
//
//  Created by Tobias Conradi on 03.04.15.
//
//

#import "VLCBaseInterfaceController.h"

@implementation VLCBaseInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    [self addMenuItemWithItemIcon:WKMenuItemIconMore title:@"currently playing" action:@selector(showNowPlaying:)];
}

- (void)showNowPlaying:(id)sender {
    [self presentControllerWithName:@"nowPlaying" context:nil];
}

@end
