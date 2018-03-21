// ******************************************************************
//
// MIT License.
// This file is part of upnpx.
//
// Copyright (c) 2010, 2011 Bruno Keymolen, email: bruno.keymolen@gmail.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// ******************************************************************

#import <Foundation/Foundation.h>
#import "SoapAction.h"

@interface SoapActionsWANPPPConnection1 : SoapAction {
    }

//SOAP

-(NSInteger)SetConnectionTypeWithNewConnectionType:(NSString*)newconnectiontype;
-(NSInteger)GetConnectionTypeInfoWithOutNewConnectionType:(NSMutableString*)newconnectiontype OutNewPossibleConnectionTypes:(NSMutableString*)newpossibleconnectiontypes;
-(NSInteger)ConfigureConnectionWithNewUserName:(NSString*)newusername NewPassword:(NSString*)newpassword;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger RequestConnection;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger RequestTermination;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger ForceTermination;
-(NSInteger)SetAutoDisconnectTimeWithNewAutoDisconnectTime:(NSString*)newautodisconnecttime;
-(NSInteger)SetIdleDisconnectTimeWithNewIdleDisconnectTime:(NSString*)newidledisconnecttime;
-(NSInteger)SetWarnDisconnectDelayWithNewWarnDisconnectDelay:(NSString*)newwarndisconnectdelay;
-(NSInteger)GetStatusInfoWithOutNewConnectionStatus:(NSMutableString*)newconnectionstatus OutNewLastConnectionError:(NSMutableString*)newlastconnectionerror OutNewUptime:(NSMutableString*)newuptime;
-(NSInteger)GetLinkLayerMaxBitRatesWithOutNewUpstreamMaxBitRate:(NSMutableString*)newupstreammaxbitrate OutNewDownstreamMaxBitRate:(NSMutableString*)newdownstreammaxbitrate;
-(NSInteger)GetPPPEncryptionProtocolWithOutNewPPPEncryptionProtocol:(NSMutableString*)newpppencryptionprotocol;
-(NSInteger)GetPPPCompressionProtocolWithOutNewPPPCompressionProtocol:(NSMutableString*)newpppcompressionprotocol;
-(NSInteger)GetPPPAuthenticationProtocolWithOutNewPPPAuthenticationProtocol:(NSMutableString*)newpppauthenticationprotocol;
-(NSInteger)GetUserNameWithOutNewUserName:(NSMutableString*)newusername;
-(NSInteger)GetPasswordWithOutNewPassword:(NSMutableString*)newpassword;
-(NSInteger)GetAutoDisconnectTimeWithOutNewAutoDisconnectTime:(NSMutableString*)newautodisconnecttime;
-(NSInteger)GetIdleDisconnectTimeWithOutNewIdleDisconnectTime:(NSMutableString*)newidledisconnecttime;
-(NSInteger)GetWarnDisconnectDelayWithOutNewWarnDisconnectDelay:(NSMutableString*)newwarndisconnectdelay;
-(NSInteger)GetNATRSIPStatusWithOutNewRSIPAvailable:(NSMutableString*)newrsipavailable OutNewNATEnabled:(NSMutableString*)newnatenabled;
-(NSInteger)GetGenericPortMappingEntryWithNewPortMappingIndex:(NSString*)newportmappingindex OutNewRemoteHost:(NSMutableString*)newremotehost OutNewExternalPort:(NSMutableString*)newexternalport OutNewProtocol:(NSMutableString*)newprotocol OutNewInternalPort:(NSMutableString*)newinternalport OutNewInternalClient:(NSMutableString*)newinternalclient OutNewEnabled:(NSMutableString*)newenabled OutNewPortMappingDescription:(NSMutableString*)newportmappingdescription OutNewLeaseDuration:(NSMutableString*)newleaseduration;
-(NSInteger)GetSpecificPortMappingEntryWithNewRemoteHost:(NSString*)newremotehost NewExternalPort:(NSString*)newexternalport NewProtocol:(NSString*)newprotocol OutNewInternalPort:(NSMutableString*)newinternalport OutNewInternalClient:(NSMutableString*)newinternalclient OutNewEnabled:(NSMutableString*)newenabled OutNewPortMappingDescription:(NSMutableString*)newportmappingdescription OutNewLeaseDuration:(NSMutableString*)newleaseduration;
-(NSInteger)AddPortMappingWithNewRemoteHost:(NSString*)newremotehost NewExternalPort:(NSString*)newexternalport NewProtocol:(NSString*)newprotocol NewInternalPort:(NSString*)newinternalport NewInternalClient:(NSString*)newinternalclient NewEnabled:(NSString*)newenabled NewPortMappingDescription:(NSString*)newportmappingdescription NewLeaseDuration:(NSString*)newleaseduration;
-(NSInteger)DeletePortMappingWithNewRemoteHost:(NSString*)newremotehost NewExternalPort:(NSString*)newexternalport NewProtocol:(NSString*)newprotocol;
-(NSInteger)GetExternalIPAddressWithOutNewExternalIPAddress:(NSMutableString*)newexternalipaddress;

@end
