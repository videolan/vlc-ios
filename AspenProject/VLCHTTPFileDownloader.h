//
//  VLCHTTPFileDownloader.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 20.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

@protocol VLCHTTPFileDownloader <NSObject>
@required
- (void)downloadStarted;
- (void)downloadEnded;

@optional
- (void)downloadFailedWithErrorDescription:(NSString *)description;
- (void)progressUpdatedTo:(CGFloat)percentage;

@end

@interface VLCHTTPFileDownloader : NSObject

@property (readonly, nonatomic) NSString *userReadableDownloadName;

@property (nonatomic, readonly) BOOL downloadInProgress;
@property (nonatomic, retain) id delegate;

- (void)cancelDownload;
- (void)downloadFileFromURL:(NSURL *)url;

@end
