/*****************************************************************************
 * UIDevice+VLC
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "UIDevice+VLC.h"
#import <sys/sysctl.h> // for sysctlbyname
#import <sys/utsname.h>

@implementation UIDevice (VLC)

- (NSNumber *)VLCFreeDiskSpace
{
    NSNumber *totalSpace;
    NSNumber *totalFreeSpace;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];

    if (!error) {
        totalSpace = [dictionary objectForKey:NSFileSystemSize];
        totalFreeSpace = [dictionary objectForKey:NSFileSystemFreeSize];
        NSString *totalSize = [NSByteCountFormatter stringFromByteCount:[totalSpace longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
        NSString *totalFreeSize = [NSByteCountFormatter stringFromByteCount:[totalFreeSpace longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
        APLog(@"Memory Capacity of %@ with %@ Free memory available.", totalSize, totalFreeSize);
    } else
        APLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);

    return totalFreeSpace;
}

- (BOOL)VLCHasExternalDisplay
{
    return ([[UIScreen screens] count] > 1);
}

- (BOOL)isiPhoneX
{
    static BOOL isiPhoneX = NO;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
#if TARGET_IPHONE_SIMULATOR
        NSString *model = NSProcessInfo.processInfo.environment[@"SIMULATOR_MODEL_IDENTIFIER"];
#else
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *model = [NSString stringWithCString:systemInfo.machine
                                             encoding:NSUTF8StringEncoding];
#endif
        isiPhoneX = [model isEqualToString:@"iPhone10,3"] || [model isEqualToString:@"iPhone10,6"];
    });

    return isiPhoneX;
}
@end
