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


#import "BasicParser.h"
#import "BasicParserAsset.h"

@interface BasicParser()
    -(int)startParser:(NSXMLParser*)parser;
@end


@implementation BasicParser

static NSString *ElementStart = @"ElementStart";
static NSString *ElementStop = @"ElementStop";


-(instancetype)init{
    return [self initWithNamespaceSupport:NO];
}

-(instancetype)initWithNamespaceSupport:(BOOL)namespaceSupport{
    self = [super init];

    if (self) {
        mSupportNamespaces = namespaceSupport;
        @synchronized(self) {
            mElementStack = [[NSMutableArray alloc] init];
            mAssets = [[NSMutableArray alloc] init];
        }
    }

    return self;
}

-(void)dealloc{
    @synchronized(self) {
        [mElementStack release];
        [mAssets release];
    }
    [super dealloc];
}

-(int)addAsset:(NSArray*)path callfunction:(SEL)function functionObject:(id)funcObj setStringValueFunction:(SEL)valueFunction setStringValueObject:(id)obj;{
    BasicParserAsset* asset = [[BasicParserAsset alloc] initWithPath:path setStringValueFunction:valueFunction setStringValueObject:obj callFunction:function functionObject:funcObj];
    @synchronized(self) {
        [mAssets addObject:asset];
    }
    [asset release];
    return 0;
}


-(void)clearAllAssets{
    @synchronized(self) {
        [mAssets removeAllObjects];
    }
}

-(BasicParserAsset*)getAssetForElementStack:(NSMutableArray*)stack{
    BasicParserAsset* ret = nil;
    BasicParserAsset* asset = nil;
    NSArray *elementStack;
    NSArray *assets;

    @autoreleasepool {
        @synchronized (self) {
            elementStack = [[stack copy] autorelease];
            assets = [[mAssets copy] autorelease];
        }
        NSEnumerator *enumer = [assets objectEnumerator];
        while((asset = [enumer nextObject])){
            //Full compares go first
            if([[asset path] isEqualToArray:elementStack]){
                ret = asset;
                break;
            }else{
                // * -> leafX -> leafY
                //Maybe we have a wildchar, that means that the path after the wildchar must match
                if([(NSString*)[asset path][0] isEqualToString:@"*"]){
                    if([elementStack count] >= [[asset path] count]){
                        //Path ends with
                        NSMutableArray *lastStackPath = [[NSMutableArray alloc] initWithArray:elementStack];
                        NSMutableArray *lastAssetPath = [[NSMutableArray alloc] initWithArray:[asset path]];
                        //cut the * from our asset path
                        [lastAssetPath removeObjectAtIndex:0];
                        //make our (copy of the) curents stack the same length
                        NSUInteger elementsToRemove = [lastStackPath count] - [lastAssetPath count];
                        NSRange range;
                        range.location = 0;
                        range.length = elementsToRemove;
                        [lastStackPath removeObjectsInRange:range];
                        if([lastAssetPath isEqualToArray:lastStackPath]){
                            ret = asset;
                            [lastAssetPath release];
                            [lastStackPath release];
                            break;
                        }
                        [lastAssetPath release];
                        [lastStackPath release];
                    }
                }
                // leafX -> leafY -> *
                if([(NSString*)[[asset path] lastObject] isEqualToString:@"*"]){
                    if([elementStack count] == [[asset path] count] && [elementStack count] > 1){
                        //Path start with
                        NSMutableArray *beginStackPath = [[NSMutableArray alloc] initWithArray:elementStack];
                        NSMutableArray *beginAssetPath = [[NSMutableArray alloc] initWithArray:[asset path]];
                        //Cut the last entry (which is * in one array and <element> in the other
                        [beginStackPath removeLastObject];
                        [beginAssetPath removeLastObject];
                        if([beginAssetPath isEqualToArray:beginStackPath]){
                            ret = asset;
                            [beginAssetPath release];
                            [beginStackPath release];
                            break;
                        }
                        [beginAssetPath release];
                        [beginStackPath release];

                    }
                }

            }
        }
        [ret retain];
    }
    [ret autorelease];

    return ret;
}

-(int)parseFromData:(NSData*)data{
    int ret = 0;

    @autoreleasepool {
        if (data != nil) {
            @autoreleasepool {
                NSString *xml = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                if (xml != nil) {
                    NSError *error = NULL;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*$\\r?\\n" options:NSRegularExpressionAnchorsMatchLines error:&error];
                    xml = [regex stringByReplacingMatchesInString:xml options:0 range:NSMakeRange(0, [xml length]) withTemplate:@""];
                    data = [[xml dataUsingEncoding:NSUTF8StringEncoding] retain];
                } else {
                    return -1;
                }
            }
            [data autorelease];
        }
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        ret = [self startParser:parser];
        [parser release];
    }

    return ret;
}

-(int)parseFromURL:(NSURL*)url{
    @autoreleasepool {
        //Workaround for memory leak
        //http://blog.filipekberg.se/2010/11/30/nsxmlparser-has-memory-leaks-in-ios-4/
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        [[NSURLCache sharedURLCache] setDiskCapacity:0];

#warning Change to Async request, sometimes it blocks main thread!
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data != nil) {
            @autoreleasepool {
                NSString *xml = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                if (xml != nil) {
                    NSError *error = NULL;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*$\\r?\\n" options:NSRegularExpressionAnchorsMatchLines error:&error];
                    xml = [regex stringByReplacingMatchesInString:xml options:0 range:NSMakeRange(0, [xml length]) withTemplate:@""];

                    data = [[xml dataUsingEncoding:NSUTF8StringEncoding] retain];
                } else
                    return -1;
            }
            [data autorelease];
        }

        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        int ret = [self startParser:parser];
        [parser release];
        return ret;
    }
}

-(int)startParser:(NSXMLParser*)parser{
    if(parser == nil){
        return -1;
    }

    [parser setShouldProcessNamespaces:mSupportNamespaces];
    [parser setDelegate:self];

    BOOL pret = [parser parse];
    [parser setDelegate:nil];

    return pret? 0: -1;
}

/***
 * NSXMLParser Delegates
 */

- (void)parserDidStartDocument:(NSXMLParser *)parser{
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict{
    @autoreleasepool {
        //NSLog(@"open=%@", elementName);
        @synchronized(self) {
            [mElementStack addObject:elementName];
        }

        //Check if we are looking for this asset
        BasicParserAsset* asset = [self getAssetForElementStack:mElementStack];
        if(asset != nil){
            elementAttributeDict = attributeDict;//make temprary available to derived classes
            [elementAttributeDict retain];

            if([asset stringValueFunction] != nil && [asset stringValueObject] != nil){
                //we are interested in a string and we are looking for this
                [[asset stringCache] setString:@""];
                //[asset setStringCache:[[[NSString alloc] init] autorelease]];
            }
            if([asset function] != nil && [asset functionObject] != nil){
                if([[asset functionObject] respondsToSelector:[asset function]]){
                    [[asset functionObject] performSelector:[asset function] withObject:ElementStart];
                }
            }

        }
    }
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    @autoreleasepool {
        BasicParserAsset* asset = [self getAssetForElementStack:mElementStack];
        if(asset != nil){
            currentElementName = elementName;//make temporary available to derived classes

            //We where looking for this
            //Set string (call function to set)
            if([asset stringValueFunction] != nil && [asset stringValueObject] != nil){
                if([[asset stringValueObject] respondsToSelector:[asset stringValueFunction]]){
                    NSString *obj = [[NSString alloc] initWithString:[asset stringCache]];
                    [[asset stringValueObject] performSelector:[asset stringValueFunction] withObject:obj];
                    [obj release];
                }else{
                    NSLog(@"Does not respond to selector @" );
                }
            }
            //Call function
            if([asset function] != nil && [asset functionObject] != nil){
                if([[asset functionObject] respondsToSelector:[asset function]]){
                    [[asset functionObject] performSelector:[asset function] withObject:ElementStop];
                }
            }
            elementAttributeDict = nil;
            [elementAttributeDict release];
        }

        NSString *lastObject;
        @synchronized(self) {
            lastObject = [mElementStack lastObject];
        }

        if([elementName isEqualToString:lastObject]){
            @synchronized(self) {
                [mElementStack removeLastObject];
            }
        }else{
            //XML structure error (!)
            NSLog(@"XML wrong formatted (!)");
            [parser abortParsing];
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    @autoreleasepool {
        //The parser object may send the delegate several parser:foundCharacters: messages to report the characters of an element.
        //Because string may be only part of the total character content for the current element, 
        //you should append it to the current accumulation of characters until the element changes.

        //Are we looking for this ?
        //Check if we are looking for this asset
        BasicParserAsset* asset = [self getAssetForElementStack:mElementStack];
        if(asset != nil){
            [[asset stringCache] appendString:string];
        }
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"%@", [NSString stringWithFormat:@"Parser Error %li, Description: %@, Line: %li, Column: %li", (long)[parseError code], [[parser parserError] localizedDescription], (long)[parser lineNumber], (long)[parser columnNumber]]);
}

/*
 # – parser:didStartMappingPrefix:toURI:  delegate method
 # – parser:didEndMappingPrefix:  delegate method
 # – parser:resolveExternalEntityName:systemID:  delegate method
 # – parser:parseErrorOccurred:  delegate method
 # – parser:validationErrorOccurred:  delegate method
 # – parser:foundIgnorableWhitespace:  delegate method
 # – parser:foundProcessingInstructionWithTarget:data:  delegate method
 # – parser:foundComment:  delegate method
 # – parser:foundCDATA:  delegate method
 */

@end
