//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import <Foundation/Foundation.h>
#import "SoapAction.h"

@interface SoapActionsCallManagement1 : SoapAction {
    }

//SOAP

-(NSInteger)AcceptCallWithTelCPName:(NSString*)telcpname SecretKey:(NSString*)secretkey TargetCallID:(NSString*)targetcallid MediaCapabilityInfo:(NSString*)mediacapabilityinfo CallMode:(NSString*)callmode;
-(NSInteger)AcceptModifyCallWithTelCPName:(NSString*)telcpname SecretKey:(NSString*)secretkey TargetCallID:(NSString*)targetcallid MediaCapabilityInfo:(NSString*)mediacapabilityinfo;
-(NSInteger)ChangeMonopolizerWithCurrentMonopolizer:(NSString*)currentmonopolizer SecretKey:(NSString*)secretkey TargetCallID:(NSString*)targetcallid NewMonopolizer:(NSString*)newmonopolizer;
-(NSInteger)ChangeTelCPNameWithCurrentTelCPName:(NSString*)currenttelcpname CurrentSecretKey:(NSString*)currentsecretkey NewTelCPName:(NSString*)newtelcpname OutNewSecretKey:(NSMutableString*)newsecretkey OutExpires:(NSMutableString*)expires;
-(NSInteger)ClearCallBackWithCallBackID:(NSString*)callbackid;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger ClearCallLogs;
-(NSInteger)GetCallBackInfoWithOutCallBackInfo:(NSMutableString*)callbackinfo;
-(NSInteger)GetCallInfoWithTelCPName:(NSString*)telcpname SecretKey:(NSString*)secretkey TargetCallID:(NSString*)targetcallid OutCallInfoList:(NSMutableString*)callinfolist;
-(NSInteger)GetCallLogsWithOutCallLogs:(NSMutableString*)calllogs;
-(NSInteger)GetMediaCapabilitiesWithTCMediaCapabilityInfo:(NSString*)tcmediacapabilityinfo OutSupportedMediaCapabilityInfo:(NSMutableString*)supportedmediacapabilityinfo;
-(NSInteger)GetTelephonyIdentityWithOutTelephonyIdentity:(NSMutableString*)telephonyidentity;
-(NSInteger)GetTelCPNameListWithOutTelCPNameList:(NSMutableString*)telcpnamelist;
-(NSInteger)InitiateCallWithCalleeID:(NSString*)calleeid OutCallID:(NSMutableString*)callid;
-(NSInteger)ModifyCallWithTelCPName:(NSString*)telcpname SecretKey:(NSString*)secretkey TargetCallID:(NSString*)targetcallid MediaCapabilityInfo:(NSString*)mediacapabilityinfo;
-(NSInteger)RegisterCallBackWithCalleeID:(NSString*)calleeid OutCallBackID:(NSMutableString*)callbackid;
-(NSInteger)RegisterTelCPNameWithTelCPName:(NSString*)telcpname CurrentSecretKey:(NSString*)currentsecretkey OutNewSecretKey:(NSMutableString*)newsecretkey OutExpires:(NSMutableString*)expires;
-(NSInteger)RejectCallWithTelCPName:(NSString*)telcpname SecretKey:(NSString*)secretkey TargetCallID:(NSString*)targetcallid RejectReason:(NSString*)rejectreason;
-(NSInteger)StartCallWithTelCPName:(NSString*)telcpname SecretKey:(NSString*)secretkey CalleeID:(NSString*)calleeid CallPriority:(NSString*)callpriority MediaCapabilityInfo:(NSString*)mediacapabilityinfo CallMode:(NSString*)callmode OutCallID:(NSMutableString*)callid;
-(NSInteger)StartMediaTransferWithTelCPName:(NSString*)telcpname SecretKey:(NSString*)secretkey TargetCallID:(NSString*)targetcallid TCList:(NSString*)tclist MediaCapabilityInfo:(NSString*)mediacapabilityinfo;
-(NSInteger)StopCallWithTelCPName:(NSString*)telcpname SecretKey:(NSString*)secretkey CallID:(NSString*)callid;
-(NSInteger)UnregisterTelCPNameWithTelCPName:(NSString*)telcpname SecretKey:(NSString*)secretkey;

@end
