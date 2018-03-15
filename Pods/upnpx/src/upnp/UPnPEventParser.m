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
 <e:propertyset xmlns:e="urn:schemas-upnp-org:event-1-0">
    <e:property>
        <SystemUpdateID>0</SystemUpdateID>
        <ContainerUpdateIDs>0,4</ContainerUpdateIDs>
    </e:property>
 </e:propertyset>
*/


#import "UPnPEventParser.h"
#import "NSString+UPnPExtentions.h"


@implementation UPnPEventParser

@synthesize events;
@synthesize elementValue;

- (instancetype)init {
    self = [super initWithNamespaceSupport:YES];
    if (self) {
        events = [[NSMutableDictionary alloc] init];

        lastChangeParser = nil;

        // Device is the root device
        [self addAsset:@[@"propertyset", @"property", @"LastChange"] callfunction:@selector(lastChangeElement:) functionObject:self setStringValueFunction:@selector(setElementValue:) setStringValueObject:self];
        [self addAsset:@[@"propertyset", @"property", @"*"] callfunction:@selector(propertyName:) functionObject:self setStringValueFunction:@selector(setElementValue:) setStringValueObject:self];
    }
    return self;
}

- (void)dealloc {
    [lastChangeParser release];
    [elementValue release];
    [events release];
    [super dealloc];
}

- (void)reinit {
    [events removeAllObjects];
}

- (void)propertyName:(NSString *)startStop {
    if (NO == [startStop isEqualToString:@"ElementStart"]) {
        //Element name
        NSString *name = [[NSString alloc] initWithString:currentElementName];
        //Element value
        NSString *value = [[NSString alloc] initWithString:elementValue];
        //Add
        events[name] = value;

        [name release];
        [value release];
    }
}

- (void)lastChangeElement:(NSString *)startStop {
    if (lastChangeParser == nil) {
        lastChangeParser = [[LastChangeParser alloc] initWithEventDictionary:events];
    }

    if (NO == [startStop isEqualToString:@"ElementStart"]) {

        elementValue = [self stringByCorrectingElementString:elementValue];

        NSData *lastChange = [elementValue dataUsingEncoding:NSUTF8StringEncoding];
        NSString *elementValueCopy = [elementValue copy];

        // iOS 8 changes behaviour based on reentrant parsing, requiring a
        // synchronous workaround.
        // https://devforums.apple.com/message/1028271
        __block int ret;

        if ([lastChange length] > 0) {
            dispatch_queue_t reentrantAvoidanceQueue = dispatch_queue_create("reentrantAvoidanceQueue", DISPATCH_QUEUE_SERIAL);
            dispatch_async(reentrantAvoidanceQueue, ^{
                ret = [lastChangeParser parseFromData:lastChange];
            });
            dispatch_sync(reentrantAvoidanceQueue, ^{});

            if (ret != 0) {
                NSLog(@"[UPnP] Something went wrong during LastChange parsing");
                NSLog(@"[UPnP] Raw data: %@", elementValueCopy);
            }
        }
    }
}

- (NSString *)stringByCorrectingElementString:(NSString *)elementValue {
    NSString * const kNextTrackMetadataPattern = @"<NextAVTransportURIMetaData val=\"([\\s\\S]*?)\"\\/>";
    NSString * const kNextTrackBeginningPart = @"<NextAVTransportURIMetaData val=\"";
    NSString * const kNextTrackEndingPart = @"\"/>";

    NSMutableString *resultString = [self.elementValue mutableCopy];

    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:kNextTrackMetadataPattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    NSTextCheckingResult *result = [regex firstMatchInString:self.elementValue options:NSMatchingReportCompletion range:NSMakeRange(0, [self.elementValue length])];
    if (result != nil && result.range.length > 0) {
        NSMutableString *foundPart = [[self.elementValue substringWithRange:result.range] mutableCopy];

        // Cutting beginning and ending parts
        NSRange range = [foundPart rangeOfString:kNextTrackBeginningPart];
        if (range.location != NSNotFound) {
            [foundPart replaceCharactersInRange:range withString:@""];
        }
        
        range = [foundPart rangeOfString:kNextTrackEndingPart options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            [foundPart replaceCharactersInRange:range withString:@""];
        }
        
        // Escape
        if (NO == [foundPart hasPrefix:@"&lt;"]) {
            [foundPart replaceCharactersInRange:NSMakeRange(0, [foundPart length]) withString:[foundPart XMLEscape]];
            // Append beginning and end parts
            [foundPart insertString:kNextTrackBeginningPart atIndex:0];
            [foundPart appendString:kNextTrackEndingPart];

            [resultString replaceCharactersInRange:result.range withString:foundPart];
        }
    }

    return resultString;
}

@end
