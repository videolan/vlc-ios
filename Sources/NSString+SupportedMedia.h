/*****************************************************************************
 * NSString+SupportedMedia.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

@interface NSString (SupportedMedia)

- (BOOL)isSupportedMediaFormat;
- (BOOL)isSupportedAudioMediaFormat;
- (BOOL)isSupportedSubtitleFormat;

- (BOOL)isSupportedFormat;

@end
