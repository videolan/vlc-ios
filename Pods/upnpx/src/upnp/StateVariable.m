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


#import "StateVariable.h"


@implementation StateVariable

@synthesize variableType;
@synthesize dataType;
@synthesize name;
@synthesize dataTypeString;


-(instancetype)init{
    self = [super init];

    if (self) {
        variableType = StateVariable_Type_Simple;
        [self empty];
    }

    return self;
}

-(void)dealloc{

    [dataTypeString release];
    [name release];

    [super dealloc];
}


-(void)empty{
    [self setDataTypeString:nil];
    /* IcY: "dataType:" looks like a goto label but is never used
     * should it be dataType = StateVariable_DataType_Unknown
     */
    //dataType: StateVariable_DataType_Unknown;
}


-(void)setDataTypeString:(NSString*)value{
    [dataTypeString release];
    dataTypeString = value;
    [dataTypeString retain];

    if([dataTypeString isEqualToString:@"ui1"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"ui2"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"ui4"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"i1"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"i2"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"i4"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"int"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"r4"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"r8"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"number"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"fixed14.4"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"float"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"boolean"]){
        dataType = StateVariable_DataType_Integer;
    }else if([dataTypeString isEqualToString:@"char"]){
        dataType = StateVariable_DataType_String;
    }else if([dataTypeString isEqualToString:@"string"]){
        dataType = StateVariable_DataType_String;
    }else{
        dataType = StateVariable_DataType_Unknown;
    }//complete the list

}

-(void)copyFromStateVariable:(StateVariable*)stateVar{
    [self setName:[NSString stringWithString:[stateVar name]]];
    dataType = [stateVar dataType];
    [self setDataTypeString:[NSString stringWithString:[stateVar dataTypeString]]];
}



@end
