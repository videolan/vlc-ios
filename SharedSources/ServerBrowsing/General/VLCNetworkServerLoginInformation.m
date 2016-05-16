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

@end

@implementation VLCNetworkServerLoginInformation
@end