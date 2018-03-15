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


#include "ssdptools.h"

#include <stdlib.h>

int GetHeaderValueFromCollection(vector<SSDP_HTTP_HEADER*> headers, u8* fieldname, int fieldnamelen, u8** value, int *len){
    int ret=0;
    int found=0;

    vector<SSDP_HTTP_HEADER*>::const_iterator it;
    SSDP_HTTP_HEADER *hdr = nullptr;

    if(headers.size() <= 0){
        ret = -1;
        goto EXIT;
    }

    for(it=headers.begin();it<headers.end();it++){
        hdr = *it;
        if(caseinstringcmp(fieldname, fieldnamelen, hdr->fieldname, hdr->fieldnamelen) == 0){
            //found
            found=1;
            break;
        }
    }

    if(found){
        *value=hdr->fieldvalue;
        *len=hdr->fieldvaluelen;
    }else{
        ret =-1;
    }

EXIT:
    return ret;
}




//Possible formats:
// uuid:device-UUID
// uuid:device-UUID::upnp:rootdevice
// uuid:device-UUID::urn :schemas-upnp-org:device :deviceType :ver
// uuid:device-UUID::urn :schemas-upnp-org:service:serviceType:ver
// uuid:device-UUID::urn :domain-name     :device :deviceType :ver
// uuid:device-UUID::urn :domain-name     :service:serviceType:ver
// 1    2            3    4                5       6           7

int ParseUSN(u8* uuidraw, u32 len, ssdpuuid *uuid){
    int ret = 0;
    int colon1 = 0;
    int colon2 = 0;
    int tel;
    int skip=0;

//    int lenleft;

    //Sanity
    if(uuid == NULL || len == 0){
        return -1;
    }
    if(memcmp(uuidraw, "uuid", 4) != 0){
        return -2;
    }

    memset(uuid, 0, sizeof(ssdpuuid));

//    lenleft = len;

    //uuid
    colon1 = getchar(uuidraw, len, ':', 1);
    colon2 = getchar(uuidraw, len, ':', 2);
    if(colon1<0 || colon1+1>=len){ ret = -1;goto EXIT;}
    if(colon2<0){
        uuid->uuid=uuidraw;//+colon1+1;
        uuid->uuidlen=len;//-colon1-1;
        //uuid->uuidlen=len-colon1-1;
        goto EXIT;
    }else{
        uuid->uuid=uuidraw;//+colon1+1;
        uuid->uuidlen=colon2;
//        uuid->uuidlen=colon2-colon1-1;
    }

    //Sanity, there must be a double colon
    //Find the first '::' sequence and compute the number of semicolons to it
    //store it in the skip variable, which is used for offsetting subsequent searches
    //this is needed for some devices that have a semicolon in the name
    colon1 = getchar(uuidraw, len, ':', 2);
    colon2 = -1;
    while (colon1 < len && colon2 == -1) {
        colon2 = getchar(uuidraw, len, ':', 2+skip+1);
        if (colon2-colon1 == 1) {
            uuid->uuidlen=colon1;
            colon1 = colon2;
        } else {
            colon1 = colon2;
            colon2 = -1;
            skip++;
        }
    }
    if(colon2 == -1){
        ret = -2;
        goto EXIT;
    }


    //upnp, isroot 
    colon1 = getchar(uuidraw, len, ':', 3+skip);
    if((len-colon1)>=15 && memcmp(uuidraw+colon1+1, "upnp:rootdevice", 15)==0 ){
        uuid->isrootdevice = 1;
        uuid->isdevice = 1;
        uuid->type = uuidraw+colon1+1;
        uuid->typelen = 15;
        goto EXIT;
    }

    //Sanity, there must be 4 colons after
    for(tel=4+skip;tel<=7+skip;tel++){
        colon1 = getchar(uuidraw, len, ':', tel);
        if(colon1 < 0){
            ret = -3;
            goto EXIT;
        }
    }


    //urn
    colon1 = getchar(uuidraw, len, ':', 3+skip);
    colon2 = getchar(uuidraw, len, ':', 4+skip);
    if((colon2-colon1)>=3 && memcmp(uuidraw+colon1+1, "urn", 3)!=0 ){
        ret = -4;
        goto EXIT;
    }
    uuid->fullurn = uuidraw+colon1+1;
    uuid->fullurnlen = len-colon1-1;

    colon1 = getchar(uuidraw, len, ':', 4+skip);
    colon2 = getchar(uuidraw, len, ':', 5+skip);
    uuid->urn=uuidraw+colon1+1;
    uuid->urnlen=colon2-colon1-1;



    //Device or service
    colon1 = getchar(uuidraw, len, ':', 5+skip);
    colon2 = getchar(uuidraw, len, ':', 6+skip);
    if( (colon2-colon1)>=6 && memcmp(uuidraw+colon1+1, "device", 6)==0){
        //device
        uuid->isdevice = 1;
    }else if((colon2-colon1)>=7 && memcmp(uuidraw+colon1+1, "service", 7)==0){
        //service
        uuid->isservice = 1;
    }else{
        ret = -5;
        goto EXIT;
    }


    //servicetype / devicetype
    colon1 = getchar(uuidraw, len, ':', 6+skip);
    colon2 = getchar(uuidraw, len, ':', 7+skip);
    uuid->type = uuidraw+colon1+1;
    uuid->typelen=colon2-colon1-1;

    //Workaround for MusicPal bug
    if(uuid->typelen==16 && memcmp(uuid->type, "RenderingControl", 16) == 0){
        uuid->isdevice = 0;
        uuid->isrootdevice = 0;
        uuid->isservice = 1;
    }

    //version
    uuid->version = uuidraw+colon2+1;
    uuid->versionlen=len-colon2-1;

EXIT:

    return ret;
}





int cachecontroltoi(u8* s, u32 l){
    u32 ret = -1;
    u32 p;

    char buf[1024];
    int buflen=1024;

    if(l >= buflen){
        return ret;
    }

    memcpy(&buf, s, l);
    buf[l]=0;

    //max-age=nn
    trimspaces(&s, &l);
    if(l >= 7 && caseinstringcmp(s, 7, (u8*)"max-age", 7) == 0){
        //search the =
        p = getchar((u8*)buf, (unsigned int)strlen(buf), '=');
        if(p > 0){
            ret = atoi(buf+p+1);
        }
    }

    return ret;
}


