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

@interface SoapActionsRenderingControl1 : SoapAction {
    }

//SOAP

-(NSInteger)ListPresetsWithInstanceID:(NSString*)instanceid OutCurrentPresetNameList:(NSMutableString*)currentpresetnamelist;
-(NSInteger)SelectPresetWithInstanceID:(NSString*)instanceid PresetName:(NSString*)presetname;
-(NSInteger)GetBrightnessWithInstanceID:(NSString*)instanceid OutCurrentBrightness:(NSMutableString*)currentbrightness;
-(NSInteger)SetBrightnessWithInstanceID:(NSString*)instanceid DesiredBrightness:(NSString*)desiredbrightness;
-(NSInteger)GetContrastWithInstanceID:(NSString*)instanceid OutCurrentContrast:(NSMutableString*)currentcontrast;
-(NSInteger)SetContrastWithInstanceID:(NSString*)instanceid DesiredContrast:(NSString*)desiredcontrast;
-(NSInteger)GetSharpnessWithInstanceID:(NSString*)instanceid OutCurrentSharpness:(NSMutableString*)currentsharpness;
-(NSInteger)SetSharpnessWithInstanceID:(NSString*)instanceid DesiredSharpness:(NSString*)desiredsharpness;
-(NSInteger)GetRedVideoGainWithInstanceID:(NSString*)instanceid OutCurrentRedVideoGain:(NSMutableString*)currentredvideogain;
-(NSInteger)SetRedVideoGainWithInstanceID:(NSString*)instanceid DesiredRedVideoGain:(NSString*)desiredredvideogain;
-(NSInteger)GetGreenVideoGainWithInstanceID:(NSString*)instanceid OutCurrentGreenVideoGain:(NSMutableString*)currentgreenvideogain;
-(NSInteger)SetGreenVideoGainWithInstanceID:(NSString*)instanceid DesiredGreenVideoGain:(NSString*)desiredgreenvideogain;
-(NSInteger)GetBlueVideoGainWithInstanceID:(NSString*)instanceid OutCurrentBlueVideoGain:(NSMutableString*)currentbluevideogain;
-(NSInteger)SetBlueVideoGainWithInstanceID:(NSString*)instanceid DesiredBlueVideoGain:(NSString*)desiredbluevideogain;
-(NSInteger)GetRedVideoBlackLevelWithInstanceID:(NSString*)instanceid OutCurrentRedVideoBlackLevel:(NSMutableString*)currentredvideoblacklevel;
-(NSInteger)SetRedVideoBlackLevelWithInstanceID:(NSString*)instanceid DesiredRedVideoBlackLevel:(NSString*)desiredredvideoblacklevel;
-(NSInteger)GetGreenVideoBlackLevelWithInstanceID:(NSString*)instanceid OutCurrentGreenVideoBlackLevel:(NSMutableString*)currentgreenvideoblacklevel;
-(NSInteger)SetGreenVideoBlackLevelWithInstanceID:(NSString*)instanceid DesiredGreenVideoBlackLevel:(NSString*)desiredgreenvideoblacklevel;
-(NSInteger)GetBlueVideoBlackLevelWithInstanceID:(NSString*)instanceid OutCurrentBlueVideoBlackLevel:(NSMutableString*)currentbluevideoblacklevel;
-(NSInteger)SetBlueVideoBlackLevelWithInstanceID:(NSString*)instanceid DesiredBlueVideoBlackLevel:(NSString*)desiredbluevideoblacklevel;
-(NSInteger)GetColorTemperatureWithInstanceID:(NSString*)instanceid OutCurrentColorTemperature:(NSMutableString*)currentcolortemperature;
-(NSInteger)SetColorTemperatureWithInstanceID:(NSString*)instanceid DesiredColorTemperature:(NSString*)desiredcolortemperature;
-(NSInteger)GetHorizontalKeystoneWithInstanceID:(NSString*)instanceid OutCurrentHorizontalKeystone:(NSMutableString*)currenthorizontalkeystone;
-(NSInteger)SetHorizontalKeystoneWithInstanceID:(NSString*)instanceid DesiredHorizontalKeystone:(NSString*)desiredhorizontalkeystone;
-(NSInteger)GetVerticalKeystoneWithInstanceID:(NSString*)instanceid OutCurrentVerticalKeystone:(NSMutableString*)currentverticalkeystone;
-(NSInteger)SetVerticalKeystoneWithInstanceID:(NSString*)instanceid DesiredVerticalKeystone:(NSString*)desiredverticalkeystone;
-(NSInteger)GetMuteWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel OutCurrentMute:(NSMutableString*)currentmute;
-(NSInteger)SetMuteWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel DesiredMute:(NSString*)desiredmute;
-(NSInteger)GetVolumeWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel OutCurrentVolume:(NSMutableString*)currentvolume;
-(NSInteger)SetVolumeWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel DesiredVolume:(NSString*)desiredvolume;
-(NSInteger)GetVolumeDBWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel OutCurrentVolume:(NSMutableString*)currentvolume;
-(NSInteger)SetVolumeDBWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel DesiredVolume:(NSString*)desiredvolume;
-(NSInteger)GetVolumeDBRangeWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel OutMinValue:(NSMutableString*)minvalue OutMaxValue:(NSMutableString*)maxvalue;
-(NSInteger)GetLoudnessWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel OutCurrentLoudness:(NSMutableString*)currentloudness;
-(NSInteger)SetLoudnessWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel DesiredLoudness:(NSString*)desiredloudness;

@end
