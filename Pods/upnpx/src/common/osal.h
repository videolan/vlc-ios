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


#ifndef _OSAL_H
#define _OSAL_H

#include <sys/types.h>
#include <sys/socket.h>
#include <errno.h>


/**
 * Data types
 */
#define u8 unsigned char
#define u16 unsigned short
#define u32 unsigned int

#define s8 signed char
#define s16 signed short
#define s32 signed int



/**
 * Sockets
 */
#define SOCKET int
#define INVALID_SOCKET -1
#define SOCKET_ERROR -1


/**
 * Functions
 */
//#define systimeinseconds (int)CFAbsoluteTimeGetCurrent()
#define systimeinseconds time(NULL)

/**
 *
 */
#define STATVAL(ret, excepted, jump) if(ret != excepted){printf("stat error, ret=%d, excepted=%d, errno=%d, line=%d, %s:%s\n", ret, excepted, errno, __LINE__, __FILE__, __FUNCTION__);goto jump;}
#define STAT(ret) STATVAL(ret, 0, EXIT)
#define STATNVAL(ret, notexcepted, jump)if(ret == notexcepted){printf("stat error, ret=%d, not excepted=%d, errno=%d, line=%d, %s:%s\n", ret, notexcepted, errno, __LINE__, __FILE__, __FUNCTION__);goto jump;}

#endif //_OSAL_H