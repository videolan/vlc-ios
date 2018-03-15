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


#import "DeviceFactory.h"

// Specific devices
#import "MediaRenderer1Device.h"
#import "MediaServer1Device.h"
#import "BinaryLight1Device.h"
#import "DimmableLight1Device.h"
#import "WANConnection1Device.h"
#import "DigitalSecurityCamera1Device.h"
#import "InternetGateway2Device.h"
#import "WANConnection2Device.h"
#import "WAN2Device.h"   
#import "LAN1Device.h"   
#import "TelephonyClient1Device.h"
#import "TelephonyServer1Device.h"

@implementation DeviceFactory

- (BasicUPnPDevice *)allocDeviceForSSDPDevice:(SSDPDBDevice_ObjC *)ssdp {
    BasicUPnPDevice *device = nil;

    if ([[ssdp urn] isEqualToString:UPnPMediaRenderer1DeviceURN]) {
        device =  [[MediaRenderer1Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:UPnPMediaServer1DeviceURN]) {
        device =  [[MediaServer1Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:@"urn:schemas-upnp-org:device:BinaryLight:1"]) {
        device =  [[BinaryLight1Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:@"urn:schemas-upnp-org:device:DimmableLight:1"]) {
        device =  [[DimmableLight1Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:@"urn:schemas-upnp-org:device:WANConnectionDevice:1"]) {
        device =  [[WANConnection1Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:@"urn:schemas-upnp-org:device:WANConnectionDevice:2"]) {
        device =  [[WANConnection2Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:@"urn:schemas-upnp-org:device:DigitalSecurityCamera:1"]) {
        device =  [[DigitalSecurityCamera1Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:@"urn:schemas-upnp-org:device:InternetGatewayDevice:2"]) {
        device =  [[InternetGateway2Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:@"urn:schemas-upnp-org:device:WANDevice:2"]) {
        device =  [[WAN2Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:@"urn:schemas-upnp-org:device:LANDevice:1"]) {
        device =  [[LAN1Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:@"urn:schemas-upnp-org:device:TelephonyClient:1"]) {
        device =  [[TelephonyClient1Device alloc] initWithSSDPDevice:ssdp];
    }
    else if ([[ssdp urn] isEqualToString:@"urn:schemas-upnp-org:device:TelephonyServer:1"]) {
        device =  [[TelephonyServer1Device alloc] initWithSSDPDevice:ssdp];
    }
    else{
        device =  [[BasicUPnPDevice alloc] initWithSSDPDevice:ssdp];
    }

    return device;
}

@end
