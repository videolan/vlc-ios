//
//  VLCServerBrowsingTVTableViewController.h
//  VLC for iOS
//
//  Created by Tobias Conradi on 27.10.15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VLCNetworkServerBrowser-Protocol.h"
@interface VLCServerBrowsingTVTableViewController : UITableViewController <VLCNetworkServerBrowserDelegate>

- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)serverBrowser;
@end
