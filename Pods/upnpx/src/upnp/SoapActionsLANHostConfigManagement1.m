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



#import "SoapActionsLANHostConfigManagement1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsLANHostConfigManagement1


-(NSInteger)SetDHCPServerConfigurableWithNewDHCPServerConfigurable:(NSString*)newdhcpserverconfigurable{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewDHCPServerConfigurable"];
    parameterObjects = @[newdhcpserverconfigurable];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetDHCPServerConfigurable" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDHCPServerConfigurableWithOutNewDHCPServerConfigurable:(NSMutableString*)newdhcpserverconfigurable{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewDHCPServerConfigurable"];
    outputObjects = @[newdhcpserverconfigurable];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDHCPServerConfigurable" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetDHCPRelayWithNewDHCPRelay:(NSString*)newdhcprelay{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewDHCPRelay"];
    parameterObjects = @[newdhcprelay];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetDHCPRelay" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDHCPRelayWithOutNewDHCPRelay:(NSMutableString*)newdhcprelay{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewDHCPRelay"];
    outputObjects = @[newdhcprelay];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDHCPRelay" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetSubnetMaskWithNewSubnetMask:(NSString*)newsubnetmask{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewSubnetMask"];
    parameterObjects = @[newsubnetmask];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetSubnetMask" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetSubnetMaskWithOutNewSubnetMask:(NSMutableString*)newsubnetmask{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewSubnetMask"];
    outputObjects = @[newsubnetmask];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetSubnetMask" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetIPRouterWithNewIPRouters:(NSString*)newiprouters{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewIPRouters"];
    parameterObjects = @[newiprouters];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetIPRouter" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)DeleteIPRouterWithNewIPRouters:(NSString*)newiprouters{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewIPRouters"];
    parameterObjects = @[newiprouters];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"DeleteIPRouter" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetIPRoutersListWithOutNewIPRouters:(NSMutableString*)newiprouters{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewIPRouters"];
    outputObjects = @[newiprouters];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetIPRoutersList" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetDomainNameWithNewDomainName:(NSString*)newdomainname{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewDomainName"];
    parameterObjects = @[newdomainname];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetDomainName" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDomainNameWithOutNewDomainName:(NSMutableString*)newdomainname{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewDomainName"];
    outputObjects = @[newdomainname];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDomainName" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetAddressRangeWithNewMinAddress:(NSString*)newminaddress NewMaxAddress:(NSString*)newmaxaddress{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewMinAddress", @"NewMaxAddress"];
    parameterObjects = @[newminaddress, newmaxaddress];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetAddressRange" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetAddressRangeWithOutNewMinAddress:(NSMutableString*)newminaddress OutNewMaxAddress:(NSMutableString*)newmaxaddress{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewMinAddress", @"NewMaxAddress"];
    outputObjects = @[newminaddress, newmaxaddress];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetAddressRange" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetReservedAddressWithNewReservedAddresses:(NSString*)newreservedaddresses{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewReservedAddresses"];
    parameterObjects = @[newreservedaddresses];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetReservedAddress" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)DeleteReservedAddressWithNewReservedAddresses:(NSString*)newreservedaddresses{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewReservedAddresses"];
    parameterObjects = @[newreservedaddresses];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"DeleteReservedAddress" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetReservedAddressesWithOutNewReservedAddresses:(NSMutableString*)newreservedaddresses{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewReservedAddresses"];
    outputObjects = @[newreservedaddresses];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetReservedAddresses" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetDNSServerWithNewDNSServers:(NSString*)newdnsservers{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewDNSServers"];
    parameterObjects = @[newdnsservers];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetDNSServer" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)DeleteDNSServerWithNewDNSServers:(NSString*)newdnsservers{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewDNSServers"];
    parameterObjects = @[newdnsservers];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"DeleteDNSServer" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDNSServersWithOutNewDNSServers:(NSMutableString*)newdnsservers{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewDNSServers"];
    outputObjects = @[newdnsservers];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDNSServers" parameters:parameters returnValues:output];
    return ret;
}



@end
