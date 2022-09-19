//
//  VLCCloudStorageController.m
//  VLC for iOS
//
//  Created by Carola Nitz on 31/12/14.
//  Copyright (c) 2014 VideoLAN. All rights reserved.
//

#import "VLCCloudStorageController.h"

@implementation VLCCloudStorageController

+ (VLCCloudStorageController *)sharedInstance {
    return nil;
}
- (void)startSession
{
    // nop
}
- (void)logout
{
    // nop
}
- (void)requestDirectoryListingAtPath:(NSString *)path
{
    // nop
}
- (BOOL)supportSorting {
    return NO;  //Return NO by default. If a subclass implemented sorting, override this method to return YES
}

- (NSString *)createPotentialPathFrom:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *fileName = [path lastPathComponent];
    NSString *finalFilePath = [path stringByDeletingLastPathComponent];

    if ([fileManager fileExistsAtPath:path]) {
        NSString *potentialFilename;
        NSString *fileExtension = [fileName pathExtension];
        NSString *rawFileName = [fileName stringByDeletingPathExtension];
        for (NSUInteger x = 1; x < 100; x++) {
            potentialFilename = [NSString stringWithFormat:@"%@_%lu.%@", rawFileName, (unsigned long)x, fileExtension];
            if (![fileManager fileExistsAtPath:[finalFilePath stringByAppendingPathComponent:potentialFilename]]) {
                break;
            }
        }
        return [finalFilePath stringByAppendingPathComponent:potentialFilename];
    }
    return path;
}

- (VLCMedia *)setMediaNameMetadata:(VLCMedia *)media withName:(NSString *)name
{
    if (name.length) {
        media.metaData.title = name;
    }
    return media;
}

@end
