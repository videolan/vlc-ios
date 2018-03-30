/*****************************************************************************
 * XCUIElement+Helpers.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: David Cordero <david # corderoramirez.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "XCUIElement+Helpers.h"

@implementation XCUIElement(Test)

- (void)clearAndEnterText:(NSString *)text {
    if (![[self value] isKindOfClass:[NSString class]]) {
        XCTFail("Tried to clear and enter text into a non string value");
        return;
    }

    [self tap];
    NSString *deleteString = @"";
    for (int i = 0; i < [(NSString *)[self value] length]; i++){
        deleteString = [deleteString stringByAppendingString:XCUIKeyboardKeyDelete];
    }

    [self typeText:deleteString];
    [self typeText:text];
}
@end
