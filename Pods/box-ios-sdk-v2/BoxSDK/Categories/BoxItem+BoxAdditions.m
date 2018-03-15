//
//  BoxItem+BoxAdditions.m
//  BoxSDK
//
//  Created on 6/4/13.
//  Copyright (c) 2013 Box. All rights reserved.
//
//  NOTE: this file is a mirror of BoxCocoaSDK/Categories/BoxItem+BoxCocoaAdditions.m. Changes made here should be reflected there.
//

#import "BoxItem+BoxAdditions.h"
#import "UIImage+BoxAdditions.h"
#import "BoxFolder.h"

@implementation BoxItem (BoxAdditions)

- (UIImage *)icon
{
    UIImage *icon = nil;

    
    if ([self isKindOfClass:[BoxFolder class]])
    {
        icon = [UIImage imageFromBoxSDKResourcesBundleWithName:@"icon-folder"];
        return icon;
    }
    
    NSString *extension = [[self.name pathExtension] lowercaseString];
    
    if ([extension isEqualToString:@"docx"]) 
    {
        extension = @"doc";
    }
    if ([extension isEqualToString:@"pptx"]) 
    {
        extension = @"ppt";
    }
    if ([extension isEqualToString:@"xlsx"]) 
    {
        extension = @"xls";
    }
    if ([extension isEqualToString:@"html"]) 
    {
        extension = @"htm";
    }
    if ([extension isEqualToString:@"jpeg"])
    {
        extension = @"jpg";
    }
    
    NSString *str = [NSString stringWithFormat:@"icon-file-%@", extension];
    icon = [UIImage  imageFromBoxSDKResourcesBundleWithName:str];
    
    if (!icon)
    {
        icon = [UIImage  imageFromBoxSDKResourcesBundleWithName:@"icon-file-generic"];
    }
    
    return icon;
}

@end
