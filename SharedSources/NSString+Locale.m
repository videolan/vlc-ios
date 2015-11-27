/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "NSString+Locale.h"

@implementation NSString (LocaleCodes)

- (NSString *)VLCtwoLetterLanguageKeyForThreeLetterCode
{
    NSDictionary *searchDict = @{@"alb" : @"sq",
                                 @"ara" : @"ar",
                                 @"arm" : @"hy",
                                 @"baq" : @"eu",
                                 @"ben" : @"bn",
                                 @"bos" : @"bs",
                                 @"bre" : @"br",
                                 @"bur" : @"bg",
                                 @"cat" : @"ca",
                                 @"chi" : @"zh",
                                 @"hrv" : @"hr",
                                 @"cze" : @"cs",
                                 @"dan" : @"da",
                                 @"dut" : @"nl",
                                 @"eng" : @"en",
                                 @"epo" : @"eo",
                                 @"fin" : @"fi",
                                 @"fre" : @"fr",
                                 @"glg" : @"gl",
                                 @"ger" : @"de",
                                 @"ell" : @"el",
                                 @"heb" : @"he",
                                 @"hin" : @"hi",
                                 @"ice" : @"is",
                                 @"ind" : @"id",
                                 @"ita" : @"it",
                                 @"jpn" : @"a",
                                 @"kaz" : @"kk",
                                 @"kor" : @"ko",
                                 @"lav" : @"lv",
                                 @"lit" : @"lt",
                                 @"ltz" : @"lb",
                                 @"mac" : @"mk",
                                 @"may" : @"ms",
                                 @"mal" : @"ml",
                                 @"mon" : @"mn",
                                 @"nor" : @"no",
                                 @"oci" : @"oc",
                                 @"per" : @"fa",
                                 @"pol" : @"pl",
                                 @"por" : @"pt",
                                 @"pob" : @"po",
                                 @"rum" : @"rm",
                                 @"rus" : @"ru",
                                 @"scc" : @"sr",
                                 @"sin" : @"si",
                                 @"slo" : @"sk",
                                 @"slv" : @"sl",
                                 @"spa" : @"es",
                                 @"swa" : @"sw",
                                 @"swe" : @"sv",
                                 @"tgl" : @"tl",
                                 @"tel" : @"te",
                                 @"tha" : @"th",
                                 @"tur" : @"tr",
                                 @"ukr" : @"uk",
                                 @"urd" : @"ur",
                                 @"vie" : @"vi"};
    return searchDict[self];
}

- (NSString *)VLCthreeLetterLanguageKeyForTwoLetterCode
{
    NSDictionary *searchDict = @{@"sq" : @"alb",
                                 @"ar" : @"ara",
                                 @"hy" : @"arm",
                                 @"eu" : @"baq",
                                 @"bn" : @"ben",
                                 @"bs" : @"bos",
                                 @"br" : @"bre",
                                 @"bg" : @"bul",
                                 @"my" : @"bur",
                                 @"ca" : @"cat",
                                 @"zh" : @"chi",
                                 @"hr" : @"hrv",
                                 @"cs" : @"cze",
                                 @"da" : @"dan",
                                 @"nl" : @"dut",
                                 @"en" : @"eng",
                                 @"eo" : @"epo",
                                 @"et" : @"est",
                                 @"fi" : @"fin",
                                 @"fr" : @"fre",
                                 @"gl" : @"glg",
                                 @"ka" : @"geo",
                                 @"de" : @"ger",
                                 @"el" : @"ell",
                                 @"he" : @"heb",
                                 @"hi" : @"hin",
                                 @"hu" : @"hun",
                                 @"is" : @"ice",
                                 @"id" : @"ind",
                                 @"it" : @"ita",
                                 @"ja" : @"jpn",
                                 @"kk" : @"kaz",
                                 @"km" : @"khm",
                                 @"ko" : @"kor",
                                 @"lv" : @"lav",
                                 @"lt" : @"lit",
                                 @"lb" : @"ltz",
                                 @"mk" : @"mac",
                                 @"ms" : @"may",
                                 @"ml" : @"mal",
                                 @"mn" : @"mon",
                                 @"no" : @"nor",
                                 @"oc" : @"oci",
                                 @"fa" : @"per",
                                 @"pl" : @"pol",
                                 @"pt" : @"por",
                                 @"po" : @"pob",
                                 @"ro" : @"rum",
                                 @"ru" : @"rus",
                                 @"sr" : @"scc",
                                 @"si" : @"sin",
                                 @"sk" : @"slo",
                                 @"sl" : @"slv",
                                 @"es" : @"spa",
                                 @"sw" : @"swa",
                                 @"sv" : @"swe",
                                 @"tl" : @"tgl",
                                 @"te" : @"tel",
                                 @"th" : @"tha",
                                 @"tr" : @"tur",
                                 @"uk" : @"ukr",
                                 @"ur" : @"urd",
                                 @"vi" : @"vie"};
    return searchDict[self];
}

- (NSString *)VLClocalizedLanguageNameForTwoLetterCode
{
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleLanguageCode value:self];
}

@end
