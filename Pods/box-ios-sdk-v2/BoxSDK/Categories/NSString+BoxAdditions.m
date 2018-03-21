//
//  NSString+BoxAdditions.m
//  BoxSDK
//
//  Created on 6/3/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

long long const BOX_KILOBYTE = 1024;
long long const BOX_MEGABYTE = BOX_KILOBYTE * 1024;
long long const BOX_GIGABYTE = BOX_MEGABYTE * 1024;
long long const BOX_TERABYTE = BOX_GIGABYTE * 1024;

#import "NSString+BoxAdditions.h"

@implementation NSString (BoxAdditions)

+ (NSString *)box_humanReadableStringForByteSize:(NSNumber *)size
{
    NSString * result_str = nil;
	long long fileSize = [size longLongValue];
    
    if (fileSize >= BOX_TERABYTE) 
    {
        double dSize = fileSize / (double)BOX_TERABYTE;
		result_str = [NSString stringWithFormat:NSLocalizedString(@"%1.1f TB", @"File size in terabytes (example: 1 TB)"), dSize];
    }
	else if (fileSize >= BOX_GIGABYTE)
	{
		double dSize = fileSize / (double)BOX_GIGABYTE;
		result_str = [NSString stringWithFormat:NSLocalizedString(@"%1.1f GB", @"File size in gigabytes (example: 1 GB)"), dSize];
	}
	else if (fileSize >= BOX_MEGABYTE)
	{
		double dSize = fileSize / (double)BOX_MEGABYTE;
		result_str = [NSString stringWithFormat:NSLocalizedString(@"%1.1f MB", @"File size in megabytes (example: 1 MB)"), dSize];
	}
	else if (fileSize >= BOX_KILOBYTE)
	{
		double dSize = fileSize / (double)BOX_KILOBYTE;
		result_str = [NSString stringWithFormat:NSLocalizedString(@"%1.1f KB", @"File size in kilobytes (example: 1 KB)"), dSize];
	}
    else if(fileSize > 0)
    {
        result_str = [NSString stringWithFormat:NSLocalizedString(@"%1.1f B", @"File size in bytes (example: 1 B)"), fileSize];
    }
	else
	{
		result_str = NSLocalizedString(@"Empty", @"File size 0 bytes");
	}
    
    return result_str;
}

@end
