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



#import "SoapActionsWANDSLLinkConfig1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsWANDSLLinkConfig1


-(NSInteger)SetDSLLinkTypeWithNewLinkType:(NSString*)newlinktype{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewLinkType"];
    parameterObjects = @[newlinktype];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetDSLLinkType" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDSLLinkInfoWithOutNewLinkType:(NSMutableString*)newlinktype OutNewLinkStatus:(NSMutableString*)newlinkstatus{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewLinkType", @"NewLinkStatus"];
    outputObjects = @[newlinktype, newlinkstatus];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDSLLinkInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetAutoConfigWithOutNewAutoConfig:(NSMutableString*)newautoconfig{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewAutoConfig"];
    outputObjects = @[newautoconfig];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetAutoConfig" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetModulationTypeWithOutNewModulationType:(NSMutableString*)newmodulationtype{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewModulationType"];
    outputObjects = @[newmodulationtype];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetModulationType" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetDestinationAddressWithNewDestinationAddress:(NSString*)newdestinationaddress{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewDestinationAddress"];
    parameterObjects = @[newdestinationaddress];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetDestinationAddress" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDestinationAddressWithOutNewDestinationAddress:(NSMutableString*)newdestinationaddress{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewDestinationAddress"];
    outputObjects = @[newdestinationaddress];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDestinationAddress" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetATMEncapsulationWithNewATMEncapsulation:(NSString*)newatmencapsulation{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewATMEncapsulation"];
    parameterObjects = @[newatmencapsulation];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetATMEncapsulation" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetATMEncapsulationWithOutNewATMEncapsulation:(NSMutableString*)newatmencapsulation{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewATMEncapsulation"];
    outputObjects = @[newatmencapsulation];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetATMEncapsulation" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetFCSPreservedWithNewFCSPreserved:(NSString*)newfcspreserved{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewFCSPreserved"];
    parameterObjects = @[newfcspreserved];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetFCSPreserved" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetFCSPreservedWithOutNewFCSPreserved:(NSMutableString*)newfcspreserved{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewFCSPreserved"];
    outputObjects = @[newfcspreserved];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetFCSPreserved" parameters:parameters returnValues:output];
    return ret;
}



@end
