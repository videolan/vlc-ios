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
#import "SoapAction.h"

@interface SoapActionsContentDirectory1 : SoapAction {
    }

//SOAP

-(NSInteger)GetSearchCapabilitiesWithOutSearchCaps:(NSMutableString*)searchcaps;
-(NSInteger)GetSortCapabilitiesWithOutSortCaps:(NSMutableString*)sortcaps;
-(NSInteger)GetSystemUpdateIDWithOutId:(NSMutableString*)id;
-(NSInteger)BrowseWithObjectID:(NSString*)objectid BrowseFlag:(NSString*)browseflag Filter:(NSString*)filter StartingIndex:(NSString*)startingindex RequestedCount:(NSString*)requestedcount SortCriteria:(NSString*)sortcriteria OutResult:(NSMutableString*)result OutNumberReturned:(NSMutableString*)numberreturned OutTotalMatches:(NSMutableString*)totalmatches OutUpdateID:(NSMutableString*)updateid;
-(NSInteger)SearchWithContainerID:(NSString*)containerid SearchCriteria:(NSString*)searchcriteria Filter:(NSString*)filter StartingIndex:(NSString*)startingindex RequestedCount:(NSString*)requestedcount SortCriteria:(NSString*)sortcriteria OutResult:(NSMutableString*)result OutNumberReturned:(NSMutableString*)numberreturned OutTotalMatches:(NSMutableString*)totalmatches OutUpdateID:(NSMutableString*)updateid;
-(NSInteger)CreateObjectWithContainerID:(NSString*)containerid Elements:(NSString*)elements OutObjectID:(NSMutableString*)objectid OutResult:(NSMutableString*)result;
-(NSInteger)DestroyObjectWithObjectID:(NSString*)objectid;
-(NSInteger)UpdateObjectWithObjectID:(NSString*)objectid CurrentTagValue:(NSString*)currenttagvalue NewTagValue:(NSString*)newtagvalue;
-(NSInteger)ImportResourceWithSourceURI:(NSString*)sourceuri DestinationURI:(NSString*)destinationuri OutTransferID:(NSMutableString*)transferid;
-(NSInteger)ExportResourceWithSourceURI:(NSString*)sourceuri DestinationURI:(NSString*)destinationuri OutTransferID:(NSMutableString*)transferid;
-(NSInteger)StopTransferResourceWithTransferID:(NSString*)transferid;
-(NSInteger)GetTransferProgressWithTransferID:(NSString*)transferid OutTransferStatus:(NSMutableString*)transferstatus OutTransferLength:(NSMutableString*)transferlength OutTransferTotal:(NSMutableString*)transfertotal;
-(NSInteger)DeleteResourceWithResourceURI:(NSString*)resourceuri;
-(NSInteger)CreateReferenceWithContainerID:(NSString*)containerid ObjectID:(NSString*)objectid OutNewID:(NSMutableString*)newid;

@end
