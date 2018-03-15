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


#import "BasicServiceParser.h"
#import "StateVariableRange.h"
#import "StateVariableList.h"
#import "StateVariable.h"

@implementation BasicServiceParser

@synthesize serviceType;
@synthesize descriptionURL;
@synthesize eventURL;
@synthesize controlURL;
@synthesize service;

-(instancetype)initWithUPnPService:(BasicUPnPService*)upnpservice{
    self = [super initWithNamespaceSupport:NO];

    if (self) {
        /* TODO: service -> retain property */
        service = upnpservice;
        [service retain];

        mStatevarCache = [[StateVariable alloc] init];
        mStatevarRangeCache = [[StateVariableRange alloc] init];
        mStatevarListCache = [[StateVariableList alloc] init];

        mCollectingStateVar = NO;
    }

    return self;
}


-(void)dealloc{
    [mStatevarCache release];
    [mStatevarRangeCache release];
    [mStatevarListCache release];
    [service release];

    [super dealloc];
}

- (int)parse {
    int ret = 0;

    /*
     * 1. First parse the Device Description XML
     */
    [self clearAllAssets];
    [self addAsset:@[@"root", @"URLBase"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setBaseURLString:) setStringValueObject:service];
    [self addAsset:@[@"*", @"device", @"serviceList", @"service", @"serviceType"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setServiceType:) setStringValueObject:self];
    [self addAsset:@[@"*", @"device", @"serviceList", @"service", @"SCPDURL"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setDescriptionURL:) setStringValueObject:self];
    [self addAsset:@[@"*", @"device", @"serviceList", @"service", @"controlURL"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setControlURL:) setStringValueObject:self];
    [self addAsset:@[@"*", @"device", @"serviceList", @"service", @"eventSubURL"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setEventURL:) setStringValueObject:self];
    [self addAsset:@[@"*", @"device", @"serviceList", @"service"] callfunction:@selector(serviceTag:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];


    NSURL *descurl = [NSURL URLWithString:[[service ssdpdevice] location]];
    ret = [super parseFromURL:descurl];

    if(ret < 0){
        return ret;
    }

    //Do we have a Base URL, if not creare one
    //Base URL
    if ([service baseURLString] == nil) {
        //Create one based on [device xmlLocation] 
        NSURL *loc = [NSURL URLWithString:[[service ssdpdevice] location] ];
        if(loc != nil){
            [service setBaseURL:loc];
        }
    }
    else {
        NSURL *loc = [NSURL URLWithString:[service baseURLString]];
        if(loc != nil){
            [service setBaseURL:loc];
        }
    }

    /*
     * 2. Parse the Service Description XML ([service descriptionURL])
     */
    [self clearAllAssets];
    [self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable"] callfunction:@selector(stateVariable:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
    //fill our cache
    [self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"name"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setName:) setStringValueObject:mStatevarCache];
    [self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"dataType"] callfunction:nil functionObject:self setStringValueFunction:@selector(setDataTypeString:) setStringValueObject:mStatevarCache];

    [self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"allowedValueRange"] callfunction:@selector(allowedValueRange:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
    [self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"allowedValueRange", @"minimum"] callfunction:nil functionObject:self setStringValueFunction:@selector(setMinWithString:) setStringValueObject:mStatevarRangeCache];
    [self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"allowedValueRange", @"maximum"] callfunction:nil functionObject:self setStringValueFunction:@selector(setMaxWithString:) setStringValueObject:mStatevarRangeCache];

    [self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"allowedValueList"] callfunction:@selector(allowedValueList:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
    [self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"allowedValueList", @"allowedValue"] callfunction:nil functionObject:self setStringValueFunction:@selector(setAllowedValue:) setStringValueObject:self];


    NSURL *serviceDescUrl = [NSURL URLWithString:[service descriptionURL] relativeToURL:[service baseURL] ];
    ret = [super parseFromURL:serviceDescUrl];

    return ret;
}

- (void)serviceTag:(NSString*)startStop {
    if([startStop isEqualToString:@"ElementStop"]) {
        //Is our cached servicetype the same as the one in the ssdp description, if so we can initialize the upnp service object
        if([serviceType compare:[[service ssdpdevice] urn] ] == NSOrderedSame){
            //found, copy
            [service setServiceType:serviceType];
            [service setDescriptionURL:descriptionURL];
            [service setControlURL:controlURL];
            [service setEventURL:eventURL];
        }
    }

}


-(void)stateVariable:(NSString*)startStop{
    if([startStop isEqualToString:@"ElementStart"]){
        mCollectingStateVar = YES;
        //clear our cache
        mCachedType = StateVariable_Type_Simple;
        [mStatevarCache empty];
        [mStatevarListCache empty];
        [mStatevarRangeCache empty];
    }else{
        mCollectingStateVar = NO;
        //add to the BasicUPnPService NSMutableDictionary *stateVariables;
        switch(mCachedType){
            case StateVariable_Type_Simple:
                {
                    StateVariable *new = [[StateVariable alloc] init];
                    [new copyFromStateVariable:mStatevarCache];
                    [service stateVariables][[new name]] = new;
                    [new release];
                }
                break;
            case StateVariable_Type_List:
                {
                    StateVariableList *new = [[StateVariableList alloc] init];
                    [new copyFromStateVariableList:mStatevarListCache];
                    [service stateVariables][[new name]] = new;
                    [new release];
                }
                break;
            case StateVariable_Type_Range:
                {
                    StateVariableRange *new = [[StateVariableRange alloc] init];
                    [new copyFromStateVariableRange:mStatevarRangeCache];
                    [service stateVariables][[new name]] = new;
                    [new release];
                }
                break;
            case StateVariable_Type_Unknown:
                NSLog(@"Error: State is unknown!");
                break;
        }
    }
}


-(void)allowedValueRange:(NSString*)startStop{
    if([startStop isEqualToString:@"ElementStart"]){
        //Copy from mStatevarCache
        [mStatevarRangeCache copyFromStateVariable:mStatevarCache];
        mCachedType = StateVariable_Type_Range;
    }else{
        //Stop
    }
}


-(void)allowedValueList:(NSString*)startStop{
    if([startStop isEqualToString:@"ElementStart"]){
        //Copy from mStatevarCache
        [mStatevarListCache copyFromStateVariable:mStatevarCache];
        mCachedType = StateVariable_Type_List;
    }else{
        //Stop
    }
}

-(void)setAllowedValue:(NSString*)value{
    [[mStatevarListCache list] addObject:value];
}


@end
