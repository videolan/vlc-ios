/*****************************************************************************
 * VLCKeychainCoordinator.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extern NSString *const VLCPasscodeValidated;

@interface VLCKeychainCoordinator : NSObject

+ (instancetype)defaultCoordinator;

@property (readonly) BOOL passcodeLockEnabled;

- (void)validatePasscode;
- (void)setPasscode:(NSString *)passcode;

@end
