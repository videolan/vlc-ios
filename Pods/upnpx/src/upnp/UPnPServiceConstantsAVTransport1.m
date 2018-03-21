// **********************************************************************************
//
// BSD License.
// This file is part of upnpx.
//
// Copyright (c) 2016, Frank Gregor, email: phranck@cocoanaut.com
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


NSString *const UPnPServiceURN_AVTransport1 = @"urn:schemas-upnp-org:service:AVTransport:1";


// Document Reference: http://upnp.org/specs/av/UPnP-av-AVTransport-v1-Service.pdf

// State Variables
NSString *const AVTransport1_SV_TransportState               = @"TransportState";
NSString *const AVTransport1_SV_TransportStatus              = @"TransportStatus";
NSString *const AVTransport1_SV_PlaybackStorageMedium        = @"PlaybackStorageMedium";
NSString *const AVTransport1_SV_RecordStorageMedium          = @"RecordStorageMedium";
NSString *const AVTransport1_SV_PossiblePlaybackStorageMedia = @"PossiblePlaybackStorageMedia";
NSString *const AVTransport1_SV_PossibleRecordStorageMedia   = @"PossibleRecordStorageMedia";
NSString *const AVTransport1_SV_CurrentPlayMode              = @"CurrentPlayMode";
NSString *const AVTransport1_SV_TransportPlaySpeed           = @"TransportPlaySpeed";
NSString *const AVTransport1_SV_RecordMediumWriteStatus      = @"RecordMediumWriteStatus";
NSString *const AVTransport1_SV_CurrentRecordQualityMode     = @"CurrentRecordQualityMode";
NSString *const AVTransport1_SV_PossibleRecordQualityModes   = @"PossibleRecordQualityModes";
NSString *const AVTransport1_SV_NumberOfTracks               = @"NumberOfTracks";
NSString *const AVTransport1_SV_CurrentTrack                 = @"CurrentTrack";
NSString *const AVTransport1_SV_CurrentTrackDuration         = @"CurrentTrackDuration";
NSString *const AVTransport1_SV_CurrentMediaDuration         = @"CurrentMediaDuration";
NSString *const AVTransport1_SV_CurrentTrackMetaData         = @"CurrentTrackMetaData";
NSString *const AVTransport1_SV_CurrentTrackURI              = @"CurrentTrackURI";
NSString *const AVTransport1_SV_AVTransportURI               = @"AVTransportURI";
NSString *const AVTransport1_SV_AVTransportURIMetaData       = @"AVTransportURIMetaData";
NSString *const AVTransport1_SV_NextAVTransportURI           = @"NextAVTransportURI";
NSString *const AVTransport1_SV_NextAVTransportURIMetaData   = @"NextAVTransportURIMetaData";
NSString *const AVTransport1_SV_RelativeTimePosition         = @"RelativeTimePosition";
NSString *const AVTransport1_SV_AbsoluteTimePosition         = @"AbsoluteTimePosition";
NSString *const AVTransport1_SV_RelativeCounterPosition      = @"RelativeCounterPosition";
NSString *const AVTransport1_SV_AbsoluteCounterPosition      = @"AbsoluteCounterPosition";
NSString *const AVTransport1_SV_CurrentTransportActions      = @"CurrentTransportActions";
NSString *const AVTransport1_SV_LastChange                   = @"LastChange";
NSString *const AVTransport1_SV_A_ARG_TYPE_SeekMode          = @"A_ARG_TYPE_SeekMode";
NSString *const AVTransport1_SV_A_ARG_TYPE_SeekTarget        = @"A_ARG_TYPE_SeekTarget";
NSString *const AVTransport1_SV_A_ARG_TYPE_InstanceID        = @"A_ARG_TYPE_InstanceID";



// State Variable Values: TransportState
NSString *const AVTransport1_SVV_TransportState_STOPPED          = @"STOPPED";
NSString *const AVTransport1_SVV_TransportState_PLAYING          = @"PLAYING";
NSString *const AVTransport1_SVV_TransportState_TRANSITIONING    = @"TRANSITIONING";
NSString *const AVTransport1_SVV_TransportState_PAUSED_PLAYBACK  = @"PAUSED_PLAYBACK";
NSString *const AVTransport1_SVV_TransportState_PAUSED_RECORDING = @"PAUSED_RECORDING";
NSString *const AVTransport1_SVV_TransportState_RECORDING        = @"RECORDING";
NSString *const AVTransport1_SVV_TransportState_NO_MEDIA_PRESENT = @"NO_MEDIA_PRESENT";



// State Variable Values: PlaybackStorageMedium
NSString *const AVTransport1_SVV_PlaybackStorageMedium_UNKNOWN         = @"UNKNOWN";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_DV              = @"DV";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_MINI_DV         = @"MINI-DV";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_VHS             = @"VHS";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_W_VHS           = @"W-VHS";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_S_VHS           = @"S-VHS";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_D_VHS           = @"D-VHS";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_VHSC            = @"VHSC";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_VIDEO8          = @"VIDEO8";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_HI8             = @"HI8";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_CD_ROM          = @"CD-ROM";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_CD_DA           = @"CD-DA";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_CD_R            = @"CD-R";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_CD_RW           = @"CD-RW";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_VIDEO_CD        = @"VIDEO-CD";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_SACD            = @"SACD";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_MD_AUDIO        = @"MD-AUDIO";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_MD_PICTURE      = @"MD-PICTURE";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_ROM         = @"DVD-ROM";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_VIDEO       = @"DVD-VIDEO";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_R           = @"DVD-R";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVDPlusRW       = @"DVD+RW";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_RW          = @"DVD-RW";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_RAM         = @"DVD-RAM";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_AUDIO       = @"DVD-AUDIO";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_DAT             = @"DAT";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_LD              = @"LD";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_HDD             = @"HDD";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_MICRO_MV        = @"MICRO-MV";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_NETWORK         = @"NETWORK";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_NONE            = @"NONE";
NSString *const AVTransport1_SVV_PlaybackStorageMedium_NOT_IMPLEMENTED = @"NOT_IMPLEMENTED";



// State Variable Values: CurrentPlayMode
NSString *const AVTransport1_SVV_CurrentPlayMode_NORMAL      = @"NORMAL";
NSString *const AVTransport1_SVV_CurrentPlayMode_SHUFFLEL    = @"SHUFFLE";
NSString *const AVTransport1_SVV_CurrentPlayMode_REPEAT_ONE  = @"REPEAT_ONE";
NSString *const AVTransport1_SVV_CurrentPlayMode_REPEAT_ALLL = @"REPEAT_ALL";
NSString *const AVTransport1_SVV_CurrentPlayMode_RANDOM      = @"RANDOM";
NSString *const AVTransport1_SVV_CurrentPlayMode_DIRECT_1    = @"DIRECT_1";
NSString *const AVTransport1_SVV_CurrentPlayMode_INTRO       = @"INTRO";



// State Variable Values: RecordMediumWriteStatus
NSString *const AVTransport1_SVV_RecordMediumWriteStatus_WRITABLE     = @"WRITABLE";
NSString *const AVTransport1_SVV_RecordMediumWriteStatus_PROTECTED    = @"PROTECTED";
NSString *const AVTransport1_SVV_RecordMediumWriteStatus_NOT_WRITABLE = @"NOT_WRITABLE";
NSString *const AVTransport1_SVV_RecordMediumWriteStatus_UNKNOWN      = @"UNKNOWN";



// State Variable Values: CurrentRecordQualityMode
NSString *const AVTransport1_SVV_CurrentRecordQualityMode_0_EP            = @"0:EP";
NSString *const AVTransport1_SVV_CurrentRecordQualityMode_1_LP            = @"1:LP";
NSString *const AVTransport1_SVV_CurrentRecordQualityMode_2_SP            = @"2:SP";
NSString *const AVTransport1_SVV_CurrentRecordQualityMode_0_BASIC         = @"0:BASIC";
NSString *const AVTransport1_SVV_CurrentRecordQualityMode_1_MEDIUM        = @"1:MEDIUM";
NSString *const AVTransport1_SVV_CurrentRecordQualityMode_2_HIGH          = @"2:HIGH";
NSString *const AVTransport1_SVV_CurrentRecordQualityMode_NOT_IMPLEMENTED = @"NOT_IMPLEMENTED";



// State Variable Values: A_ARG_TYPE_SeekMode
NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_TRACK_NR     = @"TRACK_NR";
NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_ABS_TIME     = @"ABS_TIME";
NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_REL_TIME     = @"REL_TIME";
NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_ABS_COUNT    = @"ABS_COUNT";
NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_REL_COUNT    = @"REL_COUNT";
NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_CHANNEL_FREQ = @"CHANNEL_FREQ";
NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_TAPE_INDEX   = @"TAPE-INDEX";
NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_FRAME        = @"FRAME";
