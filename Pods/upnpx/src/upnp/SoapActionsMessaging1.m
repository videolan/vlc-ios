//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import "SoapActionsMessaging1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsMessaging1


-(NSInteger)GetTelephonyIdentityWithOutTelephonyIdentity:(NSMutableString*)telephonyidentity{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"TelephonyIdentity"];
    outputObjects = @[telephonyidentity];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetTelephonyIdentity" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetMessagingCapabilitiesWithOutSupportedCapabilities:(NSMutableString*)supportedcapabilities{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"SupportedCapabilities"];
    outputObjects = @[supportedcapabilities];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetMessagingCapabilities" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetNewMessagesWithOutNewMessages:(NSMutableString*)newmessages{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewMessages"];
    outputObjects = @[newmessages];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetNewMessages" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SearchMessagesWithMessageClass:(NSString*)messageclass MessageFolder:(NSString*)messagefolder MessageStatus:(NSString*)messagestatus SessionID:(NSString*)sessionid OutMessageList:(NSMutableString*)messagelist{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"MessageClass", @"MessageFolder", @"MessageStatus", @"SessionID"];
    parameterObjects = @[messageclass, messagefolder, messagestatus, sessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"MessageList"];
    outputObjects = @[messagelist];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"SearchMessages" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)ReadMessageWithMessageID:(NSString*)messageid OutMessageRequested:(NSMutableString*)messagerequested{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"MessageID"];
    parameterObjects = @[messageid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"MessageRequested"];
    outputObjects = @[messagerequested];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"ReadMessage" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SendMessageWithMessageToSend:(NSString*)messagetosend OutMessageID:(NSMutableString*)messageid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"MessageToSend"];
    parameterObjects = @[messagetosend];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"MessageID"];
    outputObjects = @[messageid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"SendMessage" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)DeleteMessageWithMessageID:(NSString*)messageid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"MessageID"];
    parameterObjects = @[messageid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"DeleteMessage" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)CreateSessionWithSessionClass:(NSString*)sessionclass SessionRecipients:(NSString*)sessionrecipients Subject:(NSString*)subject SupportedContentType:(NSString*)supportedcontenttype OutSessionID:(NSMutableString*)sessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionClass", @"SessionRecipients", @"Subject", @"SupportedContentType"];
    parameterObjects = @[sessionclass, sessionrecipients, subject, supportedcontenttype];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"SessionID"];
    outputObjects = @[sessionid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"CreateSession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)ModifySessionWithSessionID:(NSString*)sessionid SessionRecipientsToAdd:(NSString*)sessionrecipientstoadd SessionRecipientsToRemove:(NSString*)sessionrecipientstoremove Subject:(NSString*)subject SupportedContentType:(NSString*)supportedcontenttype SessionClass:(NSString*)sessionclass{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID", @"SessionRecipientsToAdd", @"SessionRecipientsToRemove", @"Subject", @"SupportedContentType", @"SessionClass"];
    parameterObjects = @[sessionid, sessionrecipientstoadd, sessionrecipientstoremove, subject, supportedcontenttype, sessionclass];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"ModifySession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)AcceptSessionWithSessionID:(NSString*)sessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID"];
    parameterObjects = @[sessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"AcceptSession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetSessionUpdatesWithOutSessionUpdates:(NSMutableString*)sessionupdates{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"SessionUpdates"];
    outputObjects = @[sessionupdates];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetSessionUpdates" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetSessionsWithSessionID:(NSString*)sessionid SessionClass:(NSString*)sessionclass SessionStatus:(NSString*)sessionstatus OutSessionsList:(NSMutableString*)sessionslist{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID", @"SessionClass", @"SessionStatus"];
    parameterObjects = @[sessionid, sessionclass, sessionstatus];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"SessionsList"];
    outputObjects = @[sessionslist];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetSessions" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)JoinSessionWithSessionID:(NSString*)sessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID"];
    parameterObjects = @[sessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"JoinSession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)LeaveSessionWithSessionID:(NSString*)sessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID"];
    parameterObjects = @[sessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"LeaveSession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)CloseSessionWithSessionID:(NSString*)sessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID"];
    parameterObjects = @[sessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"CloseSession" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)StartFileTransferWithFileInfoList:(NSString*)fileinfolist{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"FileInfoList"];
    parameterObjects = @[fileinfolist];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"StartFileTransfer" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)CancelFileTransferWithSessionID:(NSString*)sessionid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID"];
    parameterObjects = @[sessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"CancelFileTransfer" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetFileTransferSessionWithSessionID:(NSString*)sessionid OutFileInfoList:(NSMutableString*)fileinfolist{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SessionID"];
    parameterObjects = @[sessionid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"FileInfoList"];
    outputObjects = @[fileinfolist];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetFileTransferSession" parameters:parameters returnValues:output];
    return ret;
}



@end
