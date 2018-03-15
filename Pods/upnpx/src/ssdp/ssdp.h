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



#ifndef _SSDP_H_
#define _SSDP_H_

#include <arpa/inet.h>
#include <vector>
#include <string>
#include <pthread.h>
#include <sys/select.h>

#include "osal.h"
#include "ssdpobserver.h"
#include "ssdpparser.h"
#include "ssdpdb.h"


#define SSDP_MCAST_ADDRESS    "239.255.255.250"
#define SSDP_MCAST_PORT        1900


class SSDP{
public:
    SSDP();
    virtual ~SSDP();
    int Start();
    int Stop();
    int AddObserver(SSDPObserver* observer);
    int RemoveObserver(SSDPObserver* observer);
    int Advertise();
    int Search();
    int SearchForMediaServer();
    int SearchForMediaRenderer();
    int SearchForContentDirectory();
    int NotifyAlive();
    int NotifyByeBye();
    void SetOS(const char* os);
    void SetProduct(const char* product);
    SSDPDB* GetDB();
private:
    SOCKET mMulticastSocket;
    SOCKET mUnicastSocket;
    struct sockaddr_in mSrcaddr;
    struct sockaddr_in mDstaddr;
    struct sockaddr_in mUnicastSrcaddr;
    struct ip_mreq mMreq;
    struct ip_mreq mMreqU;
    std::vector<SSDPObserver*> mObservers;
    u8 mReadLoop;
    pthread_t mReadThread;
    fd_set mExceptionFDS;
    fd_set mReadFDS;
    fd_set mWriteFDS;
    u16 mTTL;
    std::string mOS;
    std::string mProduct;
    SSDPParser* mParser;
    SSDPDB* mDB;
private:
    int ReadLoop();
    int IncommingMessage(struct sockaddr* sender, u8* buf, u32 len);
    int SendSearchRequest(const char* target);
private:
    static void* sReadLoop(void* data);
private:
    SSDP(const SSDP &src);
    SSDP& operator= (const SSDP &src);

};


#endif //_SSDP_H_