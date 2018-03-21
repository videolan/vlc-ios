//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import <Foundation/Foundation.h>
#import "SoapAction.h"

@interface SoapActionsInputConfig1 : SoapAction {
    }

//SOAP

-(NSInteger)GetInputCapabilityWithOutSupportedCapabilities:(NSMutableString*)supportedcapabilities;
-(NSInteger)GetInputConnectionListWithOutCurrentConnectionList:(NSMutableString*)currentconnectionlist;
-(NSInteger)SetInputSessionWithSelectedCapability:(NSString*)selectedcapability ReceiverInfo:(NSString*)receiverinfo PeerDeviceInfo:(NSString*)peerdeviceinfo ConnectionInfo:(NSString*)connectioninfo OutSessionID:(NSMutableString*)sessionid;
-(NSInteger)StartInputSessionWithSessionID:(NSString*)sessionid;
-(NSInteger)StopInputsessionWithSessionID:(NSString*)sessionid;
-(NSInteger)SwitchInputSessionWithSessionID:(NSString*)sessionid;
-(NSInteger)SetMultiInputModeWithNewMultiInputMode:(NSString*)newmultiinputmode;
-(NSInteger)SetMonopolizedSenderWithOwnerDeviceInfo:(NSString*)ownerdeviceinfo OwnedSessionID:(NSString*)ownedsessionid;

@end
