//
//  VLCBugreporter.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 21.07.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

@interface VLCBugreporter : NSObject

+ (VLCBugreporter *)sharedInstance;

- (void)handleBugreportRequest;

@end
