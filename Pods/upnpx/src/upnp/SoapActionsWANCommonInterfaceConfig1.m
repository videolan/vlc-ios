//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import "SoapActionsWANCommonInterfaceConfig1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsWANCommonInterfaceConfig1


-(NSInteger)SetEnabledForInternetWithNewEnabledForInternet:(NSString*)newenabledforinternet{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewEnabledForInternet"];
    parameterObjects = @[newenabledforinternet];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetEnabledForInternet" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetEnabledForInternetWithOutNewEnabledForInternet:(NSMutableString*)newenabledforinternet{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewEnabledForInternet"];
    outputObjects = @[newenabledforinternet];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetEnabledForInternet" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetCommonLinkPropertiesWithOutNewWANAccessType:(NSMutableString*)newwanaccesstype OutNewLayer1UpstreamMaxBitRate:(NSMutableString*)newlayer1upstreammaxbitrate OutNewLayer1DownstreamMaxBitRate:(NSMutableString*)newlayer1downstreammaxbitrate OutNewPhysicalLinkStatus:(NSMutableString*)newphysicallinkstatus{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewWANAccessType", @"NewLayer1UpstreamMaxBitRate", @"NewLayer1DownstreamMaxBitRate", @"NewPhysicalLinkStatus"];
    outputObjects = @[newwanaccesstype, newlayer1upstreammaxbitrate, newlayer1downstreammaxbitrate, newphysicallinkstatus];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetCommonLinkProperties" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetWANAccessProviderWithOutNewWANAccessProvider:(NSMutableString*)newwanaccessprovider{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewWANAccessProvider"];
    outputObjects = @[newwanaccessprovider];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetWANAccessProvider" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetMaximumActiveConnectionsWithOutNewMaximumActiveConnections:(NSMutableString*)newmaximumactiveconnections{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewMaximumActiveConnections"];
    outputObjects = @[newmaximumactiveconnections];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetMaximumActiveConnections" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetTotalBytesSentWithOutNewTotalBytesSent:(NSMutableString*)newtotalbytessent{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewTotalBytesSent"];
    outputObjects = @[newtotalbytessent];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetTotalBytesSent" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetTotalBytesReceivedWithOutNewTotalBytesReceived:(NSMutableString*)newtotalbytesreceived{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewTotalBytesReceived"];
    outputObjects = @[newtotalbytesreceived];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetTotalBytesReceived" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetTotalPacketsSentWithOutNewTotalPacketsSent:(NSMutableString*)newtotalpacketssent{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewTotalPacketsSent"];
    outputObjects = @[newtotalpacketssent];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetTotalPacketsSent" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetTotalPacketsReceivedWithOutNewTotalPacketsReceived:(NSMutableString*)newtotalpacketsreceived{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewTotalPacketsReceived"];
    outputObjects = @[newtotalpacketsreceived];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetTotalPacketsReceived" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetActiveConnectionWithNewActiveConnectionIndex:(NSString*)newactiveconnectionindex OutNewActiveConnDeviceContainer:(NSMutableString*)newactiveconndevicecontainer OutNewActiveConnectionServiceID:(NSMutableString*)newactiveconnectionserviceid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewActiveConnectionIndex"];
    parameterObjects = @[newactiveconnectionindex];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewActiveConnDeviceContainer", @"NewActiveConnectionServiceID"];
    outputObjects = @[newactiveconndevicecontainer, newactiveconnectionserviceid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetActiveConnection" parameters:parameters returnValues:output];
    return ret;
}



@end
