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

static CGFloat const kVLCPlaceholderArtworkFontSizeRatio = 0.28;

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

    /* The separators cover dots for file names and every dash Unicode knows,
     * as feeds title their shows with all of them. */
    NSCharacterSet *wordSeparators = [NSCharacterSet characterSetWithCharactersInString:@" _|/·•.-‐‑‒–—―"];
    NSMutableArray<NSString *> *words = [NSMutableArray array];
    for (NSString *component in [trimmed componentsSeparatedByCharactersInSet:wordSeparators]) {
        if (component.length > 0)
            [words addObject:component.uppercaseString];
    }

    if (words.count == 0)
        return @"?";

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

+ (CGFloat)fontSizeForSide:(CGFloat)side
{
    return side * kVLCPlaceholderArtworkFontSizeRatio;
}

+ (void)drawPlaceholderForName:(NSString *)name inRect:(CGRect)bounds
{
    UIColor *backgroundColor = [self backgroundColorForName:name];
    UIColor *foregroundColor = [self foregroundColorForName:name];
    NSString *initials = [self initialsForName:name];

    [backgroundColor setFill];
    UIRectFill(bounds);

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    CGFloat fontSize = [self fontSizeForSide:MIN(bounds.size.width, bounds.size.height)];
    NSDictionary *attributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:fontSize weight:UIFontWeightHeavy],
        NSForegroundColorAttributeName: foregroundColor,
        NSParagraphStyleAttributeName: paragraphStyle
    };

    CGSize textSize = [initials sizeWithAttributes:attributes];
    CGRect textRect = CGRectMake(0, (bounds.size.height - textSize.height) / 2.0, bounds.size.width, textSize.height);
    [initials drawInRect:textRect withAttributes:attributes];
}

+ (UIImage *)placeholderImageForName:(NSString *)name pixelSize:(CGFloat)pixelSize
{
    CGRect bounds = CGRectMake(0, 0, pixelSize, pixelSize);
#if TARGET_OS_WATCH
    UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 1.0);
    [self drawPlaceholderForName:name inRect:bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
#else
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
    format.scale = 1.0;
    format.opaque = YES;

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:bounds.size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [self drawPlaceholderForName:name inRect:bounds];
    }];
#endif
}

@end
