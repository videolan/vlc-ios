/*****************************************************************************
 * VLCTransferController.h
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
#import "VLCTransferItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const VLCTransferControllerStateDidChangeNotification;

@class VLCMedia;

@interface VLCTransferController : NSObject

#pragma mark - Download source
- (void)addVLCMediaToDownloadList:(VLCMedia *)media fileNameOfMedia:(nullable NSString *)fileName;
- (void)cancelCurrentDownload;

#pragma mark - Upload source (called by the Wi-Fi sharing HTTP server)
- (NSUInteger)startUploadWithExpectedSize:(long long)expectedSize;
- (void)updateUpload:(NSUInteger)token displayName:(NSString *)name;
- (void)updateUpload:(NSUInteger)token receivedBytes:(long long)received;
- (void)finishUpload:(NSUInteger)token filePath:(nullable NSString *)filePath;
- (void)failUpload:(NSUInteger)token errorDescription:(nullable NSString *)description;
- (void)cancelUpload:(NSUInteger)token;

#pragma mark - List state (view-controller-facing)
@property (readonly) NSArray<VLCTransferItem *> *inProgressItems;
@property (readonly) NSArray<VLCTransferItem *> *completedItems;
@property (readonly) NSArray<VLCTransferItem *> *failedItems;

- (void)cancelInProgressItem:(VLCTransferItem *)item;
- (void)removeFailedItem:(VLCTransferItem *)item;

@end

NS_ASSUME_NONNULL_END
