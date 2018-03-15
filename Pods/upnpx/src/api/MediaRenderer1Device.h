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
#import "SoapActionsRenderingControl1.h"
#import "SoapActionsConnectionManager1.h"

#import "MediaPlaylist.h"
#import "MediaServer1BasicObject.h"


/*
 * Services:
 * M - RenderingControl:1.0 
 * M - ConnectionManager:1.0 
 * O - AVTransport:1.0 
 */

FOUNDATION_EXPORT NSString *const UPnPMediaRenderer1DeviceURN;

@interface MediaRenderer1Device : BasicUPnPDevice <BasicUPnPServiceObserver> {
    SoapActionsAVTransport1 *mAvTransport;
    SoapActionsRenderingControl1 *mRenderingControl;
    SoapActionsConnectionManager1 *mConnectionManager;

    //Cache
    NSMutableString *mProtocolInfoSource;
    NSMutableString *mProtocolInfoSink;

    //Playlist
    MediaPlaylist *playList;
}

@property (NS_NONATOMIC_IOSONLY, readonly, strong) SoapActionsAVTransport1 *avTransport;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) SoapActionsRenderingControl1 *renderingControl;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) SoapActionsConnectionManager1 *connectionManager;

#pragma mark - Provided Services
@property (NS_NONATOMIC_IOSONLY, readonly, strong) BasicUPnPService *avTransportService;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) BasicUPnPService *renderingControlService;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) BasicUPnPService *connectionManagerService;

- (BOOL)supportProtocol:(NSString *)protocolInfo withCache:(BOOL)useCache;

#pragma mark - Playing Media
@property (NS_NONATOMIC_IOSONLY, readonly) int play;
- (int)playWithMedia:(MediaServer1BasicObject *)media;

@property (readonly) MediaPlaylist *playList;

@end
