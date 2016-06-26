/*****************************************************************************
 * VLCNetworkServerLoginInformation.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "VLCLocalNetworkService-Protocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLCNetworkServerLoginInformationField : NSObject <NSCopying, VLCNetworkServerLoginInformationField>
@property (nonatomic, readonly) VLCNetworkServerLoginInformationFieldType type;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *localizedLabel;
@property (nonatomic, copy) NSString *textValue;

- (instancetype)initWithType:(VLCNetworkServerLoginInformationFieldType)type
                  identifier:(NSString *)identifier
                       label:(NSString *)localizedLabel
                   textValue:(nullable NSString *)initialValue NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface VLCNetworkServerLoginInformation : NSObject <NSCopying, VLCNetworkServerLoginInformation>
@property (nonatomic, copy, nullable) NSString *username;
@property (nonatomic, copy, nullable) NSString *password;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSNumber *port;
@property (nonatomic, copy) NSString *protocolIdentifier;
@property (nonatomic, copy) NSArray<VLCNetworkServerLoginInformationField *> *additionalFields;

+ (instancetype)newLoginInformationForProtocol:(NSString *)protocolIdentifier;
+ (void)registerTemplateLoginInformation:(VLCNetworkServerLoginInformation *)loginInformation;
@end
NS_ASSUME_NONNULL_END
