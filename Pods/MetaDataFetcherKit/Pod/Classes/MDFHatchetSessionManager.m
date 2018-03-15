/*****************************************************************************
 * MDFHatchetSessionManager.m
 *****************************************************************************
 * Copyright (C) 2015 Felix Paul Kühne
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "MDFHatchetSessionManager.h"

static NSString * const HatchetBaseURLString = @"https://api.hatchet.is/v2";

@implementation MDFHatchetSessionManager

+ (instancetype)sharedInstance
{
    static MDFHatchetSessionManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[MDFHatchetSessionManager alloc] initWithBaseURL:[NSURL URLWithString:HatchetBaseURLString]];
        _sharedClient.requestSerializer = [AFJSONRequestSerializer serializer];

        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        securityPolicy.validatesDomainName = YES;
        securityPolicy.allowInvalidCertificates = NO;
        _sharedClient.securityPolicy = securityPolicy;

        _sharedClient.apiKey = @"none needed so far";
    });

    return _sharedClient;
}

@end
