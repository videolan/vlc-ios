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

#import <Foundation/Foundation.h>

//<res  
//
//      bitrate="24000" 
//      duration="0:03:16.000" 
//      nrAudioChannels="2" 
//      protocolInfo="http-get:*:audio/mpeg:DLNA.ORG_PN=MP3;DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01500000000000000000000000000000" sampleFrequency="44100" 
//      size="4737165">
//
//      http://192.168.0.16:8895/resource/56/MEDIA_ITEM/MP3$0
//
//</res>

@interface MediaServer1ItemRes : NSObject {
    NSString *duration;
    NSString *protocolInfo;
    NSString *iconPath;
    NSURL *uri;
    int bitrate;
    int nrAudioChannels;
    long long int size;
    int durationInSeconds;
    float frequency;
}

@property(nonatomic, retain) NSString *duration;
@property(nonatomic, retain) NSString *protocolInfo;
@property(nonatomic, retain) NSString *iconPath;
@property(nonatomic, retain) NSURL *uri;
@property(nonatomic) int bitrate;
@property(nonatomic) int nrAudioChannels;
@property(nonatomic) long long int size;
@property(nonatomic) int durationInSeconds;
@property(nonatomic) float frequency;

@end
