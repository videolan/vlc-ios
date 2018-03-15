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

#import "SSDPDB_ObjC.h"

#include "ssdpdb.h"
#include "ssdpdbobserver.h"
#include "ssdpdbdevice.h"
#include "upnp.h"
#include <vector>


/**
 C/C++ 
 */
class SSDPDB_Observer_wrapper:public SSDPDBObserver{
public:
    SSDPDB_ObjC* mObjCObserver;
    SSDPDB_Observer_wrapper(SSDPDB_ObjC* observer){
        mObjCObserver = observer;
        UPNP::GetInstance()->GetSSDP()->GetDB()->AddObserver(this);
    }

    ~SSDPDB_Observer_wrapper(){
        UPNP::GetInstance()->GetSSDP()->GetDB()->RemoveObserver(this);
    }

    int SSDPDBMessage(SSDPDBMsg* msg){
        [mObjCObserver SSDPDBUpdate];
        return 0;
    }
private:
    SSDPDB_Observer_wrapper(){}
};


/**
 Obj-C
 */
@implementation SSDPDB_ObjC

@synthesize SSDPObjCDevices;

- (instancetype)init {
    self = [super init];
    if (self) {
        mMutex = [[NSRecursiveLock alloc] init];
        mObservers = [[NSMutableArray<SSDPDB_ObjC_Observer> alloc] init];
        SSDPObjCDevices = [[NSMutableArray alloc] init];

        mWrapper = new SSDPDB_Observer_wrapper(self);
    }
    return self;
}

- (void)dealloc {
    if (mWrapper) {
        delete((SSDPDB_Observer_wrapper *)mWrapper);
    }
    [mObservers removeAllObjects];
    [mObservers release];
    [SSDPObjCDevices removeAllObjects];
    [SSDPObjCDevices release];
    [mMutex release];
    [super dealloc];
}

-(void)lock{
    [mMutex lock];
}

-(void)unlock{
    [mMutex unlock];
}


-(int)startSSDP{
    return UPNP::GetInstance()->GetSSDP()->Start();
}

-(int)stopSSDP{
    return UPNP::GetInstance()->GetSSDP()->Stop();
}

-(int)notifySSDPAlive{
    return UPNP::GetInstance()->GetSSDP()->NotifyAlive();
}

-(int)notifySSDPByeBye{
    return UPNP::GetInstance()->GetSSDP()->NotifyByeBye();
}

-(int)searchSSDP{
    return UPNP::GetInstance()->GetSSDP()->Search();
}

-(int)searchForMediaServer{
    return UPNP::GetInstance()->GetSSDP()->SearchForMediaServer();
}

-(int)searchForMediaRenderer{
    return UPNP::GetInstance()->GetSSDP()->SearchForMediaRenderer();
}

-(int)searchForContentDirectory {
    return UPNP::GetInstance()->GetSSDP()->SearchForContentDirectory();
}

-(NSUInteger)addObserver:(id <SSDPDB_ObjC_Observer>)obs{
    NSUInteger ret = 0;
    [self lock];
    [mObservers addObject:obs];
    ret = [mObservers count];
    [self unlock];
    return ret;
}

-(NSUInteger)removeObserver:(id <SSDPDB_ObjC_Observer>)obs{
    NSUInteger ret = 0;
    [self lock];
    [mObservers removeObject:obs];
    ret = [mObservers count];
    [self unlock];
    return ret;
}

- (void)clearDevices {
    [self lock];

    //Inform the listeners
    id <SSDPDB_ObjC_Observer> obs;
    NSEnumerator *listeners = [mObservers objectEnumerator];
    while ((obs = [listeners nextObject])) {
        [obs SSDPDBWillUpdate:self];
    }

    [self.SSDPObjCDevices removeAllObjects];

    listeners = [mObservers objectEnumerator];
    while ((obs = [listeners nextObject])) {
        [obs SSDPDBUpdated:self];
    }

    [self unlock];

    UPNP::GetInstance()->GetSSDP()->GetDB()->RemoveAllDevices();
}

-(void)setUserAgentProduct:(NSString*)product andOS:(NSString*)os{
    if(os != nil){
        const char *c_os = [os cStringUsingEncoding:NSASCIIStringEncoding];
        if (c_os == NULL)
            return;

        SSDP *ssdp = UPNP::GetInstance()->GetSSDP();
        if (ssdp != NULL)
            ssdp->SetOS(c_os);
    }
    if(product != nil){
        const char *c_product = [product cStringUsingEncoding:NSASCIIStringEncoding];
        if (c_product == NULL)
            return;

        SSDP* ssdp = UPNP::GetInstance()->GetSSDP();
        if (ssdp != NULL)
            ssdp->SetProduct(c_product);
    }
}

- (void)SSDPDBUpdate {
    [NSRunLoop currentRunLoop]; //Start our runloop

    @autoreleasepool {
        id <SSDPDB_ObjC_Observer> obs;

        //Inform the listeners
        NSEnumerator *listeners = [mObservers objectEnumerator];
        while ((obs = [listeners nextObject])) {
            [obs SSDPDBWillUpdate:self];
        }

        [self lock];
        [SSDPObjCDevices removeAllObjects];
        //Update the Obj-C Array
        UPNP::GetInstance()->GetSSDP()->GetDB()->Lock();
        SSDPDBDevice* thisDevice = nil;
        std::vector<SSDPDBDevice*> devices;
        std::vector<SSDPDBDevice*>::const_iterator it;
        devices = UPNP::GetInstance()->GetSSDP()->GetDB()->GetDevices();
        for (it = devices.begin(); it < devices.end(); it++) {
            thisDevice = *it;
            SSDPDBDevice_ObjC *thisObjCDevice = [[SSDPDBDevice_ObjC alloc] initWithCPPDevice:thisDevice];
            [SSDPObjCDevices addObject:thisObjCDevice];
            [thisObjCDevice release];
        }
        UPNP::GetInstance()->GetSSDP()->GetDB()->Unlock();

        //Inform the listeners
        listeners = [mObservers objectEnumerator];
        while ((obs = [listeners nextObject])) {
            [obs SSDPDBUpdated:self];
        }
        [self unlock];
    }
}

@end

/**
 * Device class
 */
@implementation SSDPDBDevice_ObjC

@synthesize isdevice;
@synthesize isroot;
@synthesize isservice;
@synthesize uuid;
@synthesize urn;
@synthesize usn;
@synthesize type;
@synthesize version;
@synthesize host;
@synthesize location;
@synthesize ip;
@synthesize port;


- (instancetype)initWithCPPDevice:(void *)cppDevice {
    self = [super init];
    if (self) {
        SSDPDBDevice *dev = (SSDPDBDevice *)cppDevice;

        isdevice  = dev->isdevice == 1 ? true : false;
        isroot    = dev->isroot == 1 ? true : false;
        isservice = dev->isservice == 1 ? true : false;
        uuid      = [[NSString alloc] initWithCString:dev->uuid.c_str() encoding:NSASCIIStringEncoding];
        urn       = [[NSString alloc] initWithCString:dev->urn.c_str() encoding:NSASCIIStringEncoding];
        usn       = [[NSString alloc] initWithCString:dev->usn.c_str() encoding:NSASCIIStringEncoding];
        type      = [[NSString alloc] initWithCString:dev->type.c_str() encoding:NSASCIIStringEncoding];
        version   = [[NSString alloc] initWithCString:dev->version.c_str() encoding:NSASCIIStringEncoding];
        host      = [[NSString alloc] initWithCString:dev->host.c_str() encoding:NSASCIIStringEncoding];
        location  = [[NSString alloc] initWithCString:dev->location.c_str() encoding:NSASCIIStringEncoding];
        ip        = dev->ip;
        port      = dev->port;
    }
    return self;
}

- (instancetype)init { return nil; }

- (void)dealloc {
    [uuid release];
    [urn release];
    [usn release];
    [type release];
    [version release];
    [host release];
    [location release];

    [super dealloc];
}

@end
