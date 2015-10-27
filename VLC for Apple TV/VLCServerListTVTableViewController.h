//
//  VLCServerListTableViewController.h
//  VLC for iOS
//
//  Created by Tobias Conradi on 27.10.15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VLCLocalServerDiscoveryController.h"
@interface VLCServerListTVTableViewController : UITableViewController <VLCLocalServerDiscoveryControllerDelegate>
@property (nonatomic) VLCLocalServerDiscoveryController *discoveryController;
@end
