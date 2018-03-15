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

#ifndef _SSDPMESSAGE_H
#define _SSDPMESSAGE_H

#include "ssdptools.h"
#include <vector>
#include <arpa/inet.h>
#include "ssdpdb.h"

class SSDPMessage{
public:
    SSDPMessage();
    virtual ~SSDPMessage();
    //What type of message can we handle
    virtual SSDP_TYPE GetType()=0;
    //Get the message dignature implemented in this class
    virtual std::vector<SSDP_HTTP_HEADER*> GetHeaderSignature();
    //Can this class parse the message with this signature ?
    virtual u8 CanProcess(std::vector<SSDP_HTTP_HEADER*> msgheaders);
    //Process the message, return value: 
    //0 : processed
    //1 : not for me, search for another to process
    //<0 : message was for me but there is an error
    virtual int Process(struct sockaddr* sender, std::vector<SSDP_HTTP_HEADER*> msgheaders)=0;
    //ReInit all members
    virtual void ReInit()=0;
    virtual SSDPDB* GetDB();
    virtual void SetDB(SSDPDB* db);
private:
    std::vector<SSDP_HTTP_HEADER*> mHeaderSignature;
protected:
    int AddSignatureHeader(char* fieldname, char* fieldvalue);
    SSDPDB *mDB;
private:
    SSDPMessage(const SSDPMessage &src);
    SSDPMessage& operator= (const SSDPMessage &src);
};


#endif //_SSDPMESSAGE_H