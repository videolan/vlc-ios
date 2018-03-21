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



#import "SoapActionsWANPOTSLinkConfig1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsWANPOTSLinkConfig1


-(NSInteger)SetISPInfoWithNewISPPhoneNumber:(NSString*)newispphonenumber NewISPInfo:(NSString*)newispinfo NewLinkType:(NSString*)newlinktype{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewISPPhoneNumber", @"NewISPInfo", @"NewLinkType"];
    parameterObjects = @[newispphonenumber, newispinfo, newlinktype];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetISPInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetCallRetryInfoWithNewNumberOfRetries:(NSString*)newnumberofretries NewDelayBetweenRetries:(NSString*)newdelaybetweenretries{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewNumberOfRetries", @"NewDelayBetweenRetries"];
    parameterObjects = @[newnumberofretries, newdelaybetweenretries];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetCallRetryInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetISPInfoWithOutNewISPPhoneNumber:(NSMutableString*)newispphonenumber OutNewISPInfo:(NSMutableString*)newispinfo OutNewLinkType:(NSMutableString*)newlinktype{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewISPPhoneNumber", @"NewISPInfo", @"NewLinkType"];
    outputObjects = @[newispphonenumber, newispinfo, newlinktype];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetISPInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetCallRetryInfoWithOutNewNumberOfRetries:(NSMutableString*)newnumberofretries OutNewDelayBetweenRetries:(NSMutableString*)newdelaybetweenretries{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewNumberOfRetries", @"NewDelayBetweenRetries"];
    outputObjects = @[newnumberofretries, newdelaybetweenretries];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetCallRetryInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetFclassWithOutNewFclass:(NSMutableString*)newfclass{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewFclass"];
    outputObjects = @[newfclass];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetFclass" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDataModulationSupportedWithOutNewDataModulationSupported:(NSMutableString*)newdatamodulationsupported{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewDataModulationSupported"];
    outputObjects = @[newdatamodulationsupported];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDataModulationSupported" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDataProtocolWithOutNewDataProtocol:(NSMutableString*)newdataprotocol{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewDataProtocol"];
    outputObjects = @[newdataprotocol];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDataProtocol" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDataCompressionWithOutNewDataCompression:(NSMutableString*)newdatacompression{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewDataCompression"];
    outputObjects = @[newdatacompression];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDataCompression" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetPlusVTRCommandSupportedWithOutNewPlusVTRCommandSupported:(NSMutableString*)newplusvtrcommandsupported{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewPlusVTRCommandSupported"];
    outputObjects = @[newplusvtrcommandsupported];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetPlusVTRCommandSupported" parameters:parameters returnValues:output];
    return ret;
}



@end
