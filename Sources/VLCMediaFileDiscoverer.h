/*****************************************************************************
 * VLCMediaFileDiscoverer.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

@protocol VLCMediaFileDiscovererDelegate <NSObject>

@optional
// loading is equal to YES first time when file is discovered
- (void)mediaFileAdded:(NSString *)filePath loading:(BOOL)isLoading;

- (void)mediaFileChanged:(NSString *)filePath size:(unsigned long long)size;
- (void)mediaFileDeleted:(NSString *)filePath;

@end

@interface VLCMediaFileDiscoverer : NSObject

- (void)addObserver:(id<VLCMediaFileDiscovererDelegate>)delegate;
- (void)removeObserver:(id<VLCMediaFileDiscovererDelegate>)delegate;

- (void)startDiscovering:(NSString *)directoryPath;
- (void)stopDiscovering;

+ (instancetype)sharedInstance;

@end
