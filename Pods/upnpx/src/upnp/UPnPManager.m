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


#import "UPnPManager.h"


static NSTimeInterval const kSSDPRestartDelay = 0.1;


@interface UPnPManager () {
    SSDPDB_ObjC *SSDP;
    UPnPDB *DB;
    DeviceFactory* deviceFactory;
    UPnPEvents *upnpEvents;

    MediaRenderer1Device *defaultMediaRenderer1;
    MediaPlaylist *defaultPlaylist;

    BOOL _inProcessOfRestart;
}

@end


@implementation UPnPManager

@synthesize SSDP;
@synthesize DB;
@synthesize deviceFactory;
@synthesize upnpEvents;
@synthesize defaultMediaRenderer1;
@synthesize defaultPlaylist;

+ (UPnPManager *)GetInstance {
    static UPnPManager *instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[UPnPManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        upnpEvents = [[UPnPEvents alloc] init];
        deviceFactory = [[DeviceFactory alloc] init];
        SSDP = [[SSDPDB_ObjC alloc] init];
        DB = [[UPnPDB alloc] initWithSSDP:SSDP];
        defaultPlaylist = [[MediaPlaylist alloc] init];

        _inProcessOfRestart = NO;

        [SSDP startSSDP];
        [upnpEvents start];
    }

    return self;
}

- (void)dealloc {
    if (upnpEvents != nil) {
        [upnpEvents stop];
    }
    if (SSDP != nil) {
        [SSDP stopSSDP];
        [SSDP release];
    }

    [DB release];
    [deviceFactory release];
    [upnpEvents release];
    [defaultPlaylist release];

    [super dealloc];
}

- (void)clearAllDevices {
    [SSDP clearDevices];
    [DB clearRootDevices];
}

- (void)restartSSDPSearchWithCompletionBlock:(void(^)())completionBlock {
    @synchronized(self) {
        if (_inProcessOfRestart) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSSDPRestartDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (completionBlock != nil) {
                    completionBlock();
                }
            });
            return;
        }

        _inProcessOfRestart = YES;

        if (SSDP != nil) {
            [SSDP stopSSDP];
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSSDPRestartDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SSDP startSSDP];
            _inProcessOfRestart = NO;

            if (completionBlock != nil) {
                completionBlock();
            }
        });
    }
}

@end
