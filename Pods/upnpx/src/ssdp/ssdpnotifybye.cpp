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


#include "ssdpnotifybye.h"

SSDPNotifyBye::SSDPNotifyBye(){
    AddSignatureHeader((char*)"HOST", (char*)"");
    AddSignatureHeader((char*)"NT", (char*)"");
    AddSignatureHeader((char*)"NTS", (char*)"ssdp:byebye");
    AddSignatureHeader((char*)"USN", (char*)"");
    /*
    AddSignatureHeader("BOOTID.UPNP.ORG", "");
    AddSignatureHeader("CONFIGID.UPNP.ORG", "");
    */
}

void SSDPNotifyBye::ReInit(){
}

int SSDPNotifyBye::Process(struct sockaddr* sender, std::vector<SSDP_HTTP_HEADER*> msgheaders){
    int ret = 0;
    u8* usn;
    int usnlen;
    ssdpuuid uuid;

    //Get the Device USN (Unique Service Name)
    ret=GetHeaderValueFromCollection(msgheaders, (u8*)"USN", 3, &usn, &usnlen);
    if(ret != 0 || usnlen<=0){
        ret = -1;
        goto EXIT;
    }

    ret = ParseUSN(usn, usnlen, &uuid);
    if(ret < 0){
        goto EXIT;//Unknown format
    }

    //Delete the UUID
    //Specs : If a control point has received at least one ssdp:byebye message of a root device, any of its embedded devices or any of its
    //        services then the control point can assume that all are no longer available.
    mDB->DeleteDevicesByUuid(uuid.uuid, uuid.uuidlen);



EXIT:
    return ret;
}