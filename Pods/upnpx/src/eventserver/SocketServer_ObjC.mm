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


#import "SocketServer_ObjC.h"
#import "socketserver.h"
#include "socketServerobserver.h"



class SocketServerObserver_wrapper:public SocketServerObserver{
private:
    SocketServer_ObjC* mObjCObserver;
    SocketServer *mServer;

public:
    SocketServerObserver_wrapper(SocketServer_ObjC* observer, SocketServer *server){
        mObjCObserver = observer;
        mServer = server;
        mServer->AddObserver(this);
    }

    ~SocketServerObserver_wrapper(){
        mServer->RemoveObserver(this);
    }

    int DataReceived(struct sockaddr_in *sender, size_t len, unsigned char *buf){
        [NSRunLoop currentRunLoop];//Start our runloop

        @autoreleasepool {
            unsigned short port = sender->sin_port;
            NSString *ip = [[NSString alloc]  initWithCString:inet_ntoa(sender->sin_addr) encoding:NSASCIIStringEncoding];
            int result = [mObjCObserver dataIn:buf length:len fromIP:ip fromPort:port];;
            [ip release];
            return result;
        }

    }

    ssize_t DataToSend(ssize_t *len, unsigned char **buf){
        return -1;//no data to send
    }

private:
    SocketServerObserver_wrapper(){}
};



@implementation SocketServer_ObjC

-(instancetype)init{
    self = [super init];

    if (self) {
        mCppSocketServer = new SocketServer(42809);
        mCppSocketServerObserverWrapper = new SocketServerObserver_wrapper(self, (SocketServer*)mCppSocketServer);
    }

    return self;
}

-(void)dealloc{
    if (mCppSocketServer) {
        ((SocketServer*)mCppSocketServer)->Stop();
        delete((SocketServer*)mCppSocketServer);
    }

    if (mCppSocketServerObserverWrapper) {
        delete((SocketServerObserver_wrapper*)mCppSocketServerObserverWrapper);
    }

    [super dealloc];
}

-(void)start{
    ((SocketServer*)mCppSocketServer)->Start();
}

-(void)stop{
    ((SocketServer*)mCppSocketServer)->Stop();
}


-(NSString*)getIPAddress{
    char *ip = ((SocketServer*)mCppSocketServer)->getServerIPAddress();

    return @(ip);
}

-(unsigned short)getPort{
    return ((SocketServer*)mCppSocketServer)->getServerPort();
}


-(void)addObserver:(SocketServer_ObjC_Observer*)obs{
    [mObservers addObject:obs];
}

-(void)removeObserver:(SocketServer_ObjC_Observer*)obs{
    [mObservers removeObject:obs];
}


-(int)dataIn:(unsigned char*)data length:(size_t)len fromIP:(NSString*)ipAddress fromPort:(unsigned short)port{
    int ret  = -1;

    SocketServer_ObjC_Observer* obs;

    NSEnumerator *obsenum = [mObservers objectEnumerator];
    while(obs = [obsenum nextObject]){
        [obs DataIn:self withData:data andLen:len fromSource:ipAddress];
    }

    return ret;
}


@end
