/*****************************************************************************
 * VLCSavedServerList.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

@class VLCNetworkServerLoginInformation;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const VLCSavedServerListDidChange;

@interface VLCSavedServerList : NSObject

@property (readonly) NSArray<NSString *> *serverIdentifiers;

- (BOOL)addLogin:(VLCNetworkServerLoginInformation *)login error:(NSError **)error;
- (BOOL)removeServerAtIndex:(NSUInteger)index error:(NSError **)error;

- (nullable VLCNetworkServerLoginInformation *)loginAtIndex:(NSUInteger)index error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
