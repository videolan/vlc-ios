// ******************************************************************
//
// MIT License.
// This file is part of upnpx.
//
// Copyright (c) 2010, 2011 Bruno Keymolen, email: bruno.keymolen@gmail.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// ******************************************************************

#import "SoapActionsContentDirectory1.h"
#import "OrderedDictionary.h"

@implementation SoapActionsContentDirectory1

-(NSInteger)GetSearchCapabilitiesWithOutSearchCaps:(NSMutableString*)searchcaps{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"SearchCaps"];
    outputObjects = @[searchcaps];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetSearchCapabilities" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetSortCapabilitiesWithOutSortCaps:(NSMutableString*)sortcaps{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"SortCaps"];
    outputObjects = @[sortcaps];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetSortCapabilities" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetSystemUpdateIDWithOutId:(NSMutableString*)id{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"Id"];
    outputObjects = @[id];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetSystemUpdateID" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)BrowseWithObjectID:(NSString*)objectid BrowseFlag:(NSString*)browseflag Filter:(NSString*)filter StartingIndex:(NSString*)startingindex RequestedCount:(NSString*)requestedcount SortCriteria:(NSString*)sortcriteria OutResult:(NSMutableString*)result OutNumberReturned:(NSMutableString*)numberreturned OutTotalMatches:(NSMutableString*)totalmatches OutUpdateID:(NSMutableString*)updateid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ObjectID", @"BrowseFlag", @"Filter", @"StartingIndex", @"RequestedCount", @"SortCriteria"];
    parameterObjects = @[objectid, browseflag, filter, startingindex, requestedcount, sortcriteria];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"Result", @"NumberReturned", @"TotalMatches", @"UpdateID"];
    outputObjects = @[result, numberreturned, totalmatches, updateid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"Browse" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SearchWithContainerID:(NSString*)containerid SearchCriteria:(NSString*)searchcriteria Filter:(NSString*)filter StartingIndex:(NSString*)startingindex RequestedCount:(NSString*)requestedcount SortCriteria:(NSString*)sortcriteria OutResult:(NSMutableString*)result OutNumberReturned:(NSMutableString*)numberreturned OutTotalMatches:(NSMutableString*)totalmatches OutUpdateID:(NSMutableString*)updateid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ContainerID", @"SearchCriteria", @"Filter", @"StartingIndex", @"RequestedCount", @"SortCriteria"];
    parameterObjects = @[containerid, searchcriteria, filter, startingindex, requestedcount, sortcriteria];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"Result", @"NumberReturned", @"TotalMatches", @"UpdateID"];
    outputObjects = @[result, numberreturned, totalmatches, updateid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"Search" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)CreateObjectWithContainerID:(NSString*)containerid Elements:(NSString*)elements OutObjectID:(NSMutableString*)objectid OutResult:(NSMutableString*)result{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ContainerID", @"Elements"];
    parameterObjects = @[containerid, elements];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"ObjectID", @"Result"];
    outputObjects = @[objectid, result];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"CreateObject" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)DestroyObjectWithObjectID:(NSString*)objectid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ObjectID"];
    parameterObjects = @[objectid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"DestroyObject" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)UpdateObjectWithObjectID:(NSString*)objectid CurrentTagValue:(NSString*)currenttagvalue NewTagValue:(NSString*)newtagvalue{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ObjectID", @"CurrentTagValue", @"NewTagValue"];
    parameterObjects = @[objectid, currenttagvalue, newtagvalue];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"UpdateObject" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)ImportResourceWithSourceURI:(NSString*)sourceuri DestinationURI:(NSString*)destinationuri OutTransferID:(NSMutableString*)transferid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SourceURI", @"DestinationURI"];
    parameterObjects = @[sourceuri, destinationuri];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"TransferID"];
    outputObjects = @[transferid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"ImportResource" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)ExportResourceWithSourceURI:(NSString*)sourceuri DestinationURI:(NSString*)destinationuri OutTransferID:(NSMutableString*)transferid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"SourceURI", @"DestinationURI"];
    parameterObjects = @[sourceuri, destinationuri];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"TransferID"];
    outputObjects = @[transferid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"ExportResource" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)StopTransferResourceWithTransferID:(NSString*)transferid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"TransferID"];
    parameterObjects = @[transferid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"StopTransferResource" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetTransferProgressWithTransferID:(NSString*)transferid OutTransferStatus:(NSMutableString*)transferstatus OutTransferLength:(NSMutableString*)transferlength OutTransferTotal:(NSMutableString*)transfertotal{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"TransferID"];
    parameterObjects = @[transferid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"TransferStatus", @"TransferLength", @"TransferTotal"];
    outputObjects = @[transferstatus, transferlength, transfertotal];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetTransferProgress" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)DeleteResourceWithResourceURI:(NSString*)resourceuri{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ResourceURI"];
    parameterObjects = @[resourceuri];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"DeleteResource" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)CreateReferenceWithContainerID:(NSString*)containerid ObjectID:(NSString*)objectid OutNewID:(NSMutableString*)newid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"ContainerID", @"ObjectID"];
    parameterObjects = @[containerid, objectid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"NewID"];
    outputObjects = @[newid];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"CreateReference" parameters:parameters returnValues:output];
    return ret;
}

@end
