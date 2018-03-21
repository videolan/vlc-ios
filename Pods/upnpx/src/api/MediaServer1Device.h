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
#import "BasicUPnPDevice.h"

#import "SoapActionsAVTransport1.h"
#import "SoapActionsConnectionManager1.h"
#import "SoapActionsContentDirectory1.h"

/*
 * Services:
 * M - ContentDirectory:1.0 
 * M - ConnectionManager:1.0 
 * O - AVTransport:1.0 
 */

FOUNDATION_EXPORT NSString *const UPnPMediaServer1DeviceURN;

@interface MediaServer1Device : BasicUPnPDevice {
    SoapActionsAVTransport1 *mAvTransport;
    SoapActionsConnectionManager1 *mConnectionManager;
    SoapActionsContentDirectory1 *mContentDirectory;
}

@property (NS_NONATOMIC_IOSONLY, readonly, strong) SoapActionsAVTransport1 *avTransport;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) SoapActionsConnectionManager1 *connectionManager;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) SoapActionsContentDirectory1 *contentDirectory;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) BasicUPnPService *avTransportService;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) BasicUPnPService *connectionManagerService;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) BasicUPnPService *contentDirectoryService;

@end
