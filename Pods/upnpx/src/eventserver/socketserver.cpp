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


#include "socketserver.h"
#include <fcntl.h>
#include "tools.h"
#include "osal.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>

#include <pthread.h>
#include <unistd.h>
#include <stdlib.h>

#include "iphoneport.h"

#define IFF_UP          0x1             /* interface is up              */
#define IFF_BROADCAST   0x2             /* broadcast address valid      */
#define IFF_DEBUG       0x4             /* turn on debugging            */
#define IFF_LOOPBACK    0x8             /* is a loopback net            */
#define IFF_POINTOPOINT 0x10            /* interface is has p-p link    */
#define IFF_NOTRAILERS  0x20            /* avoid use of trailers        */
#define IFF_RUNNING     0x40            /* resources allocated          */
#define IFF_NOARP       0x80            /* no ARP protocol              */
#define IFF_PROMISC     0x100           /* receive all packets          */
#define IFF_ALLMULTI    0x200           /* receive all multicast packets*/


SocketServer::SocketServer(unsigned short preferredPort):mServerSocket(NULL),mReadLoop(0){
    mPort = preferredPort;
    mMaxConnections = 20;
    memset(ipAddress, 0, sizeof(ipAddress));
}

SocketServer::~SocketServer(){
}

char* SocketServer::getServerIPAddress(){
    if(ipAddress[0] == 0){
        getLocalIPAddress(ipAddress, 10);
    }
    return ipAddress;
}

unsigned short SocketServer::getServerPort(){
    return mPort;
}


int SocketServer::getLocalIPAddress(char ip[16], int sWaitUntilFound){
    int ret = 0;
    int sec = 0;

    //Get the IP Address
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *thisaddress = NULL;

    while(true){
        ret = getifaddrs(&interfaces);
        if(ret == 0){
            ret = -1;//not found
            thisaddress = interfaces;
            while(thisaddress != NULL){
                if(thisaddress->ifa_addr->sa_family == AF_INET){
#ifdef UPNPX_PREFFERED_IFACE
                     if (strncmp (thisaddress->ifa_name,UPNPX_PREFFERED_IFACE,strlen(UPNPX_PREFFERED_IFACE)) == 0) {
#endif
                        unsigned int flags = thisaddress->ifa_flags;
                        if( (flags & IFF_UP) && (flags & IFF_RUNNING) && !(flags & IFF_LOOPBACK) ){
                            char* t = inet_ntoa(((struct sockaddr_in*)thisaddress->ifa_addr)->sin_addr);
                            strcpy(ip, t);
                            ret = 0;//found
                            printf("FOUND thisaddress->ifa_name:%s\n", thisaddress->ifa_name);
                            break;
                        }
#ifdef UPNPX_PREFFERED_IFACE
                    }
#endif
                }
                thisaddress = thisaddress->ifa_next;
            }
            freeifaddrs(interfaces);
        }
        if(ret == 0){
            break;//found
        }else{
            //Try again
            if(sec >= sWaitUntilFound){
                break;//timeout
            }
            sleep(1);
            sec++;
        }
    }

    return ret;
}


int SocketServer::Start(){
    int ret = 0;
    u32 optval = 0;
    int cnt = 0;

    //Get the IP Address
    ret = getLocalIPAddress(ipAddress, 10);
    if(ret != 0){
        return -1;
    }

    mServerSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (mServerSocket < 0){
        return -1;
    }

    //Set nonblocking
    optval = fcntl( mServerSocket, F_GETFL, 0 );
    STATNVAL(optval, -1,  CLEAN_AND_EXIT);
    ret = fcntl(mServerSocket, F_SETFL, optval | O_NONBLOCK);
    STATNVAL(ret, -1,  CLEAN_AND_EXIT);

    memset((char*)&mServerAddr, 0, sizeof(struct sockaddr_in));

    //Bind to port (try 500 numbers if needed)
    cnt = 0;
    do{
        mServerAddr.sin_family = AF_INET;
        mServerAddr.sin_addr.s_addr = INADDR_ANY;
        mServerAddr.sin_port = htons(mPort);

        if (bind(mServerSocket, (struct sockaddr *) &mServerAddr, sizeof(struct sockaddr_in)) == 0){
            break;
        }
        mPort++;
        cnt++;
    }while(cnt < 500);

    if(cnt == 500){
        return -2;
    }

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

    ret = pthread_create(&mReadThread, &attr, SocketServer::sReadLoop, (void*)this);

    pthread_attr_destroy(&attr);

    goto EXIT;

CLEAN_AND_EXIT:
    close(mServerSocket);
    mServerSocket = INVALID_SOCKET;

EXIT:
    return ret;
}


int SocketServer::Stop(){
    return -1;
}


int SocketServer::AddObserver(SocketServerObserver* observer){
    RemoveObserver(observer);
    mObservers.push_back(observer);
    return 0;
}


int SocketServer::RemoveObserver(SocketServerObserver* observer){
    int found = 0;
    int tel = 0;
    std::vector<SocketServerObserver*>::iterator it;
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



int SocketServer::ReadLoop(){
    ssize_t ret = 0;
    mReadLoop = 1;

    int highSocket = mServerSocket;

    struct timeval timeout;
    timeout.tv_sec = 5;
    timeout.tv_usec = 0;

    struct sockaddr_in *pConnectionSender;
    struct sockaddr_in sender;
    socklen_t senderlen = sizeof(struct sockaddr);
    std::vector<SocketServerObserver*>::iterator observerIterator;
    SocketServerConnection* connection;
    ssize_t len;

    listen(mServerSocket, mMaxConnections);

    //Read UDP answers
    while(mReadLoop){
        //printf("SSDP::ReadLoop, enter 'select'\n");

        //(Re)set file descriptor
        FD_ZERO(&mReadFDS);
        FD_ZERO(&mExceptionFDS);
        FD_ZERO(&mWriteFDS);

        //Set the ServerSocket
        FD_SET(mServerSocket, &mReadFDS);
        FD_SET(mServerSocket, &mWriteFDS);
        FD_SET(mServerSocket, &mExceptionFDS);

        //printf("mServerSocket=%d, highSocket=%d, sizeof(mReadFDS)=%d\n", mServerSocket,highSocket,sizeof(mReadFDS));

        //Set the connections
        SOCKET thisSocket;
        std::vector<SocketServerConnection*>::const_iterator it;
        for(it=mConnections.begin();it<mConnections.end();it++){
            thisSocket = ((SocketServerConnection*)*it)->GetSocket();
            FD_SET(thisSocket, &mReadFDS);
            FD_SET(thisSocket, &mExceptionFDS);
            FD_SET(thisSocket, &mWriteFDS);
            if(thisSocket > highSocket){
                highSocket = thisSocket;
            }
        }

        timeout.tv_sec = 5;
        timeout.tv_usec = 0;

#ifdef UPNPX_IPHONE 
        //Not sure why but 1024 seems to be the only one that work on the iPhone device
        ret = select(8*sizeof(mReadFDS), &mReadFDS, &mWriteFDS, &mExceptionFDS, &timeout);
#else
        ret = select(highSocket+1, &mReadFDS, &mWriteFDS, &mExceptionFDS, &timeout);
#endif 

        if(ret == SOCKET_ERROR){
            //Error
            break;
        }else if(ret == 0){
            //Timeout
        }else if(ret != 0){
            //Server socket 
            if(FD_ISSET(mServerSocket, &mExceptionFDS)){
                printf("Error on socket, continue\n");
            }else if(FD_ISSET(mServerSocket, &mWriteFDS)){
                //Write
            }else if(FD_ISSET(mServerSocket, &mReadFDS)){
                //New Connection 
                if(mConnections.size() <= mMaxConnections){
                    senderlen = sizeof(struct sockaddr);
                    SOCKET newSocket = accept(mServerSocket, (sockaddr*)&sender, &senderlen);
                    SocketServerConnection* newConnection = new SocketServerConnection(newSocket, &sender);
                    mConnections.push_back(newConnection);
                }else{
                    printf("New Connection Refused because connection pool is full!\n");
                }
            }

            //Event on connection socket
            std::vector<SocketServerConnection*>::const_iterator itConn;
            for(itConn=mConnections.begin();itConn<mConnections.end();itConn++){
                connection = (SocketServerConnection*)*itConn;
                thisSocket = connection->GetSocket();
                if(thisSocket < 0){
                    //Socket closed
                    connection->isActive = false;
                }else if(FD_ISSET(thisSocket, &mReadFDS)){
                    len = ((SocketServerConnection*)*itConn)->ReadDataFromSocket(&pConnectionSender);
                    if(len <= 0){
                        //Socket closed
                        connection->isActive = false;
                    }else{
                        //Inform the observers
                        for(observerIterator=mObservers.begin();observerIterator<mObservers.end();observerIterator++){
                            ret = ((SocketServerObserver*)*observerIterator)->DataReceived(pConnectionSender, len, connection->GetBuffer());
                            //std::vector<SocketServerObserver*>::iterator observerIterator;
                            //Is there anything to send back ?
                            if(ret == 0){
                                unsigned char* sendbuf;
                                ret = ((SocketServerObserver*)*observerIterator)->DataToSend(&len, &sendbuf);
                                if(ret >= 0 && len >= 0){
                                    ((SocketServerConnection*)*itConn)->SendDataOnSocket(sendbuf, len);
                                    free(sendbuf);
                                }
                            }
                        }
                    }
                }else if(FD_ISSET(thisSocket, &mExceptionFDS)){
                    connection->ErrorOnSocket();
                    //We remove this one from our pool
                    connection->isActive = false;
                }
                /* Closing socket if it has no data to read is bad. One reason is because it needs some time before it can be read.
                   Situation:
                    - open new socket
                    - FD_ISSET(thisSocket, &mReadFDS) == 0
                    - FD_ISSET(thisSocket, &mExceptionFDS) == 1 as socket is ready to be written to
                    - connection->isActive = false; -> socket closes in code below
                    - we lose all data from socket
                   Solution:
                    - don't close socket if it is not opened for reading, wait for another cycles until it becomes avaialable for it
                    - it will be closed when no data are to be read
                 */
                /*else if(FD_ISSET(thisSocket, &mWriteFDS)){
                    connection->isActive = false;
                }*/
            }

            //check for closed sockets
            bool found=true;
            SocketServerConnection* thisConnection;
            while(found){
                found = false;
                for(int x=0;x<mConnections.size();x++){
                    thisConnection = (SocketServerConnection*)mConnections[x];
                    if(thisConnection->isActive == false){
                        mConnections.erase(mConnections.begin()+x);
                        delete( thisConnection );
                        found = true;
                        break;
                    }
                }
            }
        }
    }
EXIT:
    return (int)ret;
}




/** 
 * Static
 */

void* SocketServer::sReadLoop(void* data){
    SocketServer* pthis = (SocketServer*)data;
    pthis->ReadLoop();
    return NULL;
}

