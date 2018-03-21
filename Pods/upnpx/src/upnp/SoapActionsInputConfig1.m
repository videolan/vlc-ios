//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import "SoapActionsInputConfig1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsInputConfig1


-(NSInteger)GetInputCapabilityWithOutSupportedCapabilities:(NSMutableString*)supportedcapabilities{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"SupportedCapabilities"];
    outputObjects = @[supportedcapabilities];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetInputCapability" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetInputConnectionListWithOutCurrentConnectionList:(NSMutableString*)currentconnectionlist{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentConnectionList"];
    outputObjects = @[currentconnectionlist];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetInputConnectionList" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetInputSessionWithSelectedCapability:(NSString*)selectedcapability ReceiverInfo:(NSString*)receiverinfo PeerDeviceInfo:(NSString*)peerdeviceinfo ConnectionInfo:(NSString*)connectioninfo OutSessionID:(NSMutableString*)sessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SelectedCapability", @"ReceiverInfo", @"PeerDeviceInfo", @"ConnectionInfo"];
    parameterObjects = @[selectedcapability, receiverinfo, peerdeviceinfo, connectioninfo];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"SessionID"];
    outputObjects = @[sessionid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"SetInputSession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)StartInputSessionWithSessionID:(NSString*)sessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID"];
    parameterObjects = @[sessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"StartInputSession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)StopInputsessionWithSessionID:(NSString*)sessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID"];
    parameterObjects = @[sessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"StopInputsession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SwitchInputSessionWithSessionID:(NSString*)sessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID"];
    parameterObjects = @[sessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SwitchInputSession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetMultiInputModeWithNewMultiInputMode:(NSString*)newmultiinputmode{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"NewMultiInputMode"];
    parameterObjects = @[newmultiinputmode];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetMultiInputMode" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetMonopolizedSenderWithOwnerDeviceInfo:(NSString*)ownerdeviceinfo OwnedSessionID:(NSString*)ownedsessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"OwnerDeviceInfo", @"OwnedSessionID"];
    parameterObjects = @[ownerdeviceinfo, ownedsessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetMonopolizedSender" parameters:parameters returnValues:output];
    return ret;
}



@end
