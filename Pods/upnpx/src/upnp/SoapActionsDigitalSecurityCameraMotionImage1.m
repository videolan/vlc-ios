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



#import "SoapActionsDigitalSecurityCameraMotionImage1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsDigitalSecurityCameraMotionImage1


-(NSInteger)GetAvailableEncodingsWithOutRetAvailableEncodings:(NSMutableString*)retavailableencodings{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetAvailableEncodings"];
    outputObjects = @[retavailableencodings];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetAvailableEncodings" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDefaultEncodingWithOutRetEncoding:(NSMutableString*)retencoding{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetEncoding"];
    outputObjects = @[retencoding];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDefaultEncoding" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetDefaultEncodingWithReqEncoding:(NSString*)reqencoding{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ReqEncoding"];
    parameterObjects = @[reqencoding];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetDefaultEncoding" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetAvailableCompressionLevelsWithOutRetAvailableCompressionLevels:(NSMutableString*)retavailablecompressionlevels{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetAvailableCompressionLevels"];
    outputObjects = @[retavailablecompressionlevels];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetAvailableCompressionLevels" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDefaultCompressionLevelWithOutRetCompressionLevel:(NSMutableString*)retcompressionlevel{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetCompressionLevel"];
    outputObjects = @[retcompressionlevel];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDefaultCompressionLevel" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetDefaultCompressionLevelWithReqCompressionLevel:(NSString*)reqcompressionlevel{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ReqCompressionLevel"];
    parameterObjects = @[reqcompressionlevel];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetDefaultCompressionLevel" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetAvailableResolutionsWithOutRetAvailableResolutions:(NSMutableString*)retavailableresolutions{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetAvailableResolutions"];
    outputObjects = @[retavailableresolutions];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetAvailableResolutions" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDefaultResolutionWithOutRetResolution:(NSMutableString*)retresolution{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetResolution"];
    outputObjects = @[retresolution];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDefaultResolution" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetDefaultResolutionWithReqResolution:(NSString*)reqresolution{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ReqResolution"];
    parameterObjects = @[reqresolution];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetDefaultResolution" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetVideoURLWithReqEncoding:(NSString*)reqencoding ReqCompression:(NSString*)reqcompression ReqResolution:(NSString*)reqresolution ReqMaxBandwidth:(NSString*)reqmaxbandwidth ReqTargetFrameRate:(NSString*)reqtargetframerate OutRetVideoURL:(NSMutableString*)retvideourl{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ReqEncoding", @"ReqCompression", @"ReqResolution", @"ReqMaxBandwidth", @"ReqTargetFrameRate"];
    parameterObjects = @[reqencoding, reqcompression, reqresolution, reqmaxbandwidth, reqtargetframerate];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetVideoURL"];
    outputObjects = @[retvideourl];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetVideoURL" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDefaultVideoURLWithOutRetVideoURL:(NSMutableString*)retvideourl{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetVideoURL"];
    outputObjects = @[retvideourl];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDefaultVideoURL" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetVideoPresentationURLWithReqEncoding:(NSString*)reqencoding ReqCompression:(NSString*)reqcompression ReqResolution:(NSString*)reqresolution ReqMaxBandwidth:(NSString*)reqmaxbandwidth ReqTargetFrameRate:(NSString*)reqtargetframerate OutRetVideoPresentationURL:(NSMutableString*)retvideopresentationurl{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ReqEncoding", @"ReqCompression", @"ReqResolution", @"ReqMaxBandwidth", @"ReqTargetFrameRate"];
    parameterObjects = @[reqencoding, reqcompression, reqresolution, reqmaxbandwidth, reqtargetframerate];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetVideoPresentationURL"];
    outputObjects = @[retvideopresentationurl];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetVideoPresentationURL" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDefaultVideoPresentationURLWithOutRetVideoPresentationURL:(NSMutableString*)retvideopresentationurl{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetVideoPresentationURL"];
    outputObjects = @[retvideopresentationurl];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDefaultVideoPresentationURL" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetMaxBandwidthWithReqMaxBandwidth:(NSString*)reqmaxbandwidth{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ReqMaxBandwidth"];
    parameterObjects = @[reqmaxbandwidth];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetMaxBandwidth" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetMaxBandwidthWithOutRetMaxBandwidth:(NSMutableString*)retmaxbandwidth{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetMaxBandwidth"];
    outputObjects = @[retmaxbandwidth];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetMaxBandwidth" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetTargetFrameRateWithReqTargetFrameRate:(NSString*)reqtargetframerate{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ReqTargetFrameRate"];
    parameterObjects = @[reqtargetframerate];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetTargetFrameRate" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetTargetFrameRateWithOutRetTargetFrameRate:(NSMutableString*)rettargetframerate{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"RetTargetFrameRate"];
    outputObjects = @[rettargetframerate];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetTargetFrameRate" parameters:parameters returnValues:output];
    return ret;
}



@end
