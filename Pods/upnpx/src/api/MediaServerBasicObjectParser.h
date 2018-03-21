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
#import "BasicParser.h"




@interface MediaServerBasicObjectParser : BasicParser {
    NSMutableArray *mediaObjects;

    //Generic
    NSString *mediaID;
    NSString *mediaTitle;
    NSString *mediaClass;
    NSString *parentID;

    //Container
    NSString *childCount;
    NSString *albumArt;

    //Item
    NSString *artist;
    NSString *album;
    NSString *date;
    NSString *genre;
    NSString *originalTrackNumber;
    NSString *uri;
    NSString *protocolInfo;
    NSString *frequency;
    NSString *audioChannels;
    NSString *size;
    NSString *duration;
    NSString *icon;
    NSString *bitrate;

    NSMutableDictionary *uriCollection; //key: NSString* protocolinfo -> value:NSString* uri
    NSMutableArray *resources;
}

-(instancetype)initWithMediaObjectArray:(NSMutableArray*)mediaObjectsArray;
-(instancetype)initWithMediaObjectArray:(NSMutableArray*)mediaObjectsArray itemsOnly:(BOOL)onlyItems NS_DESIGNATED_INITIALIZER;

-(void)container:(NSString*)startStop;
-(void)item:(NSString*)startStop;
-(void)empty;

-(void)setUri:(NSString*)s;

@property(readwrite, retain) NSString *mediaTitle;
@property(readwrite, retain) NSString *mediaClass;
@property(readwrite, retain) NSString *mediaID;
@property(readwrite, retain) NSString *parentID;
@property(readwrite, retain) NSString *childCount;
@property(readwrite, retain) NSString *artist;
@property(readwrite, retain) NSString *album;
@property(readwrite, retain) NSString *date;
@property(readwrite, retain) NSString *genre;
@property(readwrite, retain) NSString *originalTrackNumber;
@property(readonly) NSString *uri;
@property(readwrite, retain) NSString *protocolInfo;
@property(readwrite, retain) NSString *frequency;
@property(readwrite, retain) NSString *audioChannels;
@property(readwrite, retain) NSString *size;
@property(readwrite, retain) NSString *duration;
@property(readwrite, retain) NSString *icon;
@property(readwrite, retain) NSString *bitrate;
@property(readwrite, retain) NSString *albumArt;

@property (nonatomic, retain) NSMutableArray *creators;
@property (nonatomic, retain) NSMutableArray *authors;
@property (nonatomic, retain) NSMutableArray *directors;
@property (readwrite, retain) NSString *longDescription;
@property (readwrite, retain) NSString *lastPlaybackPosition;
@property (readwrite, retain) NSString *lastPlaybacktime;
@property (readwrite, retain) NSString *playbackCount;

@end
