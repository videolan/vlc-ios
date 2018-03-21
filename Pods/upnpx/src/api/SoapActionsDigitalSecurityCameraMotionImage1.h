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

@interface SoapActionsDigitalSecurityCameraMotionImage1 : SoapAction {
    }

//SOAP

-(NSInteger)GetAvailableEncodingsWithOutRetAvailableEncodings:(NSMutableString*)retavailableencodings;
-(NSInteger)GetDefaultEncodingWithOutRetEncoding:(NSMutableString*)retencoding;
-(NSInteger)SetDefaultEncodingWithReqEncoding:(NSString*)reqencoding;
-(NSInteger)GetAvailableCompressionLevelsWithOutRetAvailableCompressionLevels:(NSMutableString*)retavailablecompressionlevels;
-(NSInteger)GetDefaultCompressionLevelWithOutRetCompressionLevel:(NSMutableString*)retcompressionlevel;
-(NSInteger)SetDefaultCompressionLevelWithReqCompressionLevel:(NSString*)reqcompressionlevel;
-(NSInteger)GetAvailableResolutionsWithOutRetAvailableResolutions:(NSMutableString*)retavailableresolutions;
-(NSInteger)GetDefaultResolutionWithOutRetResolution:(NSMutableString*)retresolution;
-(NSInteger)SetDefaultResolutionWithReqResolution:(NSString*)reqresolution;
-(NSInteger)GetVideoURLWithReqEncoding:(NSString*)reqencoding ReqCompression:(NSString*)reqcompression ReqResolution:(NSString*)reqresolution ReqMaxBandwidth:(NSString*)reqmaxbandwidth ReqTargetFrameRate:(NSString*)reqtargetframerate OutRetVideoURL:(NSMutableString*)retvideourl;
-(NSInteger)GetDefaultVideoURLWithOutRetVideoURL:(NSMutableString*)retvideourl;
-(NSInteger)GetVideoPresentationURLWithReqEncoding:(NSString*)reqencoding ReqCompression:(NSString*)reqcompression ReqResolution:(NSString*)reqresolution ReqMaxBandwidth:(NSString*)reqmaxbandwidth ReqTargetFrameRate:(NSString*)reqtargetframerate OutRetVideoPresentationURL:(NSMutableString*)retvideopresentationurl;
-(NSInteger)GetDefaultVideoPresentationURLWithOutRetVideoPresentationURL:(NSMutableString*)retvideopresentationurl;
-(NSInteger)SetMaxBandwidthWithReqMaxBandwidth:(NSString*)reqmaxbandwidth;
-(NSInteger)GetMaxBandwidthWithOutRetMaxBandwidth:(NSMutableString*)retmaxbandwidth;
-(NSInteger)SetTargetFrameRateWithReqTargetFrameRate:(NSString*)reqtargetframerate;
-(NSInteger)GetTargetFrameRateWithOutRetTargetFrameRate:(NSMutableString*)rettargetframerate;

@end
