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


#import "BasicUPnPDevice.h"
#import "UPnPManager.h"
#import "BasicDeviceParser.h"


@interface BasicUPnPDevice () <UPnPDBObserver> {
    NSMutableArray *mObservers;
    NSRecursiveLock *mMutex;

    NSRecursiveLock *servicesLock;
}
@end

@implementation BasicUPnPDevice

@synthesize isRoot;
@synthesize isFound;
@synthesize isLoadingDescriptionXML;
@synthesize uuid;
@synthesize lastUpdated;
@synthesize xmlLocation;
@synthesize baseURL;
@synthesize baseURLString;
@synthesize friendlyName;
@synthesize manufacturer;
@synthesize manufacturerURL;
@synthesize manufacturerURLString;
@synthesize udn;
@synthesize usn;
@synthesize urn;
@synthesize smallIcon;
@synthesize smallIconWidth;
@synthesize smallIconHeight;
@synthesize smallIconURL;
@synthesize smallIconDepth;
@synthesize type;
@synthesize modelDescription;
@synthesize modelName;
@synthesize modelNumber;
@synthesize modelURL;
@synthesize modelURLString;
@synthesize serialNumber;


- (instancetype)init {
    self = [super init];
    if (self) {
        //NSLog(@"BasicUPnPDevice - init");
        services = [NSMutableDictionary<NSString *, BasicUPnPService *> new];
        lastUpdated = [NSDate timeIntervalSinceReferenceDate];
        smallIconWidth = 0;
        smallIconHeight = 0;
        baseURL = nil;
        baseURLString = nil;

        mObservers = [NSMutableArray new];
        mMutex = [[NSRecursiveLock alloc] init];
        servicesLock = [[NSRecursiveLock alloc] init];

        [[[UPnPManager GetInstance] DB] addObserver:self];
    }

    return self;
}

- (instancetype)initWithSSDPDevice:(SSDPDBDevice_ObjC *)ssdp {
    self = [self init];
    if (self) {
        isRoot = ssdp.isroot;
        uuid = ssdp.uuid;
        [uuid retain];
        [self setUsn:ssdp.usn];
        [self setUrn:ssdp.urn];
        type = [NSString stringWithFormat:@"%@:%@", ssdp.type, ssdp.version];
        [type retain];
        xmlLocation = ssdp.location;
        [xmlLocation retain];
    }
    return self;
}

- (void)dealloc {
    [[[UPnPManager GetInstance] DB] removeObserver:self];

    [services removeAllObjects];
    [services release];
    services = nil;
    [servicesLock release];

    [uuid release];
    [xmlLocation release];
    [baseURL release];
    [baseURLString release];
    [friendlyName release];
    [manufacturer release];
    [manufacturerURL release];
    [manufacturerURLString release];
    [modelDescription release];
    [modelName release];
    [modelNumber release];
    [modelURL release];
    [modelURLString release];
    [serialNumber release];
    [udn release];
    [usn release];
    [urn release];
    [smallIcon release];
    [type release];
    [smallIconURL release];

    [super dealloc];
}

- (int)loadDeviceDescriptionFromXML {
    int ret = 0;
    if (xmlLocation == nil || [xmlLocation length] < 5) {
        return -1;
    }

    BasicDeviceParser *parser = [[BasicDeviceParser alloc] initWithUPnPDevice:self];
    ret = [parser parse];
    [parser release];

    return ret;
}

- (NSUInteger)addObserver:(id <BasicUPnPDeviceObserver>)obs {
    NSUInteger ret = 0;
    [mMutex lock];
    [mObservers addObject:obs];
    ret = [mObservers count];
    [mMutex unlock];
    return ret;
}

- (NSUInteger)removeObserver:(id <BasicUPnPDeviceObserver>)obs {
    NSUInteger ret = 0;
    if ([mMutex tryLock]) {
        [mObservers removeObject:obs];
        ret = [mObservers count];
        [mMutex unlock];
    }
    return ret;
}

/**
 Synchronizes local collection of services with avaiable SSDP "devices"
 @return YES if services were updated, otherwise NO
 */
- (BOOL)syncServices {
    @autoreleasepool {
        //Sync 'services'
        BasicUPnPService *upnpService = nil;
        NSArray<SSDPDBDevice_ObjC *> *ssdpservices = [[[UPnPManager GetInstance] DB] getSSDPServicesForUUID:uuid];

        @synchronized (servicesLock) {
            NSMutableDictionary *toRemove = [services mutableCopy];
            NSMutableDictionary *toAdd = [NSMutableDictionary new];

            for (SSDPDBDevice_ObjC *ssdpService in ssdpservices) {
                upnpService = services[ssdpService.urn];
                if (upnpService == nil) {
                    // We don't have the service, create a new one
                    upnpService = [[BasicUPnPService alloc] initWithSSDPDevice:ssdpService];

                    // We delay initialization of the service until we need it [upnpService process];
                    toAdd[upnpService.urn] = upnpService;
                    [upnpService release];
                }
                else {
                    //remove from toRemove
                    [toRemove removeObjectForKey:[ssdpService urn]];
                }
            }

            // toAdd and toRemove are filled now, first remove services if needed
            for (NSString *key in toRemove) {
                NSLog(@"[UPnP] Sync Service (%@). Removing %@", self.friendlyName, key);
                [services removeObjectForKey:key];
            }
            for (NSString *key in toAdd) {
                NSLog(@"[UPnP] Sync Service (%@). Adding %@", self.friendlyName, key);
                services[key] = toAdd[key];
            }

            [toRemove release];
            [toAdd release];
        }
    }
    return YES;
}

- (NSMutableDictionary<NSString *, BasicUPnPService *> *)getServices {
    [self syncServices];
    return services;
}

- (BasicUPnPService *)getServiceForType:(NSString *)serviceUrn {
    BasicUPnPService *thisService = nil;

    [self syncServices];

    //Get service
    @synchronized (servicesLock) {
        thisService = services[serviceUrn];
        if (thisService != nil) {
            [thisService setup];    // can be called several times, we need to be sure it is done
        }
        else {
            NSLog(@"[UPnP] %s Can't find service of type %@", __FUNCTION__, serviceUrn);
        }
    }

    return thisService;
}

#pragma mark - <UPnPDBObserver>

- (void)UPnPDBUpdated:(UPnPDB *)sender {
    BOOL isChanged = [self syncServices];
    if (isChanged) {
        if ([mMutex tryLock]) {
            NSEnumerator<id <BasicUPnPDeviceObserver>> *listeners = [mObservers objectEnumerator];
            NSObject <BasicUPnPDeviceObserver> *observer = nil;
            while ((observer = [listeners nextObject])) {
                [observer deviceServicesDidUpdate:self];
            }
            [mMutex unlock];
        }
    }
}

@end
