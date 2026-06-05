/*****************************************************************************
 * VLCTransferItem.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VLCTransferDirection) {
    VLCTransferDirectionDownload,
    VLCTransferDirectionUpload,
};

@interface VLCTransferItem : NSObject

@property (readonly) VLCTransferDirection direction;
@property (readwrite, copy) NSString *displayName;
@property (readonly) BOOL active;
@property (readonly) BOOL sizeKnown;
@property (readonly) CGFloat progress;
@property (readonly) long long receivedBytes;
@property (readonly) long long expectedBytes;
@property (readonly, nullable) NSString *statsText;
@property (readonly, nullable) NSString *errorDescription;
@property (readonly, nullable) NSString *filePath;
@property (readonly, nullable) NSDate *date;
@property (readonly, nullable) NSString *urlString;

+ (instancetype)downloadItemWithName:(NSString *)name;
+ (instancetype)queuedDownloadItemWithName:(NSString *)name urlString:(NSString *)urlString;
+ (instancetype)uploadItemWithExpectedSize:(long long)expectedSize;

+ (NSString *)byteProgressStringForReceived:(long long)received expected:(long long)expected;

- (BOOL)ingestReceivedBytes:(long long)received expectedBytes:(long long)expected;
- (void)markCompletedWithFilePath:(nullable NSString *)filePath;
- (void)markFailedWithError:(NSString *)error;

@end

NS_ASSUME_NONNULL_END
