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


#import "WANConnection2Device.h"


@implementation WANConnection2Device

-(void)dealloc{
    [mPOTSLinkConfig release];
    [mDSLLinkConfig release];
    [mCableLinkConfig release];
    [mEthernetLinkConfig release];
    [mPPPConnection release];
    [mIPConnection release];
    [mIPv6FirewallControl release];

    [super dealloc];
}


-(SoapActionsWANPOTSLinkConfig1*)potsLinkConfig{
    if(mPOTSLinkConfig == nil){
        mPOTSLinkConfig = (SoapActionsWANPOTSLinkConfig1*)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANPOTSLinkConfig:1"] soap];
        [mPOTSLinkConfig retain];
    }
    return mPOTSLinkConfig;
}

-(SoapActionsWANDSLLinkConfig1*)dslLinkConfig{
    if(mDSLLinkConfig == nil){
        mDSLLinkConfig = (SoapActionsWANDSLLinkConfig1*)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANDSLLinkConfig:1"] soap];
        [mDSLLinkConfig retain];
    }
    return mDSLLinkConfig;
}

-(SoapActionsWANCableLinkConfig1*)cableLinkConfig{
    if(mCableLinkConfig == nil){
        mCableLinkConfig = (SoapActionsWANCableLinkConfig1*)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANCableLinkConfig:1"] soap];
        [mCableLinkConfig retain];
    }
    return mCableLinkConfig;
}

-(SoapActionsWANEthernetLinkConfig1*)ethernetLinkConfig{
    if(mEthernetLinkConfig == nil){
        mEthernetLinkConfig = (SoapActionsWANEthernetLinkConfig1*)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANEthernetLinkConfig:1"] soap];
        [mEthernetLinkConfig retain];
    }
    return mEthernetLinkConfig;
}

-(SoapActionsWANPPPConnection1*)pppConnection{
    if(mPPPConnection == nil){
        mPPPConnection = (SoapActionsWANPPPConnection1*)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANPPPConnection:1"] soap];
        [mPPPConnection retain];
    }
    return mPPPConnection;
}

-(SoapActionsWANIPConnection2*)ipConnection{
    if(mIPConnection == nil){
        mIPConnection = (SoapActionsWANIPConnection2*)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANIPConnection:2"] soap];
        [mIPConnection retain];
    }
    return mIPConnection;
}

-(SoapActionsWANIPv6FirewallControl1*)ipv6FirewallControl{
    if(mIPv6FirewallControl == nil){
        mIPv6FirewallControl = (SoapActionsWANIPv6FirewallControl1*)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANIPv6FirewallControl:1"] soap];
        [mIPv6FirewallControl retain];
    }
    return mIPv6FirewallControl;
}



-(BasicUPnPService*)potsLinkConfigService{
    return [self getServiceForType:@"urn:schemas-upnp-org:service:WANPOTSLinkConfig:1"];
}

-(BasicUPnPService*)dslLinkConfigService{
    return [self getServiceForType:@"urn:schemas-upnp-org:service:WANDSLLinkConfig:1"];
}

-(BasicUPnPService*)cableLinkConfigService{
    return [self getServiceForType:@"urn:schemas-upnp-org:service:WANCableLinkConfig:1"];
}

-(BasicUPnPService*)ethernetLinkConfigService{
    return [self getServiceForType:@"urn:schemas-upnp-org:service:WANEthernetLinkConfig:1"];
}

-(BasicUPnPService*)pppConnectionService{
    return [self getServiceForType:@"urn:schemas-upnp-org:service:WANPPPConnection:1"];
}

-(BasicUPnPService*)ipConnectionService{
    return [self getServiceForType:@"urn:schemas-upnp-org:service:WANIPConnection:2"];
}

-(BasicUPnPService*)ipv6FirewallControlService{
    return [self getServiceForType:@"urn:schemas-upnp-org:service:WANIPv6FirewallControl:1"];
}


@end
