/*****************************************************************************
 * MLFileEntityMappingPolicy_2_5_to_2_6.m
 * MobileMediaLibraryKit
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "MLFileEntityMappingPolicy_2_5_to_2_6.h"

@implementation MLFileEntityMappingPolicy_2_5_to_2_6
- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    NSString *fullPath = [sInstance primitiveValueForKey:@"url"];
    NSString *relativePath = [self relativePathForFullPath:fullPath];
    if (relativePath) {
        [sInstance setPrimitiveValue:relativePath forKey:@"url"];
    }
    BOOL success = [super createDestinationInstancesForSourceInstance:sInstance entityMapping:mapping manager:manager error:error];
    return success;
}

- (NSString *)relativePathForFullPath:(NSString *)fullPath
{
    NSArray *components = [fullPath componentsSeparatedByString:@"Documents"];
    return [components.lastObject stringByRemovingPercentEncoding];
}

@end
