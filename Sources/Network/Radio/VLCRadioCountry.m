/*****************************************************************************
 * VLCRadioCountry.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioCountry.h"
#import "VLCNetworkServerBrowserVLCMedia.h"
#import "VLCFavoriteService.h"
#import <UIKit/UIKit.h>

static NSString *const VLCRadioCountryMRL = @"VLCRadioCountryMRL";

@implementation VLCRadioCountry
{
    NSString *_countryCode;
    NSString *_localizedName;
    UIImage *_flagImage;
}

- (instancetype)initWithMrl:(NSString *)mrl
{
    self = [super init];
    if (self) {
        _mrl = [mrl copy];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _mrl = [coder decodeObjectForKey:VLCRadioCountryMRL];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_mrl forKey:VLCRadioCountryMRL];
}

- (NSString *)countryCode
{
    if (!_countryCode)
        _countryCode = [NSURL URLWithString:_mrl].host.uppercaseString;

    return _countryCode;
}

- (NSString *)localizedName
{
    if (!_localizedName)
        _localizedName = [[NSLocale currentLocale] localizedStringForCountryCode:self.countryCode];

    return _localizedName;
}

- (void)prepareFlagImage
{
    if (_flagImage)
        return;

    NSString *code = [NSURL URLWithString:_mrl].host.uppercaseString;
    if (code.length != 2)
        return;

    NSMutableString *emoji = [NSMutableString stringWithCapacity:2];
    for (NSUInteger i = 0; i < 2; i++) {
        unichar character = [code characterAtIndex:i];
        if (character < 'A' || character > 'Z')
            return;
        uint32_t scalar = 0x1F1E6 + (character - 'A');
        [emoji appendString:[[NSString alloc] initWithBytes:&scalar length:sizeof(scalar) encoding:NSUTF32LittleEndianStringEncoding]];
    }

    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:40.0] };
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:[emoji sizeWithAttributes:attributes]];
    _flagImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [emoji drawAtPoint:CGPointZero withAttributes:attributes];
    }];
}

- (id<VLCNetworkServerBrowser>)makeServerBrowser
{
    NSURL *url = [NSURL URLWithString:_mrl];
    if (!url)
        return nil;

    VLCMedia *media = [VLCMedia mediaWithURL:url];
    if (!media)
        return nil;

    media.metaData.title = self.localizedName;

    VLCNetworkServerBrowserVLCMedia *browser = [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:media options:@{}];
    browser.favoriteGroupName = VLCFavoriteGroupRadio;
    return browser;
}

@end
