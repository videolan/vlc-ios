/*****************************************************************************
 * MLTitleDecrapifier.m
 * Lunettes
 *****************************************************************************
 * Copyright (C) 2010 Pierre d'Herbemont
 * Copyright (C) 2010-2013 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "MLTitleDecrapifier.h"

#ifdef MLKIT_READONLY_TARGET

@implementation MLTitleDecrapifier

+ (NSString *)decrapify:(NSString *)string;
{
    return @"";
}

+ (BOOL)isTVShowEpisodeTitle:(NSString *)string
{
    return NO;
}

+ (NSDictionary *)tvShowEpisodeInfoFromString:(NSString *)string
{
    return @{};
}

+ (NSDictionary *)audioContentInfoFromFile:(MLFile *)file
{
    return @{};
}

@end

#else

@implementation MLTitleDecrapifier
+ (NSString *)decrapify:(NSString *)string
{
    if (string == nil)
        return nil;

    static NSArray *ignoredWords = nil;
    if (!ignoredWords)
        ignoredWords = [[NSArray alloc] initWithObjects:
                        @"xvid", @"h264", @"dvd", @"rip", @"divx", @"[fr]", @"720p", @"1080i", @"1080p", @"x264", @"hdtv", @"aac", @"bluray", nil];

    NSMutableString *mutableString = [NSMutableString stringWithString:string];
    for (NSString *word in ignoredWords)
        [mutableString replaceOccurrencesOfString:word withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];
    [mutableString replaceOccurrencesOfString:@"." withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];
    [mutableString replaceOccurrencesOfString:@"_" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];
    [mutableString replaceOccurrencesOfString:@"+" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];
    [mutableString replaceOccurrencesOfString:@"-" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];
    [mutableString replaceOccurrencesOfString:@"[]" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];
    [mutableString replaceOccurrencesOfString:@"()" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];

    NSString *staticString = [NSString stringWithString:mutableString];
    mutableString = nil;

    while ([staticString rangeOfString:@"  "].location != NSNotFound)
        staticString = [staticString stringByReplacingOccurrencesOfString:@"  " withString:@" "];

    if (staticString.length > 2) {
        @try {
            if ([staticString characterAtIndex:0] == 0x20)
                staticString = [staticString substringFromIndex:1];
        }
        @catch (NSException *exception) {
        }
    }

    return staticString;
}

static inline BOOL isDigit(char c)
{
    return c >= '0' && c <= '9';
}

// Shortcut to ease reading
static inline unichar c(NSString *string, unsigned index)
{
    @try {
        return [string characterAtIndex:index];
    }
    @catch (NSException *exception) {
        return 0x00;
    }
}


+ (BOOL)isTVShowEpisodeTitle:(NSString *)string
{
    NSString *str = [string lowercaseString];

    // Search for s01e10.
    for (int i = 0; i < (int)[str length] - 5; i++) {
        if (c(str, i) == 's' &&
            isDigit(c(str, i+1)) &&
            isDigit(c(str, i+2)) &&
            c(str, i+3) == 'e' &&
            isDigit(c(str, i+4)) &&
            isDigit(c(str, i+5)))
        {
            return YES;
        }
    }
    return NO;
}

static inline int intFromChar(char n)
{
    return n - '0';
}

static inline NSNumber *numberFromTwoChars(char high, char low)
{
    return @(intFromChar(high) * 10 + intFromChar(low));
}

static inline NSNumber *numberFromThreeChars(char high, char mid, char low)
{
    return @(intFromChar(high) * 100 + intFromChar(mid) * 10 + intFromChar(low));
}

+ (NSDictionary *)tvShowEpisodeInfoFromString:(NSString *)string
{
    if (!string)
        return nil;
    NSString *str = [string lowercaseString];
    NSUInteger stringLength = [str length];

    if (stringLength < 6)
        return nil;

    BOOL successfulSearch = NO;
    NSMutableDictionary *mutableDict;
    NSNumber *season;
    NSNumber *episode;
    NSString *tvShowName;
    NSString *episodeName;

    // Search for S00E00*
    for (unsigned int i = 0; i < stringLength - 5; i++) {
        if (c(str, i) == 's' &&
            isDigit(c(str, i+1)) &&
            isDigit(c(str, i+2)) &&
            c(str, i+3) == 'e' &&
            isDigit(c(str, i+4)) &&
            isDigit(c(str, i+5)))
        {
            season = numberFromTwoChars(c(str,i+1), c(str,i+2));

            if (isDigit(c(str, i+6)))
                episode = numberFromThreeChars(c(str,i+4), c(str,i+5), c(str,i+6));
            else
                episode = numberFromTwoChars(c(str,i+4), c(str,i+5));
            tvShowName = i > 0 ? [str substringToIndex:i] : NSLocalizedString(@"UNTITLED_SHOW", @"");
            tvShowName = tvShowName ? [[MLTitleDecrapifier decrapify:tvShowName] capitalizedString] : nil;

            episodeName = stringLength > i + 4 ? [str substringFromIndex:i+6] : nil;
            episodeName = episodeName ? [MLTitleDecrapifier decrapify:episodeName] : nil;

            successfulSearch = YES;
            goto returnThings;
        }
    }

    // search for 0x00
    if (!successfulSearch) {
        for (unsigned int i = 0; i < stringLength - 3; i++) {
            if (isDigit(c(str, i)) &&
                c(str, i+1) == 'x' &&
                isDigit(c(str, i+2)) &&
                isDigit(c(str, i+3)))
            {
                season = @(intFromChar(c(str,i)));
                episode = numberFromTwoChars(c(str,i+2), c(str,i+3));

                tvShowName = i > 0 ? [str substringToIndex:i] : NSLocalizedString(@"UNTITLED_SHOW", @"");
                tvShowName = tvShowName ? [[MLTitleDecrapifier decrapify:tvShowName] capitalizedString] : nil;

                episodeName = stringLength > i + 4 ? [str substringFromIndex:i+4] : nil;
                episodeName = episodeName ? [MLTitleDecrapifier decrapify:episodeName] : nil;

                successfulSearch = YES;
                goto returnThings;
            }
        }
    }

    // search for S0E00*
    if (!successfulSearch) {
        for (unsigned int i = 0; i < stringLength - 4; i++) {
            if (c(str, i) == 's' &&
                isDigit(c(str, i+1)) &&
                c(str, i+2) == 'e' &&
                isDigit(c(str, i+3)) &&
                isDigit(c(str, i+4)))
            {
                season = [NSNumber numberWithInt:intFromChar(c(str,i+1))];

                if (isDigit(c(str, i+5)))
                    episode = numberFromThreeChars(c(str,i+3), c(str,i+4), c(str,i+5));
                else
                    episode = numberFromTwoChars(c(str,i+3), c(str,i+4));
                tvShowName = i > 0 ? [str substringToIndex:i] : NSLocalizedString(@"UNTITLED_SHOW", @"");
                tvShowName = tvShowName ? [[MLTitleDecrapifier decrapify:tvShowName] capitalizedString] : nil;

                episodeName = stringLength > i + 4 ? [str substringFromIndex:i+5] : nil;
                episodeName = episodeName ? [MLTitleDecrapifier decrapify:episodeName] : nil;

                successfulSearch = YES;
                goto returnThings;
            }
        }
    }

returnThings:
    if (successfulSearch) {
        mutableDict = [[NSMutableDictionary alloc] initWithCapacity:4];
        if (season)
            mutableDict[@"season"] = season;
        if (episode)
            mutableDict[@"episode"] = episode;
        if (tvShowName && ![tvShowName isEqualToString:@" "])
            mutableDict[@"tvShowName"] = tvShowName;
        if (episodeName.length > 0 && ![episodeName isEqualToString:@" "])
            mutableDict[@"tvEpisodeName"] = [episodeName capitalizedString];

        return [NSDictionary dictionaryWithDictionary:mutableDict];
    }

    return nil;
}

+ (NSDictionary *)audioContentInfoFromFile:(MLFile *)file
{
    if (!file)
        return nil;

    NSString *title = file.title;
    NSArray *components = [title componentsSeparatedByString:@" "];
    if (components.count > 0) {
        if ([components[0] intValue] > 0)
            title = [self decrapify:[title stringByReplacingOccurrencesOfString:components[0] withString:@""]];
    } else
        title = [self decrapify:title];

    if (title != nil)
        return @{VLCMetaInformationTitle: title};

    return @{};
}

@end

#endif
