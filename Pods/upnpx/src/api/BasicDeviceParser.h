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

@class BasicUPnPDevice;
@interface BasicDeviceParser : BasicParser {
    BasicUPnPDevice *device;
    NSString* iconURL;
    NSString* iconWidth;
    NSString* iconHeight;
    NSString* iconMime;
    NSString* iconDepth;

    NSMutableArray* friendlyNameStack;
    NSMutableArray* udnStack;

    NSString* friendlyName;
    NSString* manufacturer;
    NSString* udn;

    NSString *modelDescription;
    NSString *modelName;
    NSString *modelNumber;
    NSString *serialNumber;
}

-(instancetype)initWithUPnPDevice:(BasicUPnPDevice*)upnpdevice NS_DESIGNATED_INITIALIZER;
@property (NS_NONATOMIC_IOSONLY, readonly) int parse;
-(void)iconFound:(NSString*)startStop;
-(void)embeddedDevice:(NSString*)startStop;
-(void)rootDevice:(NSString*)startStop;


@property (readwrite, retain) NSString* iconURL;
@property (readwrite, retain) NSString* iconWidth;
@property (readwrite, retain) NSString* iconHeight;
@property (readwrite, retain) NSString* iconMime;
@property (readwrite, retain) NSString* iconDepth;

@property (readwrite, retain) NSString* udn;
@property (readwrite, retain) NSString* friendlyName;
@property (readwrite, retain) NSString* manufacturer;
@property (readwrite, retain) NSString* manufacturerURLString;

@property (nonatomic, retain) NSString *modelDescription;
@property (nonatomic, retain) NSString *modelName;
@property (nonatomic, retain) NSString *modelNumber;
@property (nonatomic, retain) NSString *modelURLString;
@property (nonatomic, retain) NSString *serialNumber;

@end
