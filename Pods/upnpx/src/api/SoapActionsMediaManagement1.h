//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import <Foundation/Foundation.h>
#import "SoapAction.h"

@interface SoapActionsMediaManagement1 : SoapAction {
    }

//SOAP

-(NSInteger)GetMediaCapabilitiesWithTSMediaCapabilityInfo:(NSString*)tsmediacapabilityinfo OutSupportedMediaCapabilityInfo:(NSMutableString*)supportedmediacapabilityinfo;
-(NSInteger)GetMediaSessionInfoWithTargetMediaSessionID:(NSString*)targetmediasessionid OutMediaSessionInfoList:(NSMutableString*)mediasessioninfolist;
-(NSInteger)ModifyMediaSessionWithTargetMediaSessionID:(NSString*)targetmediasessionid NewMediaCapabilityInfo:(NSString*)newmediacapabilityinfo OutTCMediaCapabilityInfo:(NSMutableString*)tcmediacapabilityinfo;
-(NSInteger)StartMediaSessionWithTSMediaCapabilityInfo:(NSString*)tsmediacapabilityinfo OutMediaSessionID:(NSMutableString*)mediasessionid OutTCMediaCapabilityInfo:(NSMutableString*)tcmediacapabilityinfo;
-(NSInteger)StopMediaSessionWithTargetMediaSessionID:(NSString*)targetmediasessionid;

@end
