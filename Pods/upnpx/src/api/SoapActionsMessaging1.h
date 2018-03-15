//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import <Foundation/Foundation.h>
#import "SoapAction.h"

@interface SoapActionsMessaging1 : SoapAction {
    }

//SOAP

-(NSInteger)GetTelephonyIdentityWithOutTelephonyIdentity:(NSMutableString*)telephonyidentity;
-(NSInteger)GetMessagingCapabilitiesWithOutSupportedCapabilities:(NSMutableString*)supportedcapabilities;
-(NSInteger)GetNewMessagesWithOutNewMessages:(NSMutableString*)newmessages;
-(NSInteger)SearchMessagesWithMessageClass:(NSString*)messageclass MessageFolder:(NSString*)messagefolder MessageStatus:(NSString*)messagestatus SessionID:(NSString*)sessionid OutMessageList:(NSMutableString*)messagelist;
-(NSInteger)ReadMessageWithMessageID:(NSString*)messageid OutMessageRequested:(NSMutableString*)messagerequested;
-(NSInteger)SendMessageWithMessageToSend:(NSString*)messagetosend OutMessageID:(NSMutableString*)messageid;
-(NSInteger)DeleteMessageWithMessageID:(NSString*)messageid;
-(NSInteger)CreateSessionWithSessionClass:(NSString*)sessionclass SessionRecipients:(NSString*)sessionrecipients Subject:(NSString*)subject SupportedContentType:(NSString*)supportedcontenttype OutSessionID:(NSMutableString*)sessionid;
-(NSInteger)ModifySessionWithSessionID:(NSString*)sessionid SessionRecipientsToAdd:(NSString*)sessionrecipientstoadd SessionRecipientsToRemove:(NSString*)sessionrecipientstoremove Subject:(NSString*)subject SupportedContentType:(NSString*)supportedcontenttype SessionClass:(NSString*)sessionclass;
-(NSInteger)AcceptSessionWithSessionID:(NSString*)sessionid;
-(NSInteger)GetSessionUpdatesWithOutSessionUpdates:(NSMutableString*)sessionupdates;
-(NSInteger)GetSessionsWithSessionID:(NSString*)sessionid SessionClass:(NSString*)sessionclass SessionStatus:(NSString*)sessionstatus OutSessionsList:(NSMutableString*)sessionslist;
-(NSInteger)JoinSessionWithSessionID:(NSString*)sessionid;
-(NSInteger)LeaveSessionWithSessionID:(NSString*)sessionid;
-(NSInteger)CloseSessionWithSessionID:(NSString*)sessionid;
-(NSInteger)StartFileTransferWithFileInfoList:(NSString*)fileinfolist;
-(NSInteger)CancelFileTransferWithSessionID:(NSString*)sessionid;
-(NSInteger)GetFileTransferSessionWithSessionID:(NSString*)sessionid OutFileInfoList:(NSMutableString*)fileinfolist;

@end
