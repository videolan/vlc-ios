//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import "SoapActionsMediaManagement1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsMediaManagement1


-(NSInteger)GetMediaCapabilitiesWithTSMediaCapabilityInfo:(NSString*)tsmediacapabilityinfo OutSupportedMediaCapabilityInfo:(NSMutableString*)supportedmediacapabilityinfo{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"TSMediaCapabilityInfo"];
    parameterObjects = @[tsmediacapabilityinfo];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"SupportedMediaCapabilityInfo"];
    outputObjects = @[supportedmediacapabilityinfo];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetMediaCapabilities" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetMediaSessionInfoWithTargetMediaSessionID:(NSString*)targetmediasessionid OutMediaSessionInfoList:(NSMutableString*)mediasessioninfolist{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"TargetMediaSessionID"];
    parameterObjects = @[targetmediasessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"MediaSessionInfoList"];
    outputObjects = @[mediasessioninfolist];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetMediaSessionInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)ModifyMediaSessionWithTargetMediaSessionID:(NSString*)targetmediasessionid NewMediaCapabilityInfo:(NSString*)newmediacapabilityinfo OutTCMediaCapabilityInfo:(NSMutableString*)tcmediacapabilityinfo{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"TargetMediaSessionID", @"NewMediaCapabilityInfo"];
    parameterObjects = @[targetmediasessionid, newmediacapabilityinfo];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"TCMediaCapabilityInfo"];
    outputObjects = @[tcmediacapabilityinfo];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"ModifyMediaSession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)StartMediaSessionWithTSMediaCapabilityInfo:(NSString*)tsmediacapabilityinfo OutMediaSessionID:(NSMutableString*)mediasessionid OutTCMediaCapabilityInfo:(NSMutableString*)tcmediacapabilityinfo{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"TSMediaCapabilityInfo"];
    parameterObjects = @[tsmediacapabilityinfo];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"MediaSessionID", @"TCMediaCapabilityInfo"];
    outputObjects = @[mediasessionid, tcmediacapabilityinfo];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"StartMediaSession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)StopMediaSessionWithTargetMediaSessionID:(NSString*)targetmediasessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"TargetMediaSessionID"];
    parameterObjects = @[targetmediasessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"StopMediaSession" parameters:parameters returnValues:output];
    return ret;
}



@end
