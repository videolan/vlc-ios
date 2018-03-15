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


#ifndef _SSDPTOOLS_H
#define _SSDPTOOLS_H

#include "tools.h"
#include <vector>

using namespace std;


typedef struct ssdpuuid{
    u8* uuid;
    u32 uuidlen;
    u8* fullurn;
    u32 fullurnlen;
    u8* urn;
    u32 urnlen;
    u8  isdevice;
    u8  isrootdevice;
    u8  isservice;
    u8* type;
    u32 typelen;
    u8* version;
    u32 versionlen;
}ssdpuuid;


typedef struct SSDP_HTTP_HEADER{
    u8* fieldname;
    u32 fieldnamelen;
    u8* fieldvalue;
    u32 fieldvaluelen;
    int aa;
    int bb;
}SSDP_HTTP_HEADER;


typedef enum SSDP_TYPE{
    SSDP_TYPE_UNKNOWN = 0,
    SSDP_TYPE_NOTIFY = 1,
    SSDP_TYPE_MSEARCH,
    SSDP_TYPE_HTTP
}SSDP_TYPE;



int GetHeaderValueFromCollection(vector<SSDP_HTTP_HEADER*> headers, u8* fieldname, int fieldnamelen, u8** value, int *len);
int ParseUSN(u8* uuidraw, u32 len, ssdpuuid *uuid);
int cachecontroltoi(u8* s, u32 l);

#endif //_SSDPTOOLS_H