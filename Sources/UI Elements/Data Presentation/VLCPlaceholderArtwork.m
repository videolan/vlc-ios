/*****************************************************************************
 * VLCPlaceholderArtwork.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaceholderArtwork.h"

@implementation VLCPlaceholderArtwork

+ (NSString *)initialsForName:(NSString *)name
{
    NSString *trimmed = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0)
        return @"?";

    NSCharacterSet *wordSeparators = [NSCharacterSet characterSetWithCharactersInString:@" -_|/·•"];
    NSArray<NSString *> *components = [trimmed componentsSeparatedByCharactersInSet:wordSeparators];

    NSMutableString *initials = [NSMutableString stringWithCapacity:2];
    for (NSString *word in components) {
        if (word.length == 0)
            continue;
        [initials appendString:[[word substringToIndex:1] uppercaseString]];
        if (initials.length == 2)
            break;
    }

    if (initials.length == 0)
        [initials appendString:[[trimmed substringToIndex:1] uppercaseString]];

    return initials;
}

+ (CGFloat)hueForName:(NSString *)name
{
    NSUInteger hash = 5381;
    for (NSUInteger i = 0; i < name.length; i++) {
        hash = ((hash << 5) + hash) + [name characterAtIndex:i];
    }
    return (CGFloat)(hash % 360) / 360.0;
}

+ (UIColor *)backgroundColorForName:(NSString *)name
{
    if (name.length == 0)
        return [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.55 alpha:1.0];

    return [UIColor colorWithHue:[self hueForName:name] saturation:0.55 brightness:0.62 alpha:1.0];
}

+ (UIColor *)foregroundColorForName:(NSString *)name
{
    return [UIColor whiteColor];
}

+ (UIImage *)placeholderImageForName:(NSString *)name
                                size:(CGSize)size
                        cornerRadius:(CGFloat)cornerRadius
                            fontSize:(CGFloat)fontSize
{
    UIColor *backgroundColor = [self backgroundColorForName:name];
    UIColor *foregroundColor = [self foregroundColorForName:name];
    NSString *initials = [self initialsForName:name];

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        CGRect bounds = CGRectMake(0, 0, size.width, size.height);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:cornerRadius];
        [backgroundColor setFill];
        [path fill];

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSDictionary *attributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightHeavy],
            NSForegroundColorAttributeName: foregroundColor,
            NSParagraphStyleAttributeName: paragraphStyle
        };

        CGSize textSize = [initials sizeWithAttributes:attributes];
        CGRect textRect = CGRectMake(0, (size.height - textSize.height) / 2.0, size.width, textSize.height);
        [initials drawInRect:textRect withAttributes:attributes];
    }];
}

@end
