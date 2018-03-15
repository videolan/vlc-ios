/*****************************************************************************
 * MLThumbnailerQueue.m
 * MobileMediaLibraryKit
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2015 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "MLThumbnailerQueue.h"
#import "MLFile.h"
#import "MLCrashPreventer.h"
#import "MLMediaLibrary.h"
#import "MLFileParserQueue.h"
#import "UIImage+MLKit.h"
#import <CommonCrypto/CommonDigest.h>

#ifdef MLKIT_READONLY_TARGET

@implementation MLThumbnailerQueue

+ (MLThumbnailerQueue *)sharedThumbnailerQueue
{
    static MLThumbnailerQueue *shared = nil;
    if (!shared) {
        shared = [[MLThumbnailerQueue alloc] init];
    }
    return shared;
}

- (void)addFile:(MLFile *)file
{
}

- (void)setHighPriorityForFile:(MLFile *)file
{
}

- (void)setDefaultPriorityForFile:(MLFile *)file
{
}

- (void)stop
{
}

- (void)resume
{
}

@end

#else

@interface ThumbnailOperation : NSOperation <VLCMediaThumbnailerDelegate>
{
    MLFile *_file;
    VLCMedia *_media;;
    dispatch_semaphore_t _thumbnailingSema;
}
@property (strong,readwrite) MLFile *file;
@end

@interface MLThumbnailerQueue ()
{
    NSDictionary *_fileDescriptionToOperation;
    NSOperationQueue *_queue;
}
- (void)didFinishOperation:(ThumbnailOperation *)op;
@end

@implementation ThumbnailOperation
@synthesize file=_file;
- (id)initWithFile:(MLFile *)file
{
    if (!(self = [super init]))
        return nil;
    self.file = file;
    return self;
}

- (void)fetchThumbnail
{
    APLog(@"Starting THUMB %@", self.file);

    [[MLCrashPreventer sharedPreventer] willParseFile:self.file];

    _media = [VLCMedia mediaWithURL:self.file.url];
    VLCMediaThumbnailer *thumbnailer = [VLCMediaThumbnailer thumbnailerWithMedia:_media delegate:self andVLCLibrary:[VLCLibrary sharedLibrary]];
    MLThumbnailerQueue *thumbnailerQueue = [MLThumbnailerQueue sharedThumbnailerQueue];

    CGSize thumbSize = [UIImage preferredThumbnailSizeForDevice];
    CGFloat scale = [UIScreen mainScreen].scale;
    thumbnailer.thumbnailWidth = thumbSize.width*scale;
    thumbnailer.thumbnailHeight = thumbSize.height*scale;
    [thumbnailer fetchThumbnail];
    [thumbnailerQueue.queue setSuspended:YES]; // Balanced in -mediaThumbnailer:didFinishThumbnail
     // Balanced in -mediaThumbnailer:didFinishThumbnail:
}
- (void)main
{
    _thumbnailingSema = dispatch_semaphore_create(0);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchThumbnail];
    });

    dispatch_semaphore_wait(_thumbnailingSema, DISPATCH_TIME_FOREVER);
}

- (void)endThumbnailing
{
    [[MLCrashPreventer sharedPreventer] didParseFile:self.file];
    MLThumbnailerQueue *thumbnailerQueue = [MLThumbnailerQueue sharedThumbnailerQueue];
    [thumbnailerQueue.queue setSuspended:NO];
    [thumbnailerQueue didFinishOperation:self];
    dispatch_semaphore_signal(_thumbnailingSema);
}

- (void)mediaThumbnailer:(VLCMediaThumbnailer *)mediaThumbnailer didFinishThumbnail:(CGImageRef)thumbnail
{
    mediaThumbnailer.delegate = nil;
    MLFile *file = self.file;
    APLog(@"Finished thumbnail for %@", file.title);
    if (thumbnail) {
        UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnail scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        if (thumbnailImage) {
            file.computedThumbnail = [UIImage imageWithCGImage:thumbnail];
#if TARGET_OS_IOS
            if ([[MLMediaLibrary sharedMediaLibrary] isSpotlightIndexingEnabled]) {
                [file updateCoreSpotlightEntry];
            }
#endif
        }
    }

    [self endThumbnailing];
}

- (void)mediaThumbnailerDidTimeOut:(VLCMediaThumbnailer *)mediaThumbnailer
{
    self.file.thumbnailTimeouted = YES;
    [self endThumbnailing];
}
@end

@implementation MLThumbnailerQueue
@synthesize queue=_queue;
+ (MLThumbnailerQueue *)sharedThumbnailerQueue
{
    static MLThumbnailerQueue *shared = nil;
    if (!shared) {
        shared = [[MLThumbnailerQueue alloc] init];
    }
    return shared;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        _fileDescriptionToOperation = [[NSMutableDictionary alloc] init];
        _queue = [[NSOperationQueue alloc] init];
        [_queue setMaxConcurrentOperationCount:1];
    }
    return self;
}

static inline NSString *hashFromFile(MLFile *file)
{
    NSString *path = [[[file objectID] URIRepresentation] absoluteString];
    const char *cstr = [path cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:path.length];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);

    NSMutableString *sha1Hash = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [sha1Hash appendFormat:@"%02x", digest[i]];

    return sha1Hash;
}

- (void)didFinishOperation:(ThumbnailOperation *)op
{
    [_fileDescriptionToOperation setValue:nil forKey:hashFromFile(op.file)];
}

- (void)addFile:(MLFile *)file
{
    if (_fileDescriptionToOperation[hashFromFile(file)])
        return;
    if (![[MLCrashPreventer sharedPreventer] isFileSafe:file]) {
        APLog(@"'%@' is unsafe and will crash, ignoring", file.title);
        return;
    }

    if (file.albumTrack) {
        APLog(@"'%@' is part of a music album, ignoring", file.title);
        return;
    }

    if ([file isKindOfType:kMLFileTypeAudio]) {
        APLog(@"'%@' is an audio file, ignoring", file.title);
        return;
    }

    if (file.hasFetchedInfo.boolValue != YES) {
        APLog(@"'%@' still awaits parsing, ignoring", file.title);
        [[MLFileParserQueue sharedFileParserQueue] addFile:file];
        return;
    }

    ThumbnailOperation *op = [[ThumbnailOperation alloc] initWithFile:file];
    [_fileDescriptionToOperation setValue:op forKey:hashFromFile(file)];
    [self.queue addOperation:op];
}

- (void)stop
{
    [_queue setMaxConcurrentOperationCount:0];
}

- (void)resume
{
    [_queue setMaxConcurrentOperationCount:1];
}

- (void)setHighPriorityForFile:(MLFile *)file
{
    ThumbnailOperation *op = _fileDescriptionToOperation[hashFromFile(file)];
    [op setQueuePriority:NSOperationQueuePriorityHigh];
}

- (void)setDefaultPriorityForFile:(MLFile *)file
{
    ThumbnailOperation *op = _fileDescriptionToOperation[hashFromFile(file)];
    [op setQueuePriority:NSOperationQueuePriorityNormal];
}

@end

#endif
