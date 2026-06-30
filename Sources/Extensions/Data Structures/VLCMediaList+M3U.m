/*****************************************************************************
 * VLCMediaList+M3U.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCMediaList+M3U.h"

@implementation VLCMediaList (M3U)

- (BOOL)writeM3UToURL:(NSURL *)fileURL
                error:(NSError * _Nullable * _Nullable)error
{
    return [self writeM3UToURL:fileURL relativeToDirectory:nil error:error];
}

- (BOOL)writeM3UToURL:(NSURL *)fileURL
  relativeToDirectory:(NSURL *)baseDirectory
                error:(NSError * _Nullable * _Nullable)error
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *destinationPath = fileURL.path;

    if (![fileManager createFileAtPath:destinationPath contents:[NSData data] attributes:nil]) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSFileWriteUnknownError
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create M3U file"}];
        }
        return NO;
    }

    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:destinationPath];
    if (handle == nil) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSFileWriteUnknownError
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to open M3U file for writing"}];
        }
        return NO;
    }

    BOOL success = YES;

    // exception handling as writeData:error: is iOS 13+ only
    NSException *caught = nil;
    [self lock];
    @try {
        [handle writeData:[@"#EXTM3U\n" dataUsingEncoding:NSUTF8StringEncoding]];

        NSInteger count = self.count;
        for (NSInteger i = 0; i < count; i++) {
            VLCMedia *media = [self mediaAtIndex:i];
            NSURL *url = media.url;
            if (url == nil) {
                continue;
            }

            NSString *title = media.metaData.title;
            if (title.length == 0) {
                title = [[url.absoluteString stringByRemovingPercentEncoding] lastPathComponent];
            }
            if (title.length == 0) {
                title = url.absoluteString;
            }

            NSString *sanitizedTitle = [[title componentsSeparatedByCharactersInSet:NSCharacterSet.controlCharacterSet] componentsJoinedByString:@" "];

            NSString *location = url.absoluteString;
            if (baseDirectory != nil && url.isFileURL) {
                NSString *basePath = baseDirectory.path;
                NSString *filePath = url.path;
                if ([filePath hasPrefix:basePath]) {
                    NSString *relativePath = [filePath substringFromIndex:basePath.length];
                    if ([relativePath hasPrefix:@"/"]) {
                        relativePath = [relativePath substringFromIndex:1];
                    }
                    location = relativePath;
                }
            }

            NSString *entry = [NSString stringWithFormat:@"#EXTINF:-1,%@\n%@\n", sanitizedTitle, location];
            [handle writeData:[entry dataUsingEncoding:NSUTF8StringEncoding]];
        }
    } @catch (NSException *exception) {
        caught = exception;
        success = NO;
    } @finally {
        [self unlock];
    }

    [handle closeFile];

    if (!success && error) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                     code:NSFileWriteUnknownError
                                 userInfo:@{NSLocalizedDescriptionKey: caught.reason ?: @"M3U write failed"}];
    }

    return success;
}

@end
