/*****************************************************************************
* VLCSubtitleItem.h
* VLC for iOS
*****************************************************************************
* Copyright (c) 2015, 2020 VideoLAN. All rights reserved.
* $Id$
*
* Author: Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

@interface VLCSubtitleItem : NSObject

@property (copy, nonatomic) NSString *language;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *format;
@property (copy, nonatomic) NSString *iso639Language;
@property (copy, nonatomic) NSString *downloadAddress;
@property (copy, nonatomic) NSString *rating;

@end

@interface VLCSubtitleLanguage : NSObject

@property (copy, nonatomic) NSString *ID;
@property (copy, nonatomic) NSString *localizedName;
@property (copy, nonatomic) NSString *iso639Language;

@end
