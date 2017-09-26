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

@implementation UIDevice (VLC)

VLCSpeedCategory _currentSpeedCategory;

- (VLCSpeedCategory)vlcSpeedCategory
{
    if (_currentSpeedCategory == VLCSpeedCategoryNotSet) {
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);

        char *answer = malloc(size);
        sysctlbyname("hw.machine", answer, &size, NULL, 0);

        NSString *currentMachine = @(answer);
        free(answer);

        if ([currentMachine hasPrefix:@"iPhone4"] || [currentMachine hasPrefix:@"iPad3,1"] || [currentMachine hasPrefix:@"iPad3,2"] || [currentMachine hasPrefix:@"iPad3,3"] || [currentMachine hasPrefix:@"iPod4"] || [currentMachine hasPrefix:@"iPad2"] || [currentMachine hasPrefix:@"iPod5"]) {
            APLog(@"this is a cat two device");
            _currentSpeedCategory = VLCSpeedCategoryTwoDevices;
        } else if ([currentMachine hasPrefix:@"iPhone5"] || [currentMachine hasPrefix:@"iPhone6"] || [currentMachine hasPrefix:@"iPad4"]) {
            APLog(@"this is a cat three device");
            _currentSpeedCategory = VLCSpeedCategoryThreeDevices;
        } else {
            APLog(@"this is a cat four device");
            _currentSpeedCategory = VLCSpeedCategoryFourDevices;
        }
    }
    return _currentSpeedCategory;
}

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

@end
