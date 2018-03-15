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


#include "httpsession.h"
#include "tools.h"

#include <stdlib.h>

HTTPSession::HTTPSession(char* srcip, unsigned short srcport){
    sourcePort = srcport;
    strcpy(sourceIP, (char*)srcip);
    firstData = true;

    sessionBuf = (char*)malloc(4096);
    sessionBufLen = 4096;
    currentFillLength = 0;
    mContentlength = -1;
}

HTTPSession::~HTTPSession(){
    free(sessionBuf);
}


int HTTPSession::AddData(unsigned char* buf, int len){
    int ret = 0;

    //Do we need more memory
    if(currentFillLength + len > sessionBufLen){
        if(sessionBufLen + 2048 > 8192){ //8k max
            return -9;
        }
        sessionBuf = (char*)realloc(sessionBuf, sessionBufLen + 2048);
        sessionBufLen = sessionBufLen + 2048;
    }

    //header ?
    memset(&sessionBuf[currentFillLength], 0, sessionBufLen - currentFillLength);
    memcpy(&sessionBuf[currentFillLength], buf, len);
    if(firstData){
        ret = ParseHeader((unsigned char*)&sessionBuf[currentFillLength], len);
        if(ret < 0){
            return ret;
        }
    }
    firstData = false;

    currentFillLength = currentFillLength + len;

    //Complete ?
    if(mContentlength <= 0){
        return 0;//at the moment only CONTENT-LENGTH headers are supported, add also chunked-encoding;see UPnP architecture 4.3.2
    }

    if(currentFillLength >= mContentlength + mHeaderlength){
        mBody = sessionBuf + mHeaderlength;
        mBodyLen = currentFillLength - mHeaderlength;
        return 0;
    }

    return mContentlength + mHeaderlength - currentFillLength;//check todo
}


//modifies the buffer (!)
int HTTPSession::ParseHeader(unsigned char* buf, int len){
    u8* pos = buf;
    int poslen = len;
    int space = 0;
    int eol = 0;
    int colon = 0;

    //Parse http header
    //New request
    /*
     * Parse Request line
     * method<space>path<space>version<cr><lf>
     */
    //Method
    space = getchar(pos, poslen, ' ');
    pos[space]=0;
    mMethod = (char*)pos;
    pos = pos + space + 1;
    poslen = (int)((buf + len) - pos);

    //Path
    space = getchar(pos, poslen, ' ');
    pos[space]=0;
    mPath = (char*)pos;
    pos = pos + space + 1;
    poslen = (int)((buf + len) - pos);

    //Version
    eol = getchar(pos, poslen, '\r');
    pos[eol]=0;
    mVersion = (char*)pos;
    pos = pos + eol + 2;
    poslen = (int)((buf + len) - pos);

    /*
     * Parse headers
     */
    string headerName;
    string headerValue;
    mContentlength = -1;

    mHeaders.clear();

    while (true) {
        colon = getchar(pos, poslen, ':');
        eol = getchar(pos, poslen, '\r');

        if(eol < 0){
            break;
        }

        if(colon <= 0 || colon > eol){
            while(*pos == '\r' || *pos == '\n' || *pos == ' '){
                pos++;
                poslen--;
            }
            break;//end of header
        }

        pos[colon] = 0;
        pos[eol] = 0;

        char* pheadervalue = (char*)pos + colon + 1;
        int tmpeol = eol;

        //LR Trim the header values
        while(*pheadervalue == ' '){
            pheadervalue++;
        }
        while(pheadervalue[tmpeol-1] == ' '){
            pheadervalue[tmpeol-1] = 0;
            tmpeol--;
        }

        headerValue = pheadervalue;//(char*)pos + colon + 1;

        char* pheadername = (char*)pos;
        int tmpcolon = colon;

        while(*pheadername == ' '){
            pheadername++;
        }
        while(pheadername[tmpcolon-1] == ' '){
            pheadername[tmpcolon-1] = 0;
            tmpcolon--;
        }

        headerName = pheadername;//(char*)pos;

        //Content length ?
        if( caseinstringcmp((u8*)pos, (int)strlen((char*)pos), (u8*)"CONTENT-LENGTH", 14) == 0 ){
            mContentlength = atoi((char*)pos + colon + 1);
        }

        pos = pos + eol + 2;
        poslen = (int)((buf + len) - pos);

        //add it to the map
        mHeaders[headerName] = headerValue;
    }

    mHeaderlength = len - poslen;

    return mHeaderlength;
}

string* HTTPSession::GetMethod(){
    return &mMethod;
}
char* HTTPSession::GetSenderIP(){
    return sourceIP;
}
unsigned short HTTPSession::GetSenderPort(){
    return sourcePort;
}
string* HTTPSession::GetPath(){
    return &mPath;
}
string* HTTPSession::GetVersion(){
    return &mVersion;
}
map<string, string>* HTTPSession::GetHeaders(){
    return &mHeaders;
}
char* HTTPSession::GetBody(){
    return mBody;
}
int HTTPSession::GetBodyLen(){
    return mBodyLen;
}
