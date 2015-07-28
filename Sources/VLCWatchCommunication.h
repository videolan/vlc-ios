/*****************************************************************************
 * VLCWatchCommunication.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface VLCWatchCommunication : NSObject <WCSessionDelegate>

+ (instancetype)sharedInstance;

@end
