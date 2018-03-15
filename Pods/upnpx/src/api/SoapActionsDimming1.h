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

#import <Foundation/Foundation.h>
#import "SoapAction.h"

@interface SoapActionsDimming1 : SoapAction {
    }

//SOAP

-(NSInteger)SetLoadLevelTargetWithnewLoadlevelTarget:(NSString*)newloadleveltarget;
-(NSInteger)GetLoadLevelTargetWithOutGetLoadlevelTarget:(NSMutableString*)getloadleveltarget;
-(NSInteger)GetLoadLevelStatusWithOutretLoadlevelStatus:(NSMutableString*)retloadlevelstatus;
-(NSInteger)SetOnEffectLevelWithnewOnEffectLevel:(NSString*)newoneffectlevel;
-(NSInteger)SetOnEffectWithnewOnEffect:(NSString*)newoneffect;
-(NSInteger)GetOnEffectParametersWithOutretOnEffect:(NSMutableString*)retoneffect OutretOnEffectLevel:(NSMutableString*)retoneffectlevel;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger StepUp;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger StepDown;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger StartRampUp;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger StartRampDown;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger StopRamp;
-(NSInteger)StartRampToLevelWithnewLoadLevelTarget:(NSString*)newloadleveltarget newRampTime:(NSString*)newramptime;
-(NSInteger)SetStepDeltaWithnewStepDelta:(NSString*)newstepdelta;
-(NSInteger)GetStepDeltaWithOutretStepDelta:(NSMutableString*)retstepdelta;
-(NSInteger)SetRampRateWithnewRampRate:(NSString*)newramprate;
-(NSInteger)GetRampRateWithOutretRampRate:(NSMutableString*)retramprate;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger PauseRamp;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger ResumeRamp;
-(NSInteger)GetIsRampingWithOutretIsRamping:(NSMutableString*)retisramping;
-(NSInteger)GetRampPausedWithOutretRampPaused:(NSMutableString*)retramppaused;
-(NSInteger)GetRampTimeWithOutretRampTime:(NSMutableString*)retramptime;

@end
