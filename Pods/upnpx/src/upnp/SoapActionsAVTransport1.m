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

#import "SoapActionsAVTransport1.h"

#import "OrderedDictionary.h"

@implementation SoapActionsAVTransport1


- (NSInteger)SetAVTransportURIWithInstanceID:(NSString *)instanceid
                                  CurrentURI:(NSString *)currenturi
                          CurrentURIMetaData:(NSString *)currenturimetadata {
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[ @"InstanceID", @"CurrentURI", @"CurrentURIMetaData" ];
    parameterObjects = @[ instanceid ?: @"0",
                          currenturi ?: @"",
                          currenturimetadata ?: @""];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetAVTransportURI" parameters:parameters returnValues:output];
    return ret;
}


- (NSInteger)SetNextAVTransportURIWithInstanceID:(NSString*)instanceid
                                         NextURI:(NSString*)nexturi
                                 NextURIMetaData:(NSString*)nexturimetadata {
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"NextURI", @"NextURIMetaData"];
    parameterObjects = @[ instanceid ?: @"0",
                          nexturi ?: @"",
                          nexturimetadata ?: @""];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetNextAVTransportURI" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetMediaInfoWithInstanceID:(NSString*)instanceid OutNrTracks:(NSMutableString*)nrtracks OutMediaDuration:(NSMutableString*)mediaduration OutCurrentURI:(NSMutableString*)currenturi OutCurrentURIMetaData:(NSMutableString*)currenturimetadata OutNextURI:(NSMutableString*)nexturi OutNextURIMetaData:(NSMutableString*)nexturimetadata OutPlayMedium:(NSMutableString*)playmedium OutRecordMedium:(NSMutableString*)recordmedium OutWriteStatus:(NSMutableString*)writestatus{
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
    outputKeys = @[@"NrTracks", @"MediaDuration", @"CurrentURI", @"CurrentURIMetaData", @"NextURI", @"NextURIMetaData", @"PlayMedium", @"RecordMedium", @"WriteStatus"];
    outputObjects = @[nrtracks, mediaduration, currenturi, currenturimetadata, nexturi, nexturimetadata, playmedium, recordmedium, writestatus];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetMediaInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetTransportInfoWithInstanceID:(NSString*)instanceid OutCurrentTransportState:(NSMutableString*)currenttransportstate OutCurrentTransportStatus:(NSMutableString*)currenttransportstatus OutCurrentSpeed:(NSMutableString*)currentspeed{
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
    outputKeys = @[@"CurrentTransportState", @"CurrentTransportStatus", @"CurrentSpeed"];
    outputObjects = @[currenttransportstate, currenttransportstatus, currentspeed];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetTransportInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetPositionInfoWithInstanceID:(NSString*)instanceid OutTrack:(NSMutableString*)track OutTrackDuration:(NSMutableString*)trackduration OutTrackMetaData:(NSMutableString*)trackmetadata OutTrackURI:(NSMutableString*)trackuri OutRelTime:(NSMutableString*)reltime OutAbsTime:(NSMutableString*)abstime OutRelCount:(NSMutableString*)relcount OutAbsCount:(NSMutableString*)abscount{
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
    outputKeys = @[@"Track", @"TrackDuration", @"TrackMetaData", @"TrackURI", @"RelTime", @"AbsTime", @"RelCount", @"AbsCount"];
    outputObjects = @[track, trackduration, trackmetadata, trackuri, reltime, abstime, relcount, abscount];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetPositionInfo" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetDeviceCapabilitiesWithInstanceID:(NSString*)instanceid OutPlayMedia:(NSMutableString*)playmedia OutRecMedia:(NSMutableString*)recmedia OutRecQualityModes:(NSMutableString*)recqualitymodes{
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
    outputKeys = @[@"PlayMedia", @"RecMedia", @"RecQualityModes"];
    outputObjects = @[playmedia, recmedia, recqualitymodes];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetDeviceCapabilities" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetTransportSettingsWithInstanceID:(NSString*)instanceid OutPlayMode:(NSMutableString*)playmode OutRecQualityMode:(NSMutableString*)recqualitymode{
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
    outputKeys = @[@"PlayMode", @"RecQualityMode"];
    outputObjects = @[playmode, recqualitymode];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetTransportSettings" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)StopWithInstanceID:(NSString*)instanceid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"Stop" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)PlayWithInstanceID:(NSString*)instanceid Speed:(NSString*)speed{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Speed"];
    parameterObjects = @[instanceid, speed];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"Play" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)PauseWithInstanceID:(NSString*)instanceid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"Pause" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)RecordWithInstanceID:(NSString*)instanceid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"Record" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SeekWithInstanceID:(NSString*)instanceid Unit:(NSString*)unit Target:(NSString*)target{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"Unit", @"Target"];
    parameterObjects = @[instanceid, unit, target];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"Seek" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)NextWithInstanceID:(NSString*)instanceid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"Next" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)PreviousWithInstanceID:(NSString*)instanceid{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID"];
    parameterObjects = @[instanceid];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"Previous" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetPlayModeWithInstanceID:(NSString*)instanceid NewPlayMode:(NSString*)newplaymode{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"NewPlayMode"];
    parameterObjects = @[instanceid, newplaymode];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetPlayMode" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)SetRecordQualityModeWithInstanceID:(NSString*)instanceid NewRecordQualityMode:(NSString*)newrecordqualitymode{
    NSInteger ret = 0;

    NSDictionary *parameters = nil;
    NSDictionary *output = nil;
    NSArray *parameterKeys = nil;
    NSArray *parameterObjects = nil;
    parameterKeys = @[@"InstanceID", @"NewRecordQualityMode"];
    parameterObjects = @[instanceid, newrecordqualitymode];
    parameters = [OrderedDictionary dictionaryWithObjects:parameterObjects forKeys:parameterKeys];

    ret = [self action:@"SetRecordQualityMode" parameters:parameters returnValues:output];
    return ret;
}


-(NSInteger)GetCurrentTransportActionsWithInstanceID:(NSString*)instanceid OutActions:(NSMutableString*)actions{
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
    outputKeys = @[@"Actions"];
    outputObjects = @[actions];
    output = [NSDictionary dictionaryWithObjects:outputObjects forKeys:outputKeys];

    ret = [self action:@"GetCurrentTransportActions" parameters:parameters returnValues:output];
    return ret;
}



@end
