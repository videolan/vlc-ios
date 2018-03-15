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

#include "ssdpmessage.h"

#include <stdlib.h>
#include <unistd.h>

SSDPMessage::SSDPMessage():mDB(NULL){
}

SSDPMessage::~SSDPMessage(){
    std::vector<SSDP_HTTP_HEADER*>::iterator it;
    for(it=mHeaderSignature.begin();it<mHeaderSignature.end();it++){
        free(*it);
    }
    mHeaderSignature.clear();
}



std::vector<SSDP_HTTP_HEADER*> SSDPMessage::GetHeaderSignature(){
    return mHeaderSignature;
}


u8 SSDPMessage::CanProcess(std::vector<SSDP_HTTP_HEADER*> msgheaders){
    u8 ret = 0;
    SSDP_HTTP_HEADER* hdrsig;
    SSDP_HTTP_HEADER* hdrmsg;
    u8 found = 0;
    u32 ftel = 0;
    std::vector<SSDP_HTTP_HEADER*>::const_iterator itsig;
    std::vector<SSDP_HTTP_HEADER*>::const_iterator itmsg;
    if(mHeaderSignature.size()<=0 || msgheaders.size() <= 0){
        goto EXIT;
    }
    for(itsig=mHeaderSignature.begin();itsig<mHeaderSignature.end();itsig++){
        hdrsig = (SSDP_HTTP_HEADER*)*itsig;
        found = 0;
        for(itmsg=msgheaders.begin();itmsg<msgheaders.end();itmsg++){
            hdrmsg = (SSDP_HTTP_HEADER*)*itmsg;
            if(caseinstringcmp(hdrmsg->fieldname, hdrmsg->fieldnamelen, hdrsig->fieldname, hdrsig->fieldnamelen) == 0 &&
               ( hdrsig->fieldvaluelen == 0 || (hdrmsg->fieldvaluelen == hdrsig->fieldvaluelen && memcmp(hdrmsg->fieldvalue, hdrsig->fieldvalue, hdrsig->fieldvaluelen) == 0) ))
            {
                found = 1;
                break;
            }
        }
        if(found==1){
            ftel++;
        }
    }
    if(ftel == mHeaderSignature.size()){
        //All found
        ret = 1;
    }
EXIT:
    return ret;
}


int SSDPMessage::AddSignatureHeader(char* fieldname, char* fieldvalue){
    SSDP_HTTP_HEADER *thisHeader = (SSDP_HTTP_HEADER*)malloc(sizeof(SSDP_HTTP_HEADER));
    thisHeader->fieldname = (u8*)fieldname;
    thisHeader->fieldnamelen = (unsigned int)strlen(fieldname);
    thisHeader->fieldvalue = (u8*)fieldvalue;
    thisHeader->fieldvaluelen = (unsigned int)strlen(fieldvalue);
    mHeaderSignature.push_back(thisHeader);
    return (int)mHeaderSignature.size();
}


void SSDPMessage::SetDB(SSDPDB* db){
    mDB = db;
}

SSDPDB* SSDPMessage::GetDB(){
    return mDB;
}

