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

#import "SoapActionsRenderingControl1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsRenderingControl1


-(NSInteger)ListPresetsWithInstanceID:(NSString*)instanceid OutCurrentPresetNameList:(NSMutableString*)currentpresetnamelist{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentPresetNameList"];
    outputObjects = @[currentpresetnamelist];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"ListPresets" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SelectPresetWithInstanceID:(NSString*)instanceid PresetName:(NSString*)presetname{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"PresetName"];
    parameterObjects = @[instanceid, presetname];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SelectPreset" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetBrightnessWithInstanceID:(NSString*)instanceid OutCurrentBrightness:(NSMutableString*)currentbrightness{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentBrightness"];
    outputObjects = @[currentbrightness];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetBrightness" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetBrightnessWithInstanceID:(NSString*)instanceid DesiredBrightness:(NSString*)desiredbrightness{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredBrightness"];
    parameterObjects = @[instanceid, desiredbrightness];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetBrightness" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetContrastWithInstanceID:(NSString*)instanceid OutCurrentContrast:(NSMutableString*)currentcontrast{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentContrast"];
    outputObjects = @[currentcontrast];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetContrast" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetContrastWithInstanceID:(NSString*)instanceid DesiredContrast:(NSString*)desiredcontrast{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredContrast"];
    parameterObjects = @[instanceid, desiredcontrast];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetContrast" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetSharpnessWithInstanceID:(NSString*)instanceid OutCurrentSharpness:(NSMutableString*)currentsharpness{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentSharpness"];
    outputObjects = @[currentsharpness];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetSharpness" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetSharpnessWithInstanceID:(NSString*)instanceid DesiredSharpness:(NSString*)desiredsharpness{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredSharpness"];
    parameterObjects = @[instanceid, desiredsharpness];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetSharpness" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetRedVideoGainWithInstanceID:(NSString*)instanceid OutCurrentRedVideoGain:(NSMutableString*)currentredvideogain{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentRedVideoGain"];
    outputObjects = @[currentredvideogain];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetRedVideoGain" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetRedVideoGainWithInstanceID:(NSString*)instanceid DesiredRedVideoGain:(NSString*)desiredredvideogain{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredRedVideoGain"];
    parameterObjects = @[instanceid, desiredredvideogain];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetRedVideoGain" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetGreenVideoGainWithInstanceID:(NSString*)instanceid OutCurrentGreenVideoGain:(NSMutableString*)currentgreenvideogain{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentGreenVideoGain"];
    outputObjects = @[currentgreenvideogain];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetGreenVideoGain" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetGreenVideoGainWithInstanceID:(NSString*)instanceid DesiredGreenVideoGain:(NSString*)desiredgreenvideogain{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredGreenVideoGain"];
    parameterObjects = @[instanceid, desiredgreenvideogain];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetGreenVideoGain" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetBlueVideoGainWithInstanceID:(NSString*)instanceid OutCurrentBlueVideoGain:(NSMutableString*)currentbluevideogain{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentBlueVideoGain"];
    outputObjects = @[currentbluevideogain];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetBlueVideoGain" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetBlueVideoGainWithInstanceID:(NSString*)instanceid DesiredBlueVideoGain:(NSString*)desiredbluevideogain{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredBlueVideoGain"];
    parameterObjects = @[instanceid, desiredbluevideogain];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetBlueVideoGain" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetRedVideoBlackLevelWithInstanceID:(NSString*)instanceid OutCurrentRedVideoBlackLevel:(NSMutableString*)currentredvideoblacklevel{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentRedVideoBlackLevel"];
    outputObjects = @[currentredvideoblacklevel];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetRedVideoBlackLevel" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetRedVideoBlackLevelWithInstanceID:(NSString*)instanceid DesiredRedVideoBlackLevel:(NSString*)desiredredvideoblacklevel{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredRedVideoBlackLevel"];
    parameterObjects = @[instanceid, desiredredvideoblacklevel];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetRedVideoBlackLevel" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetGreenVideoBlackLevelWithInstanceID:(NSString*)instanceid OutCurrentGreenVideoBlackLevel:(NSMutableString*)currentgreenvideoblacklevel{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentGreenVideoBlackLevel"];
    outputObjects = @[currentgreenvideoblacklevel];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetGreenVideoBlackLevel" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetGreenVideoBlackLevelWithInstanceID:(NSString*)instanceid DesiredGreenVideoBlackLevel:(NSString*)desiredgreenvideoblacklevel{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredGreenVideoBlackLevel"];
    parameterObjects = @[instanceid, desiredgreenvideoblacklevel];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetGreenVideoBlackLevel" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetBlueVideoBlackLevelWithInstanceID:(NSString*)instanceid OutCurrentBlueVideoBlackLevel:(NSMutableString*)currentbluevideoblacklevel{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentBlueVideoBlackLevel"];
    outputObjects = @[currentbluevideoblacklevel];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetBlueVideoBlackLevel" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetBlueVideoBlackLevelWithInstanceID:(NSString*)instanceid DesiredBlueVideoBlackLevel:(NSString*)desiredbluevideoblacklevel{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredBlueVideoBlackLevel"];
    parameterObjects = @[instanceid, desiredbluevideoblacklevel];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetBlueVideoBlackLevel" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetColorTemperatureWithInstanceID:(NSString*)instanceid OutCurrentColorTemperature:(NSMutableString*)currentcolortemperature{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentColorTemperature"];
    outputObjects = @[currentcolortemperature];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetColorTemperature" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetColorTemperatureWithInstanceID:(NSString*)instanceid DesiredColorTemperature:(NSString*)desiredcolortemperature{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredColorTemperature"];
    parameterObjects = @[instanceid, desiredcolortemperature];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetColorTemperature" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetHorizontalKeystoneWithInstanceID:(NSString*)instanceid OutCurrentHorizontalKeystone:(NSMutableString*)currenthorizontalkeystone{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentHorizontalKeystone"];
    outputObjects = @[currenthorizontalkeystone];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetHorizontalKeystone" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetHorizontalKeystoneWithInstanceID:(NSString*)instanceid DesiredHorizontalKeystone:(NSString*)desiredhorizontalkeystone{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredHorizontalKeystone"];
    parameterObjects = @[instanceid, desiredhorizontalkeystone];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetHorizontalKeystone" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetVerticalKeystoneWithInstanceID:(NSString*)instanceid OutCurrentVerticalKeystone:(NSMutableString*)currentverticalkeystone{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentVerticalKeystone"];
    outputObjects = @[currentverticalkeystone];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetVerticalKeystone" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetVerticalKeystoneWithInstanceID:(NSString*)instanceid DesiredVerticalKeystone:(NSString*)desiredverticalkeystone{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"DesiredVerticalKeystone"];
    parameterObjects = @[instanceid, desiredverticalkeystone];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetVerticalKeystone" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetMuteWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel OutCurrentMute:(NSMutableString*)currentmute{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Channel"];
    parameterObjects = @[instanceid, channel];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentMute"];
    outputObjects = @[currentmute];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetMute" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetMuteWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel DesiredMute:(NSString*)desiredmute{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Channel", @"DesiredMute"];
    parameterObjects = @[instanceid, channel, desiredmute];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetMute" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetVolumeWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel OutCurrentVolume:(NSMutableString*)currentvolume{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Channel"];
    parameterObjects = @[instanceid, channel];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentVolume"];
    outputObjects = @[currentvolume];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetVolume" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetVolumeWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel DesiredVolume:(NSString*)desiredvolume{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Channel", @"DesiredVolume"];
    parameterObjects = @[instanceid, channel, desiredvolume];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetVolume" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetVolumeDBWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel OutCurrentVolume:(NSMutableString*)currentvolume{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Channel"];
    parameterObjects = @[instanceid, channel];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentVolume"];
    outputObjects = @[currentvolume];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetVolumeDB" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetVolumeDBWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel DesiredVolume:(NSString*)desiredvolume{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Channel", @"DesiredVolume"];
    parameterObjects = @[instanceid, channel, desiredvolume];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetVolumeDB" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetVolumeDBRangeWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel OutMinValue:(NSMutableString*)minvalue OutMaxValue:(NSMutableString*)maxvalue{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Channel"];
    parameterObjects = @[instanceid, channel];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"MinValue", @"MaxValue"];
    outputObjects = @[minvalue, maxvalue];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetVolumeDBRange" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetLoudnessWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel OutCurrentLoudness:(NSMutableString*)currentloudness{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Channel"];
    parameterObjects = @[instanceid, channel];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    NSArray *outputObjects = nil;
    NSArray *outputKeys = nil;
    outputKeys = @[@"CurrentLoudness"];
    outputObjects = @[currentloudness];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetLoudness" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetLoudnessWithInstanceID:(NSString*)instanceid Channel:(NSString*)channel DesiredLoudness:(NSString*)desiredloudness{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Channel", @"DesiredLoudness"];
    parameterObjects = @[instanceid, channel, desiredloudness];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetLoudness" parameters:parameters returnValues:output];
    return ret;
}



@end
