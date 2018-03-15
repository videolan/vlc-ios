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


#ifndef _HTTPSESSION_H
#define _HTTPSESSION_H

#include "osal.h"

#include <map>
#include <string>

using namespace std;

class HTTPSession{
private:
    char *sessionBuf;
    int sessionBufLen;
    int currentFillLength;
    map<string, string> sessionHeaders;//copy the strings into the map

    bool firstData;
    unsigned short sourcePort;
    char sourceIP[16];
    string mVersion;
    string mPath;
    string mMethod;
    char* mBody;
    int mBodyLen;
    int mContentlength;
    int mHeaderlength;

    map<string, string> mHeaders;

public:
    HTTPSession(char* srcip, unsigned short srcport);
    ~HTTPSession();

    //return the bytes still to receive
    //< 0 when error
    //0 if done
    int AddData(unsigned char* buf, int len);

    string* GetMethod();
    char* GetSenderIP();
    unsigned short GetSenderPort();
    string* GetPath();
    string*  GetVersion();
    map<string, string>* GetHeaders();
    char* GetBody();
    int GetBodyLen();

private:
    int ParseHeader(unsigned char* buf, int len);
};

#endif //_HTTPSESSION_H


