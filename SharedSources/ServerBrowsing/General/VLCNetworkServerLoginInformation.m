/*****************************************************************************
 * VLCNetworkServerLoginInformation.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerLoginInformation.h"

@implementation VLCNetworkServerLoginInformationField

- (instancetype)initWithType:(VLCNetworkServerLoginInformationFieldType)type identifier:(NSString *)identifier label:(NSString *)localizedLabel textValue:(NSString *)initialValue
{
    self = [super init];
    if (self) {
        _type = type;
        _identifier = [identifier copy];
        _localizedLabel = [localizedLabel copy];
        _textValue = [initialValue copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithType:self.type identifier:self.identifier label:self.localizedLabel textValue:self.textValue];
}

@end

@implementation VLCNetworkServerLoginInformation

- (id)copyWithZone:(NSZone *)zone
{
    VLCNetworkServerLoginInformation *other = [[[self class] allocWithZone:zone] init];
    other.username = self.username;
    other.password = self.password;
    other.address = self.address;
    other.port = self.port;
    other.protocolIdentifier = self.protocolIdentifier;
    other.additionalFields = [[NSMutableArray alloc] initWithArray:self.additionalFields copyItems:YES];
    return other;
}



static NSMutableDictionary<NSString *, VLCNetworkServerLoginInformation *> *VLCNetworkServerLoginInformationRegistry = nil;
+ (void)initialize
{
    [super initialize];
    VLCNetworkServerLoginInformationRegistry = [[NSMutableDictionary alloc] init];
}

+ (void)registerTemplateLoginInformation:(VLCNetworkServerLoginInformation *)loginInformation
{
    VLCNetworkServerLoginInformationRegistry[loginInformation.protocolIdentifier] = [loginInformation copy];
}

+ (instancetype)newLoginInformationForProtocol:(NSString *)protocolIdentifier
{
    VLCNetworkServerLoginInformation *loginInformation  = [VLCNetworkServerLoginInformationRegistry[protocolIdentifier] copy];
    if (!loginInformation) {
        loginInformation = [[VLCNetworkServerLoginInformation alloc] init];
        loginInformation.protocolIdentifier = protocolIdentifier;
    }
    return loginInformation;
}

@end
