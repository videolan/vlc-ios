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

/*
#include <iostream>

#include "upnp.h"
#include "ssdp.h"
#include "ssdpobserver.h"
#include "ssdpdbobserver.h"

#import "Test_ObjC.h"


class MainClass: public SSDPObserver, public SSDPDBObserver{
public:
    int SSDPMessage(SSDPParser *parsedmsg){
        switch(parsedmsg->GetType()){
            case SSDP_TYPE_HTTP:
                //printf("SSDP_TYPE_HTTP\n");
                break;
            case SSDP_TYPE_NOTIFY:
                //printf("SSDP_TYPE_NOTIFY\n");
                break;
            case SSDP_TYPE_MSEARCH:
                //printf("SSDP_TYPE_MSEARCH\n");
                break;
            default:
                printf("unknown\n");
                break;
        }
        return 0;
    }

    int SSDPDBMessage(SSDPDBMsg* msg){
        SSDPDB* db = UPNP::GetInstance()->GetSSDP()->GetDB();

        switch(msg->type){
            case SSDPDBMsg_DeviceUpdate:
            case SSDPDBMsg_ServiceUpdate:
                {
                    db->Lock();
                    vector<SSDPDBDevice*>devices = db->GetDevices();
                    std::vector<SSDPDBDevice*>::iterator it;
                    printf("devices.size()=%d\n", devices.size());
                    for(it=devices.begin();it<devices.end();it++){
                        printf("full usn=%s, type=%s, version=%s, location=%s\n", ((SSDPDBDevice*)*it)->usn.c_str(), ((SSDPDBDevice*)*it)->type.c_str(), ((SSDPDBDevice*)*it)->version.c_str(), ((SSDPDBDevice*)*it)->location.c_str());
                    }
                    db->Unlock();
                }
                printf("SSDPDBMsg_DeviceUpdate\n");
                break;
        }
        return 0;
    }

private:
};

int main (int argc, char * const argv[]) {
    // insert code here...
    std::cout << "Hello, World!\n";

    MainClass mm;

    Test_ObjC* testObjC = [[Test_ObjC alloc] init];

    UPNP* upnp = UPNP::GetInstance();

    SSDP* ssdp = upnp->GetSSDP();
    SSDPDB* db = ssdp->GetDB();
//    db->AddObserver(&mm);
//    ssdp->AddObserver(&mm);
    ssdp->Start();

    while(1){
        ssdp->Search();
        printf("sleep...\n");
        sleep(30);
    }

    [testObjC release];

    return 0;
}
*/