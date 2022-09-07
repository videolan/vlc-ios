/*****************************************************************************
* VLCSubtitleItem.m
* VLC for iOS
*****************************************************************************
* Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
* $Id$
*
* Author: Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

#import "VLCSubtitleItem.h"

@implementation VLCSubtitleItem

- (NSString *)description
{
    return [NSString stringWithFormat:@"%s: name: '%@' format: '%@' language: '%@'", __PRETTY_FUNCTION__, self.name, self.format, self.language];
}

@end

@implementation VLCSubtitleLanguage

- (NSString *)description
{
    return [NSString stringWithFormat:@"%s: ID: '%@', ISO639: '%@', localized: '%@'", __PRETTY_FUNCTION__, self.ID, self.iso639Language, self.localizedName];
}

@end
