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


/* WANConnectionDevice:1 Services (O:Optional/R:Required)
 *
 * WANPOTSLinkConfig:1            O for POTS modems
 * WANDSLLinkConfig:1            O for DSL modems
 * WANCableLinkConfig:1            O for Cable modems
 * WANEthernetLinkConfig:1        O for Ethernet attached modems
 * WANPPPConnection:1            R for modems that support PPP based connections
 * WANIPConnection:1            R for modems that support IP based connections
 *
 */


#import <Foundation/Foundation.h>
#import "BasicUPnPDevice.h"
#import "SoapActionsWANIPConnection1.h"
#import "SoapActionsWANPPPConnection1.h"


@interface WANConnection1Device : BasicUPnPDevice {
    SoapActionsWANIPConnection1 *mIPConnection;
    SoapActionsWANPPPConnection1 *mPPPConnection;
}

@property (NS_NONATOMIC_IOSONLY, readonly, strong) SoapActionsWANIPConnection1 *ipConnection;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) SoapActionsWANPPPConnection1 *pppConnection;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) BasicUPnPService *ipConnectionService;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) BasicUPnPService *pppConnectionService;

@end
