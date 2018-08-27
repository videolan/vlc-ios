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
- (void)mediaFilesFoundRequiringAdditionToStorageBackend:(NSArray <NSString *> *)foundFiles;
// loading is equal to YES first time when file is discovered
- (void)mediaFileAdded:(NSString *)filePath loading:(BOOL)isLoading;

- (void)mediaFileChanged:(NSString *)filePath size:(unsigned long long)size;
- (void)mediaFileDeleted:(NSString *)filePath;

@end

@interface VLCMediaFileDiscoverer : NSObject

/**
 * the path the discoverer will monitor
 * \note _MUST_ be set before starting the discovery
 */
@property (readwrite, retain, nonatomic) NSString *directoryPath;
@property (readwrite, nonatomic) BOOL filterResultsForPlayability;

- (void)addObserver:(id<VLCMediaFileDiscovererDelegate>)delegate;
- (void)removeObserver:(id<VLCMediaFileDiscovererDelegate>)delegate;

- (void)startDiscovering;
- (void)stopDiscovering;

- (void)updateMediaList;

+ (instancetype)sharedInstance;

@end
