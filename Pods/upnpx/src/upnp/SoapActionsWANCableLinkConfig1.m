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



#import "SoapActionsWANCableLinkConfig1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsWANCableLinkConfig1


-(NSInteger)GetCableLinkConfigInfoWithOutNewCableLinkConfigState:(NSMutableString*)newcablelinkconfigstate OutNewLinkType:(NSMutableString*)newlinktype{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewCableLinkConfigState", @"NewLinkType"];
    outputObjects = @[newcablelinkconfigstate, newlinktype];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetCableLinkConfigInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDownstreamFrequencyWithOutNewDownstreamFrequency:(NSMutableString*)newdownstreamfrequency{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewDownstreamFrequency"];
    outputObjects = @[newdownstreamfrequency];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDownstreamFrequency" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDownstreamModulationWithOutNewDownstreamModulation:(NSMutableString*)newdownstreammodulation{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewDownstreamModulation"];
    outputObjects = @[newdownstreammodulation];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDownstreamModulation" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetUpstreamFrequencyWithOutNewUpstreamFrequency:(NSMutableString*)newupstreamfrequency{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewUpstreamFrequency"];
    outputObjects = @[newupstreamfrequency];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetUpstreamFrequency" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetUpstreamModulationWithOutNewUpstreamModulation:(NSMutableString*)newupstreammodulation{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewUpstreamModulation"];
    outputObjects = @[newupstreammodulation];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetUpstreamModulation" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetUpstreamChannelIDWithOutNewUpstreamChannelID:(NSMutableString*)newupstreamchannelid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewUpstreamChannelID"];
    outputObjects = @[newupstreamchannelid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetUpstreamChannelID" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetUpstreamPowerLevelWithOutNewUpstreamPowerLevel:(NSMutableString*)newupstreampowerlevel{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewUpstreamPowerLevel"];
    outputObjects = @[newupstreampowerlevel];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetUpstreamPowerLevel" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetBPIEncryptionEnabledWithOutNewBPIEncryptionEnabled:(NSMutableString*)newbpiencryptionenabled{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewBPIEncryptionEnabled"];
    outputObjects = @[newbpiencryptionenabled];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetBPIEncryptionEnabled" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetConfigFileWithOutNewConfigFile:(NSMutableString*)newconfigfile{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewConfigFile"];
    outputObjects = @[newconfigfile];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetConfigFile" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetTFTPServerWithOutNewTFTPServer:(NSMutableString*)newtftpserver{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewTFTPServer"];
    outputObjects = @[newtftpserver];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetTFTPServer" parameters:parameters returnValues:output];
    return ret;
}



@end
