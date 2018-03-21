/*****************************************************************************
 * MLCrashPreventer.m
 * MobileMediaLibraryKit
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2013 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
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

#import "MLCrashPreventer.h"
#import "MLThumbnailerQueue.h"
#import "MLFileParserQueue.h"
#import "MLCrashPreventer.h"
#import "MLFile.h"
#import "MLMediaLibrary.h"

@interface MLCrashPreventer ()
{
    NSMutableArray *_parsedFiles;
}
@end

@implementation MLCrashPreventer
+ (id)sharedPreventer
{
    static MLCrashPreventer *crashPreventer;
    if (!crashPreventer)
        crashPreventer = [[MLCrashPreventer alloc] init];

    // Use the same queue for the two objects, because we wan't to track accurately
    // which operation causes a crash.
    [MLThumbnailerQueue sharedThumbnailerQueue].queue = [MLFileParserQueue sharedFileParserQueue].queue;

    return crashPreventer;
}

- (id)init
{
    self = [super init];
    if (self)
        _parsedFiles = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc
{
    NSAssert([_parsedFiles count] == 0, @"You should call -cancelAllFileParse before releasing");
}

- (BOOL)fileParsingInProgress
{
    return _parsedFiles.count > 0;
}

- (void)cancelAllFileParse
{
    APLog(@"Cancelling file parsing");
    for (MLFile *file in _parsedFiles)
        file.isBeingParsed = NO;
    [_parsedFiles removeAllObjects];
    [[MLMediaLibrary sharedMediaLibrary] save];
}

- (void)markCrasherFiles
{
    for (MLFile *file in [MLFile allFiles]) {
        if ([file isBeingParsed]) {
            file.isSafe = NO;
            file.isBeingParsed = NO;
        }
    }
    [[MLMediaLibrary sharedMediaLibrary] save];
}

- (BOOL)isFileSafe:(MLFile *)file
{
    return file.isSafe;
}

- (void)willParseFile:(MLFile *)file
{
    NSAssert([MLThumbnailerQueue sharedThumbnailerQueue].queue == [MLFileParserQueue sharedFileParserQueue].queue, @"");

    NSAssert([_parsedFiles count] < 1, @"Parsing multiple files at the same time. Crash preventer can't work accurately.");
    file.isBeingParsed = YES;

    // Force to save the media library in case of crash.
    [[MLMediaLibrary sharedMediaLibrary] save];

    [_parsedFiles addObject:file];
}

- (void)didParseFile:(MLFile *)file
{
    file.isBeingParsed = NO;
    [_parsedFiles removeObject:file];
}

@end
