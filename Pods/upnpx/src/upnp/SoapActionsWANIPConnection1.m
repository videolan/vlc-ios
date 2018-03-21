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



#import "SoapActionsWANIPConnection1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsWANIPConnection1


-(NSInteger)SetConnectionTypeWithNewConnectionType:(NSString*)newconnectiontype{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewConnectionType"];
    parameterObjects = @[newconnectiontype];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetConnectionType" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetConnectionTypeInfoWithOutNewConnectionType:(NSMutableString*)newconnectiontype OutNewPossibleConnectionTypes:(NSMutableString*)newpossibleconnectiontypes{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewConnectionType", @"NewPossibleConnectionTypes"];
    outputObjects = @[newconnectiontype, newpossibleconnectiontypes];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetConnectionTypeInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)RequestConnection{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    ret = [self action:@"RequestConnection" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)RequestTermination{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    ret = [self action:@"RequestTermination" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)ForceTermination{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    ret = [self action:@"ForceTermination" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetAutoDisconnectTimeWithNewAutoDisconnectTime:(NSString*)newautodisconnecttime{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewAutoDisconnectTime"];
    parameterObjects = @[newautodisconnecttime];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetAutoDisconnectTime" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetIdleDisconnectTimeWithNewIdleDisconnectTime:(NSString*)newidledisconnecttime{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewIdleDisconnectTime"];
    parameterObjects = @[newidledisconnecttime];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetIdleDisconnectTime" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetWarnDisconnectDelayWithNewWarnDisconnectDelay:(NSString*)newwarndisconnectdelay{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewWarnDisconnectDelay"];
    parameterObjects = @[newwarndisconnectdelay];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetWarnDisconnectDelay" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetStatusInfoWithOutNewConnectionStatus:(NSMutableString*)newconnectionstatus OutNewLastConnectionError:(NSMutableString*)newlastconnectionerror OutNewUptime:(NSMutableString*)newuptime{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewConnectionStatus", @"NewLastConnectionError", @"NewUptime"];
    outputObjects = @[newconnectionstatus, newlastconnectionerror, newuptime];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetStatusInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetAutoDisconnectTimeWithOutNewAutoDisconnectTime:(NSMutableString*)newautodisconnecttime{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewAutoDisconnectTime"];
    outputObjects = @[newautodisconnecttime];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetAutoDisconnectTime" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetIdleDisconnectTimeWithOutNewIdleDisconnectTime:(NSMutableString*)newidledisconnecttime{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewIdleDisconnectTime"];
    outputObjects = @[newidledisconnecttime];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetIdleDisconnectTime" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetWarnDisconnectDelayWithOutNewWarnDisconnectDelay:(NSMutableString*)newwarndisconnectdelay{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewWarnDisconnectDelay"];
    outputObjects = @[newwarndisconnectdelay];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetWarnDisconnectDelay" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetNATRSIPStatusWithOutNewRSIPAvailable:(NSMutableString*)newrsipavailable OutNewNATEnabled:(NSMutableString*)newnatenabled{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewRSIPAvailable", @"NewNATEnabled"];
    outputObjects = @[newrsipavailable, newnatenabled];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetNATRSIPStatus" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetGenericPortMappingEntryWithNewPortMappingIndex:(NSString*)newportmappingindex OutNewRemoteHost:(NSMutableString*)newremotehost OutNewExternalPort:(NSMutableString*)newexternalport OutNewProtocol:(NSMutableString*)newprotocol OutNewInternalPort:(NSMutableString*)newinternalport OutNewInternalClient:(NSMutableString*)newinternalclient OutNewEnabled:(NSMutableString*)newenabled OutNewPortMappingDescription:(NSMutableString*)newportmappingdescription OutNewLeaseDuration:(NSMutableString*)newleaseduration{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewPortMappingIndex"];
    parameterObjects = @[newportmappingindex];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewRemoteHost", @"NewExternalPort", @"NewProtocol", @"NewInternalPort", @"NewInternalClient", @"NewEnabled", @"NewPortMappingDescription", @"NewLeaseDuration"];
    outputObjects = @[newremotehost, newexternalport, newprotocol, newinternalport, newinternalclient, newenabled, newportmappingdescription, newleaseduration];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetGenericPortMappingEntry" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetSpecificPortMappingEntryWithNewRemoteHost:(NSString*)newremotehost NewExternalPort:(NSString*)newexternalport NewProtocol:(NSString*)newprotocol OutNewInternalPort:(NSMutableString*)newinternalport OutNewInternalClient:(NSMutableString*)newinternalclient OutNewEnabled:(NSMutableString*)newenabled OutNewPortMappingDescription:(NSMutableString*)newportmappingdescription OutNewLeaseDuration:(NSMutableString*)newleaseduration{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewRemoteHost", @"NewExternalPort", @"NewProtocol"];
    parameterObjects = @[newremotehost, newexternalport, newprotocol];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewInternalPort", @"NewInternalClient", @"NewEnabled", @"NewPortMappingDescription", @"NewLeaseDuration"];
    outputObjects = @[newinternalport, newinternalclient, newenabled, newportmappingdescription, newleaseduration];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetSpecificPortMappingEntry " parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)AddPortMappingWithNewRemoteHost:(NSString*)newremotehost NewExternalPort:(NSString*)newexternalport NewProtocol:(NSString*)newprotocol NewInternalPort:(NSString*)newinternalport NewInternalClient:(NSString*)newinternalclient NewEnabled:(NSString*)newenabled NewPortMappingDescription:(NSString*)newportmappingdescription NewLeaseDuration:(NSString*)newleaseduration{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewRemoteHost", @"NewExternalPort", @"NewProtocol", @"NewInternalPort", @"NewInternalClient", @"NewEnabled", @"NewPortMappingDescription", @"NewLeaseDuration"];
    parameterObjects = @[newremotehost, newexternalport, newprotocol, newinternalport, newinternalclient, newenabled, newportmappingdescription, newleaseduration];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"AddPortMapping " parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)DeletePortMappingWithNewRemoteHost:(NSString*)newremotehost NewExternalPort:(NSString*)newexternalport NewProtocol:(NSString*)newprotocol{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewRemoteHost", @"NewExternalPort", @"NewProtocol"];
    parameterObjects = @[newremotehost, newexternalport, newprotocol];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"DeletePortMapping" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetExternalIPAddressWithOutNewExternalIPAddress:(NSMutableString*)newexternalipaddress{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewExternalIPAddress"];
    outputObjects = @[newexternalipaddress];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetExternalIPAddress" parameters:parameters returnValues:output];
    return ret;
}



@end
