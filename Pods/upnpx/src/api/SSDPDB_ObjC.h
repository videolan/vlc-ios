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

@class SSDPDB_ObjC, SSDPDB_ObjC_Observer, SSDPDBDevice_ObjC;

/**
 * Interface
 */
@protocol SSDPDB_ObjC_Observer

- (void)SSDPDBUpdated:(SSDPDB_ObjC *)sender;
- (void)SSDPDBWillUpdate:(SSDPDB_ObjC *)sender;

@end


/**
 * DB Class
 */
@interface SSDPDB_ObjC : NSObject {
@public
    NSMutableArray<SSDPDB_ObjC_Observer> *mObservers;

@private
    void *mWrapper;
    NSRecursiveLock *mMutex;
    NSMutableArray *SSDPObjCDevices;
}

@property(readonly, retain) NSMutableArray *SSDPObjCDevices;

- (void)lock;
- (void)unlock;

@property (NS_NONATOMIC_IOSONLY, readonly) int startSSDP;
@property (NS_NONATOMIC_IOSONLY, readonly) int stopSSDP;
@property (NS_NONATOMIC_IOSONLY, readonly) int searchSSDP;
@property (NS_NONATOMIC_IOSONLY, readonly) int searchForMediaServer;
@property (NS_NONATOMIC_IOSONLY, readonly) int searchForMediaRenderer;
@property (NS_NONATOMIC_IOSONLY, readonly) int searchForContentDirectory;
@property (NS_NONATOMIC_IOSONLY, readonly) int notifySSDPAlive;
@property (NS_NONATOMIC_IOSONLY, readonly) int notifySSDPByeBye;

- (NSUInteger)addObserver:(id <SSDPDB_ObjC_Observer>)obs;
- (NSUInteger)removeObserver:(id <SSDPDB_ObjC_Observer>)obs;

- (void)clearDevices;

- (void)SSDPDBUpdate;
- (void)setUserAgentProduct:(NSString*)product andOS:(NSString*)os;

@end

/**
 Device class
*/
@interface SSDPDBDevice_ObjC : NSObject {
@private
    bool isdevice;
    bool isroot;
    bool isservice;
    NSString *uuid;
    NSString *urn;
    NSString *usn;
    NSString *type;
    NSString *version;
    NSString *host;
    NSString *location;

    unsigned int ip;
    unsigned short port;
}

- (instancetype)initWithCPPDevice:(void*)cppDevice NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) bool isdevice;
@property (readonly) bool isroot;
@property (readonly) bool isservice;
@property (readonly) NSString *uuid;
@property (readonly) NSString *urn;
@property (readonly) NSString *usn;
@property (readonly) NSString *type;
@property (readonly) NSString *version;
@property (readonly) NSString *host;
@property (readonly) NSString *location;
@property (readonly) unsigned int ip;
@property (readonly) unsigned short port;

@end