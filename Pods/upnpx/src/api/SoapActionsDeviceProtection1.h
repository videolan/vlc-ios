//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import <Foundation/Foundation.h>
#import "SoapAction.h"

@interface SoapActionsDeviceProtection1 : SoapAction {
    }

//SOAP

-(NSInteger)SendSetupMessageWithProtocolType:(NSString*)protocoltype InMessage:(NSString*)inmessage OutOutMessage:(NSMutableString*)outmessage;
-(NSInteger)GetSupportedProtocolsWithOutProtocolList:(NSMutableString*)protocollist;
-(NSInteger)GetAssignedRolesWithOutRoleList:(NSMutableString*)rolelist;
-(NSInteger)GetRolesForActionWithDeviceUDN:(NSString*)deviceudn ServiceId:(NSString*)serviceid ActionName:(NSString*)actionname OutRoleList:(NSMutableString*)rolelist OutRestrictedRoleList:(NSMutableString*)restrictedrolelist;
-(NSInteger)GetUserLoginChallengeWithProtocolType:(NSString*)protocoltype Name:(NSString*)name OutSalt:(NSMutableString*)salt OutChallenge:(NSMutableString*)challenge;
-(NSInteger)UserLoginWithProtocolType:(NSString*)protocoltype Challenge:(NSString*)challenge Authenticator:(NSString*)authenticator;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger UserLogout;
-(NSInteger)GetACLDataWithOutACL:(NSMutableString*)acl;
-(NSInteger)AddIdentityListWithIdentityList:(NSString*)identitylist OutIdentityListResult:(NSMutableString*)identitylistresult;
-(NSInteger)RemoveIdentityWithIdentity:(NSString*)identity;
-(NSInteger)SetUserLoginPasswordWithProtocolType:(NSString*)protocoltype Name:(NSString*)name Stored:(NSString*)stored Salt:(NSString*)salt;
-(NSInteger)AddRolesForIdentityWithIdentity:(NSString*)identity RoleList:(NSString*)rolelist;
-(NSInteger)RemoveRolesForIdentityWithIdentity:(NSString*)identity RoleList:(NSString*)rolelist;

@end
