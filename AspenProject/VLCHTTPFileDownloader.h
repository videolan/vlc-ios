//
//  VLCHTTPFileDownloader.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 20.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

@class VLCMenuViewController;

@interface VLCHTTPFileDownloader : NSObject

@property (nonatomic, retain) VLCMenuViewController *mediaViewController;
@property (nonatomic, readonly) BOOL downloadInProgress;

- (void)downloadFileFromURL:(NSURL *)url;

@end
