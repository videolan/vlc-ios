/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerLoginInformation.h"
NS_ASSUME_NONNULL_BEGIN
@interface VLCNetworkServerLoginInformation (Keychain)
@property (nonatomic, readonly) NSString *keychainServiceIdentifier;

+ (instancetype)loginInformationWithKeychainIdentifier:(NSString *)keychainIdentifier;

- (BOOL)loadLoginInformationFromKeychainWithError:(NSError * _Nullable __autoreleasing *)error;
- (BOOL)saveLoginInformationToKeychainWithError:(NSError * _Nullable __autoreleasing *)error;
- (BOOL)deleteFromKeychainWithError:(NSError * _Nullable __autoreleasing *)error;
@end
NS_ASSUME_NONNULL_END
