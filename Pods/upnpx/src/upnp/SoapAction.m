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


#import "SoapAction.h"
#import "BasicParserAsset.h"

#import "SoapActionsAVTransport1.h"
#import "SoapActionsConnectionManager1.h"
#import "SoapActionsContentDirectory1.h"
#import "SoapActionsRenderingControl1.h"
#import "SoapActionsSwitchPower1.h"
#import "SoapActionsDimming1.h"
#import "SoapActionsWANIPConnection1.h"
#import "SoapActionsWANPPPConnection1.h"


@interface SoapAction () {
    NSURL *_actionURL;
    NSURL *_eventURL;
    NSString *_upnpNameSpace;
    NSDictionary *_mOutput;
}
@end

@implementation SoapAction


-(instancetype)initWithActionURL:(NSURL*)aUrl eventURL:(NSURL*)eUrl upnpnamespace:(NSString*)ns{
    self = [super initWithNamespaceSupport:YES];

    if (self) {
        /* TODO: All of the below -> retain properties */
        _actionURL = aUrl;
        _eventURL = eUrl;
        _upnpNameSpace = ns;
        [_actionURL retain];
        [_eventURL retain];
        [_upnpNameSpace retain];
    }

    return self;
}

-(void)dealloc{
    [_actionURL release];
    [_eventURL release];
    [_upnpNameSpace release];
    [super dealloc];
}



-(NSInteger)action:(NSString*)soapAction parameters:(NSDictionary*)parameters returnValues:(NSDictionary*)output{
    NSUInteger len=0;
    NSInteger ret = 0;

    _mOutput = output;//we need it as a member to fill it during parsing

    @autoreleasepool {

        //SOAP Message to Send
        NSMutableString *body = [[NSMutableString alloc] init];
        [body appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
        [body appendString:@"<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"];
        [body appendString:@"<s:Body>"];
        [body appendFormat:@"<u:%@ xmlns:u=\"%@\">", soapAction, _upnpNameSpace];
        for (id key in parameters) {
            [body appendFormat:@"<%@>%@</%@>", key, parameters[key], key];
        }
        [body appendFormat:@"</u:%@>", soapAction];
        [body appendFormat:@"</s:Body></s:Envelope>"];
        len = [body length];

        //Construct the HTML POST 
        NSMutableURLRequest* urlRequest=[NSMutableURLRequest requestWithURL:_actionURL
                                                                cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                            timeoutInterval:60.0];

        [urlRequest setValue:[NSString stringWithFormat:@"\"%@#%@\"", _upnpNameSpace, soapAction] forHTTPHeaderField:@"SOAPACTION"];
        [urlRequest setValue:[NSString stringWithFormat:@"%ld", (unsigned long)len] forHTTPHeaderField:@"CONTENT-LENGTH"];
        [urlRequest setValue:@"text/xml;charset=\"utf-8\"" forHTTPHeaderField:@"CONTENT-TYPE"];

        /*
        [urlRequest setValue:@"" forHTTPHeaderField:@"Accept-Language"];
        [urlRequest setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
        */

        //POST (Synchronous)
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];


        NSHTTPURLResponse *urlResponse;
        NSError *error = nil;
        NSData *resp = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:&error];
        self.response = urlResponse;
        self.error = error;

        // Check the Server Return Code @TODO
        if ([urlResponse statusCode] != 200) {
            ret = -[urlResponse statusCode];
            NSString *rsp = [[NSString  alloc] initWithData:resp encoding:NSUTF8StringEncoding];
            NSLog(@"[UPnP] Error (SoapAction): Got a non 200 response: %ld. Data: %@", (long)[urlResponse statusCode], rsp);
            [rsp release];
            if (ret == 0) {
                ret = -408; // Why 408?
            }
        }
        else {
            ret = 0;
        }

        if (ret == 0 && [resp length] > 0 ) {
            //Parse result
            //Clear the assets becuase the action can be re-used
            [self clearAllAssets];
            NSString *responseGroupTag = [NSString stringWithFormat:@"%@Response", soapAction];
            for (id key in output) {
                [self addAsset:@[@"Envelope", @"Body", responseGroupTag, (NSString*)key] callfunction:nil functionObject:nil setStringValueFunction:@selector(setStringValueForFoundAsset:) setStringValueObject:self];
            }

            //uShare Issues here, can not handle names like 'Bj~rk
            ret = [super parseFromData:resp];
        }

        [body release];

        _mOutput = nil;
    }

    return ret;
}


-(void)setStringValueForFoundAsset:(NSString*)value{
    if(value != nil){
        //Check which asset is active in our stack
        BasicParserAsset* asset = [self getAssetForElementStack:mElementStack];
        if(asset != nil){
            NSString *elementName = [[asset path] lastObject];
            if(elementName != nil){
                NSMutableString *output = _mOutput[elementName];
                if(output != nil){
                    [output setString:value];
                }
            }
        }
    }
}

@end

@implementation SoapAction (Factory)

+ (SoapAction*)soapActionWithURN:(NSString*)urn andBaseNSURL:(NSURL*)baseURL andControlURL:(NSString*)controlURL andEventURL:(NSString*)eventURL {
    SoapAction *soapaction = nil;

    if([urn isEqualToString:@"urn:schemas-upnp-org:service:AVTransport:1"]){


        soapaction = [[SoapActionsAVTransport1 alloc]
                      initWithActionURL:[NSURL URLWithString:controlURL relativeToURL:baseURL]
                      eventURL:[NSURL URLWithString:eventURL relativeToURL:baseURL]
                      upnpnamespace:urn
                      ];


    }else if([urn isEqualToString:@"urn:schemas-upnp-org:service:ConnectionManager:1"]){

        soapaction = [[SoapActionsConnectionManager1 alloc]
                      initWithActionURL:[NSURL URLWithString:controlURL relativeToURL:baseURL]
                      eventURL:[NSURL URLWithString:eventURL relativeToURL:baseURL]
                      upnpnamespace:urn
                      ];


    }else if([urn isEqualToString:@"urn:schemas-upnp-org:service:ContentDirectory:1"]){

        soapaction = [[SoapActionsContentDirectory1 alloc]
                      initWithActionURL:[NSURL URLWithString:controlURL relativeToURL:baseURL]
                      eventURL:[NSURL URLWithString:eventURL relativeToURL:baseURL]
                      upnpnamespace:urn
                      ];

    }else if([urn isEqualToString:@"urn:schemas-upnp-org:service:RenderingControl:1"]){

        soapaction = [[SoapActionsRenderingControl1 alloc]
                      initWithActionURL:[NSURL URLWithString:controlURL relativeToURL:baseURL]
                      eventURL:[NSURL URLWithString:eventURL relativeToURL:baseURL]
                      upnpnamespace:urn
                      ];

    }else if([urn isEqualToString:@"urn:schemas-upnp-org:service:SwitchPower:1"]){
        soapaction = [[SoapActionsSwitchPower1 alloc]
                      initWithActionURL:[NSURL URLWithString:controlURL relativeToURL:baseURL]
                      eventURL:[NSURL URLWithString:eventURL relativeToURL:baseURL]
                      upnpnamespace:urn
                      ];

    }else if([urn isEqualToString:@"urn:schemas-upnp-org:service:Dimming:1"]){
        soapaction = [[SoapActionsDimming1 alloc]
                      initWithActionURL:[NSURL URLWithString:controlURL relativeToURL:baseURL]
                      eventURL:[NSURL URLWithString:eventURL relativeToURL:baseURL]
                      upnpnamespace:urn
                      ];

    }else if([urn isEqualToString:@"urn:schemas-upnp-org:service:WANIPConnection:1"]){
        soapaction = [[SoapActionsWANIPConnection1 alloc]
                      initWithActionURL:[NSURL URLWithString:controlURL relativeToURL:baseURL]
                      eventURL:[NSURL URLWithString:eventURL relativeToURL:baseURL]
                      upnpnamespace:urn
                      ];
    }else if([urn isEqualToString:@"urn:schemas-upnp-org:service:WANPPPConnection:1"]){
        soapaction = [[SoapActionsWANPPPConnection1 alloc]
                      initWithActionURL:[NSURL URLWithString:controlURL relativeToURL:baseURL]
                      eventURL:[NSURL URLWithString:eventURL relativeToURL:baseURL]
                      upnpnamespace:urn
                      ];
    }


    return [soapaction autorelease];
}

@end
