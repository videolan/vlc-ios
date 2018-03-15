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


#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include "ssdp.h"
#include "tools.h"

#include <iostream>
#include <string>
#include <sstream>

SSDP::SSDP():mMulticastSocket(INVALID_SOCKET), mUnicastSocket(INVALID_SOCKET), mReadLoop(0), mTTL(2), mOS("mac/1.0"), mProduct("upnpx/1.0"){
    mDB = new SSDPDB();
    mDB->Start();
    mParser = new SSDPParser(mDB);
}


SSDP::~SSDP(){
    Stop();
    delete(mParser);
    mParser = NULL;
    mDB->Stop();
    delete(mDB);
    mDB = NULL;
}


int SSDP::Start(){
    int ret = 0;
    u32 optval = 0;

    if(mMulticastSocket != INVALID_SOCKET || mUnicastSocket != INVALID_SOCKET){
        ret = -9;
        goto EXIT;
    }

    //
    //Setup the Multicast Socket
    //
    mMulticastSocket = socket(PF_INET, SOCK_DGRAM, 0);
    STATNVAL(mMulticastSocket, INVALID_SOCKET, EXIT);

    //Set nonblocking
    optval = fcntl( mMulticastSocket, F_GETFL, 0 );
    STATNVAL(optval, -1,  CLEAN_AND_EXIT);
    ret = fcntl(mMulticastSocket, F_SETFL, optval | O_NONBLOCK);
    STATNVAL(ret, -1,  CLEAN_AND_EXIT);

    //Source address
    mSrcaddr.sin_family = PF_INET;
    mSrcaddr.sin_port = 0;//Let the IP stack decide
    mSrcaddr.sin_addr.s_addr = INADDR_ANY;//Default multicast nic

    //Reuse port
    optval = 1;
    ret = setsockopt(mMulticastSocket, SOL_SOCKET, SO_REUSEADDR, (char*)&optval, 4);
    STATVAL(ret, 0, CLEAN_AND_EXIT);
    optval = 1;
    ret = setsockopt(mMulticastSocket, SOL_SOCKET, SO_REUSEPORT, (char*)&optval, 4);
    STATVAL(ret, 0, CLEAN_AND_EXIT);

    //Never generate SIGPIPE on broken write
    optval = 1;
    ret = setsockopt(mMulticastSocket, SOL_SOCKET, SO_NOSIGPIPE, (void *)&optval, sizeof(int));
    STATVAL(ret, 0, CLEAN_AND_EXIT);

    //Disable loopback
    optval = 0;
    ret = setsockopt(mMulticastSocket, IPPROTO_IP, IP_MULTICAST_LOOP, (char*)&optval, sizeof(int));
    STATNVAL(ret, SOCKET_ERROR, CLEAN_AND_EXIT);

    //TTL
    optval = mTTL;
    ret = setsockopt(mMulticastSocket, IPPROTO_IP, IP_MULTICAST_TTL, (char*)&optval, sizeof(int));
    STATNVAL(ret, SOCKET_ERROR, CLEAN_AND_EXIT);

    //buffer size
    optval = 5000;
    ret = setsockopt(mMulticastSocket, SOL_SOCKET, SO_SNDBUF, (char*)&optval, sizeof(int));
    STATNVAL(ret, SOCKET_ERROR, CLEAN_AND_EXIT);

    //Add membership
    mMreq.imr_multiaddr.s_addr = inet_addr(SSDP_MCAST_ADDRESS);
    mMreq.imr_interface.s_addr = INADDR_ANY;
    ret = setsockopt(mMulticastSocket, IPPROTO_IP, IP_ADD_MEMBERSHIP, (char*)&mMreq, sizeof(struct ip_mreq));
    STATNVAL(ret, SOCKET_ERROR, CLEAN_AND_EXIT);


    //Bind to all interface(s)
    ret = ::bind(mMulticastSocket, (struct sockaddr*)&mSrcaddr, sizeof(struct sockaddr));
    if(ret < 0 && (errno == EACCES || errno == EADDRINUSE))
        printf("address in use\n");
    STATVAL(ret, 0, CLEAN_AND_EXIT);


    //Destination address
    mDstaddr.sin_family = PF_INET;
    mDstaddr.sin_addr.s_addr = inet_addr(SSDP_MCAST_ADDRESS);
    mDstaddr.sin_port = htons(SSDP_MCAST_PORT);


    //
    // Setup the Unicast Socket (We listen for Advertisements)
    //
    mUnicastSocket = socket(PF_INET, SOCK_DGRAM, 0);
    STATNVAL(mUnicastSocket, INVALID_SOCKET, EXIT);

    //Set nonblocking
    optval = fcntl( mUnicastSocket, F_GETFL, 0 );
    STATNVAL(optval, -1,  CLEAN_AND_EXIT);
    ret = fcntl(mUnicastSocket, F_SETFL, optval | O_NONBLOCK);
    STATNVAL(ret, -1,  CLEAN_AND_EXIT);

    //Source address
    mUnicastSrcaddr.sin_family = PF_INET;
    mUnicastSrcaddr.sin_port = htons(SSDP_MCAST_PORT);
    mUnicastSrcaddr.sin_addr.s_addr = INADDR_ANY;//Default nic 

    //Reuse port
    optval = 1;
    ret = setsockopt(mUnicastSocket, SOL_SOCKET, SO_REUSEADDR, (char*)&optval, 4);
    STATVAL(ret, 0, CLEAN_AND_EXIT);
    optval = 1;
    ret = setsockopt(mUnicastSocket, SOL_SOCKET, SO_REUSEPORT, (char*)&optval, 4);
    STATVAL(ret, 0, CLEAN_AND_EXIT);

    //Join Multicast group
    mMreqU.imr_multiaddr.s_addr = inet_addr(SSDP_MCAST_ADDRESS);
    mMreqU.imr_interface.s_addr = INADDR_ANY;
    ret = setsockopt(mUnicastSocket, IPPROTO_IP, IP_ADD_MEMBERSHIP, (char*)&mMreqU, sizeof(struct ip_mreq));
    STATNVAL(ret, SOCKET_ERROR, CLEAN_AND_EXIT);



    //Bind to all interface(s)
    ret = ::bind(mUnicastSocket, (struct sockaddr*)&mUnicastSrcaddr, sizeof(struct sockaddr));
    if(ret < 0 && (errno == EACCES || errno == EADDRINUSE))
        printf("address in use\n");
    STATVAL(ret, 0, CLEAN_AND_EXIT);



    //Start the read thread
    pthread_attr_t  attr;
    ret = pthread_attr_init(&attr);
    if(ret != 0){
        goto CLEAN_AND_EXIT;
    }
    ret = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    if(ret != 0){
        pthread_attr_destroy(&attr);
        goto CLEAN_AND_EXIT;
    }

    ret = pthread_create(&mReadThread, &attr, SSDP::sReadLoop, (void*)this);

    pthread_attr_destroy(&attr);


    goto EXIT;


CLEAN_AND_EXIT:
    close(mMulticastSocket);
    mMulticastSocket = INVALID_SOCKET;
    close(mUnicastSocket);
    mUnicastSocket = INVALID_SOCKET;

EXIT:
    return ret;
}


int SSDP::Stop(){
    mReadLoop = 0;
    //@TODO: leave multicast groups
    if (mMulticastSocket > 0) {
        close(mMulticastSocket);
        mMulticastSocket = INVALID_SOCKET;
        close(mUnicastSocket);
        mUnicastSocket = INVALID_SOCKET;
    }

    return 0;
}


int SSDP::NotifyAlive(){
    const char *os=mOS.c_str();
    const char *product=mProduct.c_str();

    char buf[20048];

    sprintf(buf, "NOTIFY * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nCACHE-CONTROL: max-age=100\r\nNT: upnp:rootdevice\r\nNTS: ssdp:alive\r\nSERVER: %s/14.0.0, %s, UPnP/1.1\r\nX-User-Agent: fkuehne-upnpx\r\n\r\n", os, product);

    if(mMulticastSocket != INVALID_SOCKET)
        sendto(mMulticastSocket, buf, strlen(buf), 0, (struct sockaddr*)&mDstaddr , sizeof(struct sockaddr));
    else
        printf("invalid socket\n");

    return 0;
}

int SSDP::NotifyByeBye(){
    const char *os=mOS.c_str();
    const char *product=mProduct.c_str();

    char buf[20048];

    sprintf(buf, "NOTIFY * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nCACHE-CONTROL: max-age=100\r\nNT: upnp:rootdevice\r\nNTS: ssdp:byebye\r\nSERVER: %s, %s, UPnP/1.1\r\nX-User-Agent: fkuehne-upnpx\r\n\r\n", os, product);

    if(mMulticastSocket != INVALID_SOCKET)
        sendto(mMulticastSocket, buf, strlen(buf), 0, (struct sockaddr*)&mDstaddr , sizeof(struct sockaddr));
    else
        printf("invalid socket\n");

    return 0;
}

//Multicast M-Search
int SSDP::Search(){
    return this->SendSearchRequest("ssdp:all");
}

int SSDP::SearchForMediaServer(){
    return this->SendSearchRequest("urn:schemas-upnp-org:device:MediaServer:1");
}

int SSDP::SearchForMediaRenderer(){
    return this->SendSearchRequest("urn:schemas-upnp-org:device:MediaRenderer:1");
}

int SSDP::SearchForContentDirectory(){
    return this->SendSearchRequest("urn:schemas-upnp-org:service:ContentDirectory:1");
}

int SSDP::AddObserver(SSDPObserver* observer){
    RemoveObserver(observer);
    mObservers.push_back(observer);
    return 0;
}


int SSDP::RemoveObserver(SSDPObserver* observer){
    u8 found = 0;
    int tel = 0;
    std::vector<SSDPObserver*>::iterator it;
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

void SSDP::SetOS(const char* os){
    if(os)
        mOS = os;
}

void SSDP::SetProduct(const char* product){
    if(product)
        mProduct = product;
}

std::string mOS;
std::string mProduct;

int SSDP::ReadLoop(){
    int ret = 0;
    mReadLoop = 1;

    struct timeval timeout;
    timeout.tv_sec = 5;
    timeout.tv_usec = 0;

    const int bufsize = 4096;
    u8 buf[bufsize];

    struct sockaddr_in sender;
    socklen_t senderlen = sizeof(struct sockaddr);

    int maxsock = mMulticastSocket > mUnicastSocket ? mMulticastSocket : mUnicastSocket;

    //Read UDP answers
    while (mReadLoop) {
        memset(buf, 0, bufsize);

        //(Re)set file descriptor
        FD_ZERO(&mReadFDS);
        FD_ZERO(&mWriteFDS);
        FD_ZERO(&mExceptionFDS);
        if (!mMulticastSocket) {
            printf("Multicast socket failed!\n");
            break;
        }

        FD_SET(mMulticastSocket, &mReadFDS);
        FD_SET(mMulticastSocket, &mWriteFDS);
        FD_SET(mMulticastSocket, &mExceptionFDS);

        if (!mUnicastSocket) {
            printf("Multicast socket failed!\n");
            break;
        }
        FD_SET(mUnicastSocket, &mReadFDS);
        FD_SET(mUnicastSocket, &mWriteFDS);
        FD_SET(mUnicastSocket, &mExceptionFDS);

        timeout.tv_sec = 5;
        timeout.tv_usec = 0;

        ret = select(maxsock+1, &mReadFDS, 0, &mExceptionFDS, &timeout);
        if (ret == SOCKET_ERROR) {
            printf("Socket error!\n");
            break;
        }
        else if (ret != 0) {
            //Multicast
            if (FD_ISSET(mMulticastSocket, &mExceptionFDS)) {
                printf("Error on Multicast socket, continue\n");
            }
            if (FD_ISSET(mMulticastSocket, &mReadFDS)) {
                //Data
                //printf("Data\n");
                ret = (int)recvfrom(mMulticastSocket, buf, bufsize, MSG_WAITALL, (struct sockaddr*)&sender, &senderlen);
                if(ret != SOCKET_ERROR){
                    //Be sure to only deliver full messages (!)
                    IncommingMessage((struct sockaddr*)&sender, buf, ret);
                }
            }
            //Unicast
            if (FD_ISSET(mUnicastSocket, &mExceptionFDS)) {
                printf("Error on Unicast socket, continue\n");
            }
            if (FD_ISSET(mUnicastSocket, &mReadFDS)) {
                //Data
                //printf("Data\n");
                ret = (int)recvfrom(mUnicastSocket, buf, bufsize, MSG_WAITALL, (struct sockaddr*)&sender, &senderlen);
                if(ret != SOCKET_ERROR){
                    //Be sure to only deliver full messages (!)
                    IncommingMessage((struct sockaddr*)&sender, buf, ret);
                }
            }

        }
    }
EXIT:
    return ret;
}



int SSDP::IncommingMessage(struct sockaddr* sender, u8* buf, u32 len){
//    u8 *address;
    u16 port;

//    address = (u8*)sender->sa_data+2;
    memcpy(&port, sender->sa_data, 2);
    port = ntohs(port);

//    printf("receive from: %d.%d.%d.%d, port %d\n", address[0], address[1], address[2], address[3] , port);

    mParser->ReInit();
    mParser->Parse(sender, buf, len);

    //We have the type and all headers, check the mandatory headers for Advertisement & Search

    //Inform the observer(s)
    std::vector<SSDPObserver*>::const_iterator it;
    for(it=mObservers.begin();it<mObservers.end();it++){
        ((SSDPObserver*)*it)->SSDPMessage(mParser);
    }

    //hexdump(buf, len);
    return 0;
}

int SSDP::SendSearchRequest(const char *target) {
    std::stringstream str;
    str << "M-SEARCH * HTTP/1.1\r\n";
    str << "Mx: " << 5 << "\r\n";
    str << "St: " << target << "\r\n";
    str << "Man: \"ssdp:discover\"\r\n";
    str << "User-Agent: UPnP/1.1 " << mOS << " " << mProduct << "\r\n";
    str << "Connection: close\r\n";
    str << "Host: 239.255.255.250:1900\r\n\r\n";

    str.seekp(0, ios::end);
    stringstream::pos_type length = str.tellp();
    str.seekp(0, ios::beg);

    if(mMulticastSocket != INVALID_SOCKET)
        sendto(mMulticastSocket, str.str().c_str(), (unsigned long)length, 0, (struct sockaddr*)&mDstaddr , sizeof(struct sockaddr));
    else
        printf("invalid socket\n");

    return 0;
}

SSDPDB* SSDP::GetDB(){
    return mDB;
}



/** 
 * Static
 */

void* SSDP::sReadLoop(void* data){

    SSDP* pthis = (SSDP*)data;
    pthis->ReadLoop();

    return NULL;
}


