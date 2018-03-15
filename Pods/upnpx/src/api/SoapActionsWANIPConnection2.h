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



#import <Foundation/Foundation.h>
#import "SoapAction.h"

@interface SoapActionsWANIPConnection2 : SoapAction {
    }

//SOAP

-(NSInteger)SetConnectionTypeWithNewConnectionType:(NSString*)newconnectiontype;
-(NSInteger)GetConnectionTypeInfoWithOutNewConnectionType:(NSMutableString*)newconnectiontype OutNewPossibleConnectionTypes:(NSMutableString*)newpossibleconnectiontypes;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger RequestConnection;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger RequestTermination;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger ForceTermination;
-(NSInteger)SetAutoDisconnectTimeWithNewAutoDisconnectTime:(NSString*)newautodisconnecttime;
-(NSInteger)SetIdleDisconnectTimeWithNewIdleDisconnectTime:(NSString*)newidledisconnecttime;
-(NSInteger)SetWarnDisconnectDelayWithNewWarnDisconnectDelay:(NSString*)newwarndisconnectdelay;
-(NSInteger)GetStatusInfoWithOutNewConnectionStatus:(NSMutableString*)newconnectionstatus OutNewLastConnectionError:(NSMutableString*)newlastconnectionerror OutNewUptime:(NSMutableString*)newuptime;
-(NSInteger)GetAutoDisconnectTimeWithOutNewAutoDisconnectTime:(NSMutableString*)newautodisconnecttime;
-(NSInteger)GetIdleDisconnectTimeWithOutNewIdleDisconnectTime:(NSMutableString*)newidledisconnecttime;
-(NSInteger)GetWarnDisconnectDelayWithOutNewWarnDisconnectDelay:(NSMutableString*)newwarndisconnectdelay;
-(NSInteger)GetNATRSIPStatusWithOutNewRSIPAvailable:(NSMutableString*)newrsipavailable OutNewNATEnabled:(NSMutableString*)newnatenabled;
-(NSInteger)GetGenericPortMappingEntryWithNewPortMappingIndex:(NSString*)newportmappingindex OutNewRemoteHost:(NSMutableString*)newremotehost OutNewExternalPort:(NSMutableString*)newexternalport OutNewProtocol:(NSMutableString*)newprotocol OutNewInternalPort:(NSMutableString*)newinternalport OutNewInternalClient:(NSMutableString*)newinternalclient OutNewEnabled:(NSMutableString*)newenabled OutNewPortMappingDescription:(NSMutableString*)newportmappingdescription OutNewLeaseDuration:(NSMutableString*)newleaseduration;
-(NSInteger)GetSpecificPortMappingEntryWithNewRemoteHost:(NSString*)newremotehost NewExternalPort:(NSString*)newexternalport NewProtocol:(NSString*)newprotocol OutNewInternalPort:(NSMutableString*)newinternalport OutNewInternalClient:(NSMutableString*)newinternalclient OutNewEnabled:(NSMutableString*)newenabled OutNewPortMappingDescription:(NSMutableString*)newportmappingdescription OutNewLeaseDuration:(NSMutableString*)newleaseduration;
-(NSInteger)AddPortMappingWithNewRemoteHost:(NSString*)newremotehost NewExternalPort:(NSString*)newexternalport NewProtocol:(NSString*)newprotocol NewInternalPort:(NSString*)newinternalport NewInternalClient:(NSString*)newinternalclient NewEnabled:(NSString*)newenabled NewPortMappingDescription:(NSString*)newportmappingdescription NewLeaseDuration:(NSString*)newleaseduration;
-(NSInteger)DeletePortMappingWithNewRemoteHost:(NSString*)newremotehost NewExternalPort:(NSString*)newexternalport NewProtocol:(NSString*)newprotocol;
-(NSInteger)DeletePortMappingRangeWithNewStartPort:(NSString*)newstartport NewEndPort:(NSString*)newendport NewProtocol:(NSString*)newprotocol NewManage:(NSString*)newmanage;
-(NSInteger)GetExternalIPAddressWithOutNewExternalIPAddress:(NSMutableString*)newexternalipaddress;
-(NSInteger)GetListOfPortMappingsWithNewStartPort:(NSString*)newstartport NewEndPort:(NSString*)newendport NewProtocol:(NSString*)newprotocol NewManage:(NSString*)newmanage NewNumberOfPorts:(NSString*)newnumberofports OutNewPortListing:(NSMutableString*)newportlisting;
-(NSInteger)AddAnyPortMappingWithNewRemoteHost:(NSString*)newremotehost NewExternalPort:(NSString*)newexternalport NewProtocol:(NSString*)newprotocol NewInternalPort:(NSString*)newinternalport NewInternalClient:(NSString*)newinternalclient NewEnabled:(NSString*)newenabled NewPortMappingDescription:(NSString*)newportmappingdescription NewLeaseDuration:(NSString*)newleaseduration OutNewReservedPort:(NSMutableString*)newreservedport;

@end
