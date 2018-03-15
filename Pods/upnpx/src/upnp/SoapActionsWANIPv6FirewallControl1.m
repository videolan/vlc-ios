// **********************************************************************************
//
// BSD License.
// This file is part of upnpx.
//
// Copyright (c) 2010-2011, Bruno Keymolen, email: bruno.keymolen@gmail.com
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, 
// this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this 
// list of conditions and the following disclaimer in the documentation and/or other 
// materials provided with the distribution.
// Neither the name of "Bruno Keymolen" nor the names of its contributors may be 
// used to endorse or promote products derived from this software without specific 
// prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;LOSS OF USE, DATA, OR 
// PROFITS;OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
// POSSIBILITY OF SUCH DAMAGE.
//
// **********************************************************************************



#import "SoapActionsWANIPv6FirewallControl1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsWANIPv6FirewallControl1


-(NSInteger)GetFirewallStatusWithOutFirewallEnabled:(NSMutableString*)firewallenabled OutInboundPinholeAllowed:(NSMutableString*)inboundpinholeallowed{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"FirewallEnabled", @"InboundPinholeAllowed"];
    outputObjects = @[firewallenabled, inboundpinholeallowed];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetFirewallStatus" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetOutboundPinholeTimeoutWithRemoteHost:(NSString*)remotehost RemotePort:(NSString*)remoteport InternalClient:(NSString*)internalclient InternalPort:(NSString*)internalport Protocol:(NSString*)protocol OutOutboundPinholeTimeout:(NSMutableString*)outboundpinholetimeout{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"RemoteHost", @"RemotePort", @"InternalClient", @"InternalPort", @"Protocol"];
    parameterObjects = @[remotehost, remoteport, internalclient, internalport, protocol];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"OutboundPinholeTimeout"];
    outputObjects = @[outboundpinholetimeout];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetOutboundPinholeTimeout" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)AddPinholeWithRemoteHost:(NSString*)remotehost RemotePort:(NSString*)remoteport InternalClient:(NSString*)internalclient InternalPort:(NSString*)internalport Protocol:(NSString*)protocol LeaseTime:(NSString*)leasetime OutUniqueID:(NSMutableString*)uniqueid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"RemoteHost", @"RemotePort", @"InternalClient", @"InternalPort", @"Protocol", @"LeaseTime"];
    parameterObjects = @[remotehost, remoteport, internalclient, internalport, protocol, leasetime];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"UniqueID"];
    outputObjects = @[uniqueid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"AddPinhole" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)UpdatePinholeWithUniqueID:(NSString*)uniqueid NewLeaseTime:(NSString*)newleasetime{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"UniqueID", @"NewLeaseTime"];
    parameterObjects = @[uniqueid, newleasetime];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"UpdatePinhole" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)DeletePinholeWithUniqueID:(NSString*)uniqueid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"UniqueID"];
    parameterObjects = @[uniqueid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"DeletePinhole" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetPinholePacketsWithUniqueID:(NSString*)uniqueid OutPinholePackets:(NSMutableString*)pinholepackets{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"UniqueID"];
    parameterObjects = @[uniqueid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"PinholePackets"];
    outputObjects = @[pinholepackets];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetPinholePackets" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)CheckPinholeWorkingWithUniqueID:(NSString*)uniqueid OutIsWorking:(NSMutableString*)isworking{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"UniqueID"];
    parameterObjects = @[uniqueid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"IsWorking"];
    outputObjects = @[isworking];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"CheckPinholeWorking" parameters:parameters returnValues:output];
    return ret;
}



@end
