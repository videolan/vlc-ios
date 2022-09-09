/*****************************************************************************
 * VLCDownloadController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCMedia;

@protocol VLCDownloadControllerDelegate <NSObject>

@required
- (void)downloadStartedWithDisplayName:(NSString *)displayName;
- (void)downloadEnded;
- (void)downloadFailedWithDescription:(NSString *)description;
- (void)downloadProgressUpdatedWithPercentage:(CGFloat)percentage time:(NSString *)time speed:(NSString *)speed totalSizeKnown:(BOOL)totalSizeKnown;
- (void)listOfScheduledDownloadsChanged;

@end

@interface VLCDownloadController : NSObject

@property (readonly) NSUInteger numberOfScheduledDownloads;
@property (readonly) NSUInteger numberOfCompletedDownloads;
@property (readwrite, weak) id<VLCDownloadControllerDelegate> delegate;

+ (instancetype)sharedInstance;

- (void)addURLToDownloadList:(NSURL *)aURL fileNameOfMedia:(nullable NSString *)fileName;
- (void)addVLCMediaToDownloadList:(VLCMedia *)media fileNameOfMedia:(NSString *)fileName expectedDownloadSize:(long long unsigned)expectedDownloadSize;
- (void)removeScheduledDownloadAtIndex:(NSUInteger)index;
- (void)cancelCurrentDownload;
- (nullable NSString *)displayNameForDownloadAtIndex:(NSUInteger)index;
- (nullable NSString *)urlStringForDownloadAtIndex:(NSUInteger)index;
- (nullable NSString *)displayNameForCompletedDownloadAtIndex:(NSUInteger)index;
- (nullable NSString *)metadataForCompletedDownloadAtIndex:(NSUInteger)index;
- (nullable VLCMedia *)mediaForCompletedDownloadAtIndex:(NSUInteger)index;
- (void)bringDelegateUpToDate;

@end

NS_ASSUME_NONNULL_END
