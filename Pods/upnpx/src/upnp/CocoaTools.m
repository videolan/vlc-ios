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


#import "NSString+UPnPExtentions.h"


@implementation NSString(UPnPExtentions)

- (NSString *)XMLUnEscape {
    if ([self length] < 2) {
        return self;
    }

    NSString *returnStr = nil;

    @autoreleasepool {
        returnStr = [self stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#x27;" withString:@"'"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#x39;" withString:@"'"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#x92;" withString:@"'"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#x96;" withString:@"'"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#10;" withString:@"\n"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#xA;" withString:@"\n"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#13;" withString:@"\r"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#xD;" withString:@"\r"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#x9;" withString:@"\t"];

        returnStr = [[NSString alloc] initWithString:returnStr];
    }

    return [returnStr autorelease];
}

- (NSString *)XMLEscape {
    if ([self length] < 2) {
        return self;
    }

    NSString *returnStr = [self copy];

    @autoreleasepool {
        // Disabled for correct double escaping

        //First remove all eventually escape codes because it makes it impossible to distinguish during unescape
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&amp;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&quot;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&apos;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#x27;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#x39;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#x92;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#x96;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&gt;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&lt;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#10;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#xA;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#13;" withString:@"."];
//        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&#xD;" withString:@"."];

        //Escape
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"&" withString: @"&amp;"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"\n" withString:@"&#xA;"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"\r" withString:@"&#xD;"];
        returnStr = [returnStr stringByReplacingOccurrencesOfString:@"\t" withString:@"&#x9;"];

        //Also for line breaks you need to use &#xA; &#xD; and &#x9; for tab, if you need these characters in an attribute.

        returnStr = [[NSString alloc] initWithString:returnStr];
    }

    return [returnStr autorelease];
}

//hh:mm:ss -> seconds
- (int)HMS2Seconds {
    int s = 0;

    @autoreleasepool {
        NSArray *items = [self componentsSeparatedByString:@":"];
        if ([items count] == 3) {
            //hh
            s += [(NSString*)items[0] intValue] * 60 * 60;
            //mm
            s += [(NSString*)items[1] intValue] * 60;
            //ss
            s += [(NSString*)items[2] intValue];
        }

        return s;
    }
}

//seconds -> hh:mm:ss 
+ (NSString*)Seconds2HMS:(int)seconds {
    NSString *ret = nil;
    if (seconds > 0) {
        int hh = (int) (seconds / 60 / 60);
        int mm = (int) ((seconds / 60) %  60 );
        int ss = (int) (seconds % 60 );
        ret = [NSString stringWithFormat:@"%.2d:%.2d:%.2d", hh, mm, ss];
    }
    else {
        ret = @"00:00:00";
    }

    return ret;
}

@end
