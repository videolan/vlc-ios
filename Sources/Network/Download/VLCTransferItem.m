/*****************************************************************************
 * VLCTransferItem.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCTransferItem.h"

@interface VLCTransferItem ()
{
    NSMutableArray<NSNumber *> *_lastSpeeds;
    long long _lastReceivedSnapshot;
    NSTimeInterval _lastStatsUpdate;
}

@property (readwrite) VLCTransferDirection direction;
@property (readwrite) BOOL active;
@property (readwrite) BOOL sizeKnown;
@property (readwrite) CGFloat progress;
@property (readwrite) long long receivedBytes;
@property (readwrite) long long expectedBytes;
@property (readwrite, nullable) NSString *bytesString;
@property (readwrite, nullable) NSString *speedString;
@property (readwrite, nullable) NSString *timeString;
@property (readwrite, nullable) NSString *errorDescription;
@property (readwrite, nullable) NSString *filePath;
@property (readwrite, nullable) NSDate *date;
@property (readwrite, nullable) NSString *urlString;

@end

@implementation VLCTransferItem

+ (NSByteCountFormatter *)byteFormatter
{
    static NSByteCountFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSByteCountFormatter alloc] init];
        formatter.countStyle = NSByteCountFormatterCountStyleFile;
        formatter.allowsNonnumericFormatting = NO;
    });
    return formatter;
}

+ (NSDateFormatter *)remainingTimeFormatter
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss";
        formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });
    return formatter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lastSpeeds = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (instancetype)downloadItemWithName:(NSString *)name
{
    VLCTransferItem *item = [[VLCTransferItem alloc] init];
    item.direction = VLCTransferDirectionDownload;
    item.displayName = name ?: @"";
    item.active = YES;
    return item;
}

+ (instancetype)queuedDownloadItemWithName:(NSString *)name urlString:(NSString *)urlString
{
    VLCTransferItem *item = [[VLCTransferItem alloc] init];
    item.direction = VLCTransferDirectionDownload;
    item.displayName = name ?: @"";
    item.active = NO;
    item.urlString = urlString;
    return item;
}

+ (instancetype)uploadItemWithExpectedSize:(long long)expectedSize
{
    VLCTransferItem *item = [[VLCTransferItem alloc] init];
    item.direction = VLCTransferDirectionUpload;
    item.displayName = @"";
    item.active = YES;
    item.expectedBytes = expectedSize;
    item.sizeKnown = expectedSize > 0;
    return item;
}

#pragma mark - progress / speed estimation

- (CGFloat)averageSpeed:(CGFloat)speed
{
    [_lastSpeeds addObject:@(speed)];
    if (_lastSpeeds.count > 10) {
        [_lastSpeeds removeObjectAtIndex:0];
    }
    CGFloat sum = 0;
    for (NSNumber *value in _lastSpeeds) {
        sum += value.floatValue;
    }
    return _lastSpeeds.count > 0 ? sum / _lastSpeeds.count : 0;
}

- (NSString *)speedStringForSpeed:(CGFloat)speed
{
    NSString *string = [NSByteCountFormatter stringFromByteCount:(long long)speed
                                                      countStyle:NSByteCountFormatterCountStyleDecimal];
    return [string stringByAppendingString:@"/s"];
}

- (NSString *)remainingTimeStringForSpeed:(CGFloat)speed
{
    if (self.expectedBytes <= 0 || speed <= 0) {
        return @"--:--";
    }
    CGFloat remainingInSeconds = (self.expectedBytes - self.receivedBytes) / speed;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:remainingInSeconds];
    return [[VLCTransferItem remainingTimeFormatter] stringFromDate:date];
}

+ (NSString *)byteProgressStringForReceived:(long long)received expected:(long long)expected
{
    NSByteCountFormatter *formatter = [VLCTransferItem byteFormatter];
    NSString *receivedString = [formatter stringFromByteCount:received];
    if (expected > 0) {
        return [NSString stringWithFormat:@"%@ / %@", receivedString, [formatter stringFromByteCount:expected]];
    }
    return receivedString;
}

- (NSString *)formattedBytes
{
    return [VLCTransferItem byteProgressStringForReceived:self.receivedBytes expected:self.expectedBytes];
}

- (BOOL)ingestReceivedBytes:(long long)received expectedBytes:(long long)expected
{
    self.receivedBytes = received;
    self.expectedBytes = expected;
    self.sizeKnown = expected > 0;
    self.progress = expected > 0 ? fmin(fmax((CGFloat)received / (CGFloat)expected, 0.0), 1.0) : 0.0;
    self.bytesString = [self formattedBytes];

    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (_lastStatsUpdate <= 0) {
        _lastStatsUpdate = now;
        _lastReceivedSnapshot = received;
        return YES;
    }
    NSTimeInterval delta = now - _lastStatsUpdate;
    if (delta < 0.5) {
        return NO;
    }
    CGFloat instantSpeed = (received - _lastReceivedSnapshot) / delta;
    CGFloat averageSpeed = [self averageSpeed:instantSpeed];
    self.speedString = [self speedStringForSpeed:averageSpeed];
    self.timeString = [self remainingTimeStringForSpeed:averageSpeed];
    _lastStatsUpdate = now;
    _lastReceivedSnapshot = received;
    return YES;
}

- (NSString *)statsText
{
    if (!self.sizeKnown) {
        return self.bytesString.length > 0 ? self.bytesString : NSLocalizedString(@"TRANSFERS_IN_PROGRESS", nil);
    }
    NSString *bytes = self.bytesString ?: @"";
    NSString *speed = self.speedString ?: @"";
    NSString *time = self.timeString ?: @"";
    return [NSString stringWithFormat:@"%@\n%@ • %@", bytes, speed, time];
}

- (void)markCompletedWithFilePath:(NSString *)filePath
{
    self.active = NO;
    self.progress = 1.0;
    self.filePath = filePath;
    self.date = [NSDate date];
}

- (void)markFailedWithError:(NSString *)error
{
    self.active = NO;
    self.errorDescription = error;
}

@end
