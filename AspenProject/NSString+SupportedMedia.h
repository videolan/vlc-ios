//
//  NSString+SupportedMedia.h
//  VLC for iOS
//
//  Created by Gleb on 6/1/13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SupportedMedia)

- (BOOL)isSupportedMediaFormat;
- (BOOL)isSupportedSubtitleFormat;

@end
