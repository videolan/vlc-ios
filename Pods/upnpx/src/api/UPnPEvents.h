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
#import "BasicHTTPServer_ObjC.h"
#import "UPnPEventParser.h"

NS_ASSUME_NONNULL_BEGIN

//Observer
@protocol UPnPEvents_Observer

- (void)UPnPEvent:(NSDictionary *)events;
- (NSURL *)GetUPnPEventURL;
- (void)subscriptionTimerExpiresIn:(int)seconds timeoutSubscription:(int)timeout timeSubscription:(double)subscribed;

@end


@interface ObserverEntry : NSObject {
    id<UPnPEvents_Observer> observer;
    int timeout;
    double subscriptiontime;
}

@property (readwrite, strong) id<UPnPEvents_Observer> observer;
@property (readwrite) int timeout;
@property (readwrite) double subscriptiontime;

@end


@interface UPnPEvents : NSObject <BasicHTTPServer_ObjC_Observer> {
    NSMutableDictionary *mEventSubscribers;//uuid, observer
    BasicHTTPServer_ObjC *server;
    UPnPEventParser *parser;
    NSRecursiveLock *mMutex;
    NSTimer *mTimeoutTimer;
}


- (void)start;
- (void)stop;

- (void)subscribe:(id<UPnPEvents_Observer>)subscriber completion:(void (^)(NSString * __nullable uuid))completion;
- (void)unsubscribe:(id<UPnPEvents_Observer>)subscriber withSID:(NSString *)uuid;

- (void)manageSubscriptionTimeouts:(NSTimer *)timer;


//BasicHTTPServer_ObjC_Observer
-(BOOL)canProcessMethod:(BasicHTTPServer_ObjC*)sender requestMethod:(NSString*)method;
-(BOOL)request:(BasicHTTPServer_ObjC*)sender method:(NSString*)method path:(NSString*)path version:(NSString*)version headers:(NSDictionary*)headers body:(NSData*)body;
-(BOOL)response:(BasicHTTPServer_ObjC*)sender returncode:(int*)returncode headers:(NSMutableDictionary*)headers body:(NSMutableData*)body;

@end

NS_ASSUME_NONNULL_END
