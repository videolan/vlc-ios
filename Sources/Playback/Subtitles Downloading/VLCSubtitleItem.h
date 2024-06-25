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

@property (copy, nonatomic) NSNumber *ID;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *language;
@property (copy, nonatomic) NSString *fps;
@property (nonatomic) BOOL hd;
@property (copy, nonatomic) NSString *rating;
@property (copy, nonatomic) NSString *downloadCount;
@property (copy, nonatomic) NSDate *uploadDate;

@end

@interface VLCSubtitleLanguage : NSObject

@property (copy, nonatomic) NSString *languageCode;
@property (copy, nonatomic) NSString *languageName;

@end
