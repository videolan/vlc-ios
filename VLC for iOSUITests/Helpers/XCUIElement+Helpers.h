/*****************************************************************************
 * XCUIElement+Helpers.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: David Cordero <david # corderoramirez.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <XCTest/XCTest.h>

@interface XCUIElement(Test)

- (void)clearAndEnterText:(NSString *)text;

@end
