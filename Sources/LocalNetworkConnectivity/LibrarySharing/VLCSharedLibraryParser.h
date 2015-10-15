/*****************************************************************************
 * VLCSharedLibraryParser.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

extern NSString *const VLCSharedLibraryParserDeterminedNetserviceAsVLCInstance;

@protocol VLCSharedLibraryParserDelegate <NSObject>

@required

- (void)sharedLibraryDataProcessings:(NSArray *)result;

@end

@interface VLCSharedLibraryParser : NSObject

@property (readwrite, weak) id<VLCSharedLibraryParserDelegate> delegate;

- (void)checkNetserviceForVLCService:(NSNetService *)netservice;
- (void)fetchDataFromServer:(NSString *)hostname port:(long)port;

@end
