/*****************************************************************************
 * VLCSharedLibraryParser.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
@interface VLCSharedLibraryParser : NSObject

- (NSMutableArray *)VLCLibraryServerParser:(NSString *)adress port:(NSString *)port;
- (BOOL)isVLCMediaServer:(NSString *)adress port:(NSString *)port;

@end
