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


#include "basichttpserver.h"
#include "tools.h"
#include "osal.h"

#include <stdlib.h>

BasicHTTPServer::BasicHTTPServer(unsigned short prefferedPort){
    mServer = new SocketServer(prefferedPort);
    mServer->AddObserver(this);
}

BasicHTTPServer::~BasicHTTPServer(){
    delete(mServer);
}

SocketServer* BasicHTTPServer::GetSocketServer(){
    return mServer;
}

int BasicHTTPServer::Start(){
    return mServer->Start();
}

int BasicHTTPServer::Stop(){
    return mServer->Stop();
}

int BasicHTTPServer::AddObserver(BasicHTTPObserver *observer){
    RemoveObserver(observer);
    mObservers.push_back(observer);
    return 0;
}

int BasicHTTPServer::RemoveObserver(BasicHTTPObserver *observer){
    int found = 0;
    int tel = 0;
    std::vector<BasicHTTPObserver*>::iterator it;
    for(it=mObservers.begin();it<mObservers.end();it++){
        if(observer == *it){
            //Remove this one and stop
            found = 1;
            break;
        }
        tel++;
    }
    if(found){
        mObservers.erase(mObservers.begin()+tel);
    }
    return 0;
}

/**
 * SocketServerObserver
 */
int BasicHTTPServer::DataReceived(struct sockaddr_in *sender, size_t len, unsigned char *buf){
    //u8* pos = buf;
    //int poslen = len;

    int ret = 0;
    //int contentlength = 0;

    //Sender
    char senderIP[16];
    unsigned short senderPort;

    char* t = inet_ntoa(sender->sin_addr);
    strcpy(senderIP, t);
    senderPort = ntohs(sender->sin_port);

    char idbuf[25];
    sprintf(idbuf, "%s:%d", senderIP, senderPort);
    string sessionID = idbuf;

    //Do we have a session still open for this ?
    HTTPSession* thisSession = mSessions[sessionID];

    if(thisSession == NULL){
        //No, create
        thisSession = new HTTPSession(senderIP, senderPort);
        mSessions[sessionID] = thisSession;
    }
    ret = thisSession->AddData(buf, (unsigned int)len);

    //Session has all data, send it to the observers
    if(ret == 0){
        //Session complete
        mSessions.erase(sessionID);

        //Inform the observers
        std::vector<BasicHTTPObserver*>::iterator observerIterator;
        for(observerIterator=mObservers.begin();observerIterator<mObservers.end();observerIterator++){
            if( ((BasicHTTPObserver*)*observerIterator)->CanProcessMethod(thisSession->GetMethod()) == true){
                ((BasicHTTPObserver*)*observerIterator)->Request(thisSession->GetSenderIP(), thisSession->GetSenderPort(), thisSession->GetMethod(), thisSession->GetPath(), thisSession->GetVersion(), thisSession->GetHeaders(), (char*)thisSession->GetBody(), thisSession->GetBodyLen());
            }

            std::vector<SocketServerObserver*>::iterator observerIterator;
        }

        delete(thisSession);
    }

    return ret;
}

ssize_t BasicHTTPServer::DataToSend(ssize_t *len, unsigned char **buf){
    if(mObservers.size() == 0){
    //    *len = 0;
        return -1;
    }

    //Only the first observer can send responses
    BasicHTTPObserver *observer = mObservers[0];

    map<string, string> headers;
    int returnCode;
    char* body = NULL;
    unsigned long bodyLen;

    bool bret = observer->Response(&returnCode, &headers, &body, &bodyLen);

    if(body){
        free(body);
    }

    if(!bret){
        return -9;
    }

    //Constuct the http
    *buf = (unsigned char*)malloc(1024);

    //Request line
    if(returnCode == 200){
        sprintf((char*)*buf, "HTTP/1.1 200 OK\r\n\r\n");
        *len = strlen((char*)*buf);
        return *len;
    }

    return -1;//not implemented
}


