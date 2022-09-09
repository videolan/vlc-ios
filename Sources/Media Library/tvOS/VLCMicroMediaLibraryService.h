/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCMicroMediaLibraryService;

@protocol VLCMicroMediaLibraryServiceDelegate <NSObject>

@required
- (void)mediaListUpdatedForService:(VLCMicroMediaLibraryService *)service;

@end

@interface VLCMicroMediaLibraryService : NSObject

+ (instancetype)sharedInstance;

@property (readwrite, weak) id<VLCMicroMediaLibraryServiceDelegate> delegate;
@property (readonly) NSInteger numberOfDiscoveredMedia;
@property (readonly, copy) VLCMediaList *mediaList;
@property (readonly, copy) NSArray *rawListOfFiles;

- (void)updateMediaList;
- (NSString *)filenameOfItemAtIndex:(NSInteger)index;
- (void)deleteFileAtIndex:(NSInteger)index;

- (NSURL *)thumbnailURLForItemAtIndex:(NSInteger)index;
- (NSURL *)thumbnailURLForItemWithPath:(NSString *)path;
- (NSString *)titleForItemAtIndex:(NSInteger)index;
- (UIImage *)placeholderImageForItemWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
