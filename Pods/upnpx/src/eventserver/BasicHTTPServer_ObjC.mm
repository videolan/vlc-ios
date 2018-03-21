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


#import "BasicHTTPServer_ObjC.h"

#include "basichttpserver.h"
#include "basichttpobserver.h"


class BasicHTTPObserver_wrapper : public BasicHTTPObserver {
private:
    BasicHTTPServer_ObjC* mObjCServer;
    BasicHTTPServer *mCPPServer;
    NSArray *mObjCObservers;

public:
    BasicHTTPObserver_wrapper (BasicHTTPServer_ObjC *objcServer) {
        mObjCServer = objcServer;
        mObjCObservers = [objcServer getObservers];//BasicHTTPServer_ObjC_Observer
        mCPPServer = new BasicHTTPServer(52809);
        mCPPServer->AddObserver(this);
    }

    ~BasicHTTPObserver_wrapper() {
        mCPPServer->RemoveObserver(this);
        delete(mCPPServer);
    }

    BasicHTTPServer* GetServer() {
        return mCPPServer;
    }

    int Start() {
        return mCPPServer->Start();
    }

    int Stop() {
        return mCPPServer->Stop();
    }

    //Observer functions
    bool CanProcessMethod(string *method) {
        [NSRunLoop currentRunLoop];//Start our runloop

        @autoreleasepool {
            BasicHTTPServer_ObjC_Observer *obs = nil;
            NSString *request = [[NSString alloc] initWithCString:method->c_str() encoding:NSASCIIStringEncoding];

            BOOL ret = NO;
            NSEnumerator *obsenum = [mObjCObservers objectEnumerator];
            while((obs = [obsenum nextObject])){
                ret = [obs canProcessMethod:mObjCServer requestMethod:request];
            }

            [request release];

            return (ret==YES? true: false);
        }
    }

    bool Request(char *senderIP, unsigned short senderPort, string *method, string *path, string *version, map<string, string> *headers, char *body, int bodylen) {

        if (strlen(body) != bodylen) {
            NSLog(@"[UPnP] ERROR: real bodylen is %d, received bodylen is %zu \n Content: %s", bodylen, strlen(body), body);
            bodylen = (int)strlen(body);
        }

        @autoreleasepool {
            NSString *oMethod = [[NSString alloc] initWithCString:method->c_str() encoding:NSASCIIStringEncoding];
            NSString *oPath = [[NSString alloc] initWithCString:path->c_str() encoding:NSASCIIStringEncoding];
            NSString *oVersion = [[NSString alloc] initWithCString:version->c_str() encoding:NSASCIIStringEncoding];
            NSMutableDictionary *oHeaders = [[NSMutableDictionary alloc] init];

            for (map<string,string>::const_iterator it=headers->begin() ;it != headers->end();it++ ){
                NSString *header = [[NSString alloc] initWithCString:(*it).first.c_str() encoding:NSASCIIStringEncoding];
                NSString *value = [[NSString alloc] initWithCString:(*it).second.c_str() encoding:NSASCIIStringEncoding];
                NSString *upperHeader = [header uppercaseString];
                oHeaders[upperHeader] = value;
                [value release];
                [header release];
            }
            NSData *oBody = nil;
            if (bodylen >= 0) {
                oBody = [[NSData alloc] initWithBytes:body length:bodylen];
            }

            BOOL ret = NO;
            BasicHTTPServer_ObjC_Observer *obs = nil;
            NSEnumerator *obsenum = [mObjCObservers objectEnumerator];
            while ((obs = [obsenum nextObject])) {
                ret = [obs request:mObjCServer method:oMethod path:oPath version:oVersion headers:oHeaders body:oBody];
            }

            [oMethod release];
            [oPath release];
            [oVersion release];
            [oHeaders release];
            [oBody release];

            return (bool)ret;
        }
    }

    bool Response (int *returncode, map<string, string> *headers, char **body, unsigned long *bodylen) {
        @autoreleasepool {
            BOOL ret = NO;

            int oReturnCode;
            NSMutableDictionary *oHeaders = [[NSMutableDictionary alloc] init];
            NSMutableData *oBody = [[NSMutableData alloc] init];

            headers->clear();

            string value;
            string name;

            BasicHTTPServer_ObjC_Observer *obs = nil;
            if ([mObjCObservers count] > 0) {
                //Only the first observer can respond
                obs = mObjCObservers[0];

                oReturnCode = -1;
                [oHeaders removeAllObjects];
                [oBody setLength:0];
                ret = [obs response:mObjCServer returncode:&oReturnCode headers:oHeaders body:oBody];
                if (ret) {
                    *returncode = oReturnCode;
                    *bodylen = [oBody length];
                    if (*bodylen > 0) {
                        *body = (char *)malloc([oBody length]);//must be deleted by the caller (!!!)
                        memcpy(*body, [oBody bytes], [oBody length]);
                    }
                    for (id key in oHeaders) {
                        value = [(NSString *)oHeaders[key] cStringUsingEncoding: NSASCIIStringEncoding];
                        name = [(NSString *)key cStringUsingEncoding: NSASCIIStringEncoding];
                        (*headers)[name] = value;
                    }
                }
            }

            [oHeaders release];
            [oBody release];

            return (bool)ret;
        }
    }
};

@implementation BasicHTTPServer_ObjC

- (instancetype)init {
    self = [super init];

    if (self) {
        mObservers = [[NSMutableArray alloc] init];
        httpServerWrapper = new BasicHTTPObserver_wrapper(self);
    }

    return self;
}

- (void)dealloc {
    [self stop];
    if (httpServerWrapper) {
        delete((BasicHTTPObserver_wrapper*)httpServerWrapper);
    }
    [mObservers release];

    [super dealloc];
}

- (int)start {
    return ((BasicHTTPObserver_wrapper*)httpServerWrapper)->Start();
}

- (int)stop {
    return ((BasicHTTPObserver_wrapper*)httpServerWrapper)->Stop();
}

- (void)addObserver:(BasicHTTPServer_ObjC_Observer *)observer {
    [mObservers addObject:observer];
}

- (void)removeObserver:(BasicHTTPServer_ObjC_Observer *)observer {
    [mObservers removeObject:observer];
}

- (NSMutableArray *)getObservers {
    return mObservers;
}

- (NSString *)getIPAddress {
    char *ip = ((BasicHTTPObserver_wrapper*)httpServerWrapper)->GetServer()->GetSocketServer()->getServerIPAddress();

    return @(ip);
}

- (unsigned short)getPort {
    return ((BasicHTTPObserver_wrapper*)httpServerWrapper)->GetServer()->GetSocketServer()->getServerPort();
}

@end
