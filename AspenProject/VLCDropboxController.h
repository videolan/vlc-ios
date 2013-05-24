//
//  VLCDropboxController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 23.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>

@protocol VLCDropboxController
@required
- (void)mediaListUpdated;

@end

@interface VLCDropboxController : NSObject <DBRestClientDelegate, DBSessionDelegate, DBNetworkRequestDelegate>

@property (nonatomic, retain) id delegate;
@property (nonatomic, readonly) NSArray *currentListFiles;
@property (nonatomic, readonly) BOOL sessionIsLinked;

- (void)startSession;
- (void)logout;

- (void)requestDirectoryListingAtPath:(NSString *)path;
- (void)downloadFileToDocumentFolder:(DBMetadata *)file;

@end
