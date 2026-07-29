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

+ (NSString *)leadingCharacters:(NSUInteger)count ofString:(NSString *)string
{
    NSRange range = NSMakeRange(0, 0);
    while (count > 0 && NSMaxRange(range) < string.length) {
        range.length += [string rangeOfComposedCharacterSequenceAtIndex:NSMaxRange(range)].length;
        count--;
    }

    return [string substringWithRange:range];
}

+ (NSString *)initialsForName:(NSString *)name
{
    NSString *trimmed = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0)
        return @"?";

    NSCharacterSet *wordSeparators = [NSCharacterSet characterSetWithCharactersInString:@" -_|/·•"];
    NSMutableArray<NSString *> *words = [NSMutableArray array];
    for (NSString *component in [trimmed componentsSeparatedByCharactersInSet:wordSeparators]) {
        if (component.length > 0)
            [words addObject:component.uppercaseString];
    }

    if (words.count == 0)
        return [self leadingCharacters:1 ofString:trimmed.uppercaseString];

    if (words.count == 1)
        return [self leadingCharacters:2 ofString:words.firstObject];

    NSMutableString *initials = [NSMutableString stringWithCapacity:2];
    for (NSUInteger index = 0; index < MIN(words.count, 2); index++) {
        [initials appendString:[self leadingCharacters:1 ofString:words[index]]];
    }

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
