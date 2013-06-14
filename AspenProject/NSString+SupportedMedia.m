//
//  NSString+SupportedMedia.m
//  VLC for iOS
//
//  Created by Gleb on 6/1/13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "NSString+SupportedMedia.h"

@implementation NSString (SupportedMedia)

- (BOOL)isSupportedMediaFormat
{
    NSUInteger options = NSRegularExpressionSearch | NSCaseInsensitiveSearch;
    return ([self rangeOfString:kSupportedFileExtensions options:options].location != NSNotFound);
}

- (BOOL)isSupportedSubtitleFormat
{
    NSUInteger options = NSRegularExpressionSearch | NSCaseInsensitiveSearch;
    return ([self rangeOfString:kSupportedSubtitleFileExtensions options:options].location != NSNotFound);
}

@end
