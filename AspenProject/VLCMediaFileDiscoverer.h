//
//  VLCMediaFileDiscoverer.h
//  VLC for iOS
//
//  Created by Gleb on 7/27/13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VLCMediaFileDiscovererDelegate <NSObject>

@optional
- (void)mediaFileAdded:(NSString *)fileName loading:(BOOL)isLoading;
- (void)mediaFileChanged:(NSString *)fileName size:(unsigned long long)size;
- (void)mediaFileDeleted:(NSString *)name;

@end

@interface VLCMediaFileDiscoverer : NSObject

- (void)addObserver:(id<VLCMediaFileDiscovererDelegate>)delegate;
- (void)removeObserver:(id<VLCMediaFileDiscovererDelegate>)delegate;

- (void)startDiscovering:(NSString *)directoryPath;
- (void)stopDiscovering;

+ (instancetype)sharedInstance;

@end
