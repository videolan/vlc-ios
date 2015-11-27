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

@interface NSString (LocaleCodes)

- (NSString *)VLCtwoLetterLanguageKeyForThreeLetterCode;
- (NSString *)VLCthreeLetterLanguageKeyForTwoLetterCode;
- (NSString *)VLClocalizedLanguageNameForTwoLetterCode;

@end
