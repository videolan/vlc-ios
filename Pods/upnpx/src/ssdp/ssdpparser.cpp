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


#include "ssdpparser.h"
#include "tools.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

//Message implementations
#include "ssdpnotifyalive.h"
#include "ssdpnotifybye.h"
#include "ssdpnotifyupdate.h"
#include "ssdpsearchreq.h"
#include "ssdpsearchresp.h"

#define SSDP_START_NOTIFY    "NOTIFY * HTTP/1.1"
#define SSDP_START_MSEARCH    "M-SEARCH * HTTP/1.1"
#define SSDP_START_HTTP        "HTTP/1.1 200 OK"



SSDPParser::SSDPParser(SSDPDB* db):mType(SSDP_TYPE_UNKNOWN){
    mDB = db;

    /*
     * Register all implemented message types
     */
    SSDPMessage* msg;
    msg = new SSDPNotifyAlive();
    msg->SetDB(mDB);
    mMessages.push_back(msg);

    msg = new SSDPNotifyBye();
    msg->SetDB(mDB);
    mMessages.push_back(msg);

    msg = new SSDPNotifyUpdate();
    msg->SetDB(mDB);
    mMessages.push_back(msg);

    msg = new SSDPSearchReq();
    msg->SetDB(mDB);
    mMessages.push_back(msg);

    msg = new SSDPSearchResp();
    msg->SetDB(mDB);
    mMessages.push_back(msg);
}

SSDPParser::~SSDPParser(){
    std::vector<SSDP_HTTP_HEADER*>::iterator it;
    for(it=mHeaders.begin();it<mHeaders.end();it++){
        free(*it);
    }
    mHeaders.clear();

    std::vector<SSDPMessage*>::iterator itmsg;
    for(itmsg=mMessages.begin();itmsg<mMessages.end();itmsg++){
        delete(*itmsg);
    }
    mMessages.clear();
}


int SSDPParser::ReInit(){
    //Clear all headers of previous session (if any)
    if(mHeaders.size() > 0){
        std::vector<SSDP_HTTP_HEADER*>::iterator it;
        for(it=mHeaders.begin();it<mHeaders.end();it++){
            free(*it);
        }
        mHeaders.clear();
    }


    //ReInit all messages
    if(mMessages.size() > 0){
        std::vector<SSDPMessage*>::const_iterator itmsg;
        for(itmsg=mMessages.begin();itmsg<mMessages.end();itmsg++){
            ((SSDPMessage*)*itmsg)->ReInit();
        }
    }

    //Clear all members
    mType = SSDP_TYPE_UNKNOWN;


    return 0;
}

int SSDPParser::Parse(struct sockaddr* sender, u8* buf, u32 len){
    int linelen;
    u8* pos = buf;
    u32 restlen = len;
    u8* newpos;
    u32 newlen;
    u32 colon;
    int ret = 0;

    SSDPMessage* msg;
    std::vector<SSDPMessage*>::const_iterator itmsg;


    while( (linelen = ReadLine(pos, restlen, &newpos, &newlen)) > 0 ){
        if(mType == SSDP_TYPE_UNKNOWN){
            //Parse the first line and define the type
            if( linelen==strlen(SSDP_START_NOTIFY) && memcmp(pos, SSDP_START_NOTIFY, strlen(SSDP_START_NOTIFY)) == 0){
                mType = SSDP_TYPE_NOTIFY;
            }else if( linelen==strlen(SSDP_START_MSEARCH) && memcmp(pos, SSDP_START_MSEARCH, strlen(SSDP_START_MSEARCH)) == 0){
                mType = SSDP_TYPE_MSEARCH;
            }else if( linelen==strlen(SSDP_START_HTTP) && memcmp(pos, SSDP_START_HTTP, strlen(SSDP_START_HTTP)) == 0){
                mType = SSDP_TYPE_HTTP;
            }else{
                //unknown
                goto EXIT;
            }
        }else{
            //Read the headers
            //Find the first colon, that is the end of the field name, the rest is the field value
            colon = 0;
            while(pos[colon] != ':' && colon < linelen){
                colon++;
            }

            //Add the header to our collection
            SSDP_HTTP_HEADER *thisHeader = (SSDP_HTTP_HEADER*)malloc(sizeof(SSDP_HTTP_HEADER));
            thisHeader->fieldname = pos;
            thisHeader->fieldnamelen = colon;
            thisHeader->fieldvalue = pos+colon+1;
            if (colon<linelen) {
                thisHeader->fieldvaluelen = linelen-colon-1;
            } else {
                thisHeader->fieldvaluelen = 0;
            }
            //Trim spaces
            trimspaces(&(thisHeader->fieldname), &(thisHeader->fieldnamelen));
            trimspaces(&(thisHeader->fieldvalue), &(thisHeader->fieldvaluelen));
            mHeaders.push_back(thisHeader);
        }

        pos = newpos;
        restlen = newlen;
    }

    //We have all headers + type, search the message who can process it
    for(itmsg=mMessages.begin();itmsg<mMessages.end();itmsg++){
        msg = (SSDPMessage*)*itmsg;

        if(msg->GetType() == mType){
            if(msg->CanProcess(mHeaders) == 1){
                ret = msg->Process(sender, mHeaders);
                if(ret != 1){ //0=ok,-1=error,1=not for me, continue...
                    break;
                }
            }
        }
    }

EXIT:
    return ret;
}


SSDP_TYPE SSDPParser::GetType(){
    return mType;
}


/**
 * Private
 */


int SSDPParser::ReadLine(u8 *buf, u32 len, u8 **restbuf, u32 *restlen){
    int ret = 0;

    // If len is <2 it's not possible that we're going to find \r\n
    if (len < 2) {
        return -1;
    }

    //Search the \r\n
    u8 *pos = (u8 *)strnstr((const char*)buf, "\r\n", len);
    if( !pos )
        return -1;
    // \r\n or eof
    *restlen = len - (u32)(pos + 2 - buf);

    if( *restlen == 0 ){
        ret = -1;//eof
    }else{
        *restbuf = pos + 2;
        ret = len - *restlen - 2;
    }

    return ret;
}



