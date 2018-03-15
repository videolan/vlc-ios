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


FOUNDATION_EXPORT NSString *const UPnPServiceURN_AVTransport1;


// State Variables
FOUNDATION_EXPORT NSString *const AVTransport1_SV_TransportState;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_TransportStatus;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_PlaybackStorageMedium;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_RecordStorageMedium;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_PossiblePlaybackStorageMedia;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_PossibleRecordStorageMedia;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_CurrentPlayMode;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_TransportPlaySpeed;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_RecordMediumWriteStatus;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_CurrentRecordQualityMode;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_PossibleRecordQualityModes;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_NumberOfTracks;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_CurrentTrack;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_CurrentTrackDuration;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_CurrentMediaDuration;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_CurrentTrackMetaData;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_CurrentTrackURI;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_AVTransportURI;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_AVTransportURIMetaData;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_NextAVTransportURI;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_NextAVTransportURIMetaData;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_RelativeTimePosition;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_AbsoluteTimePosition;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_RelativeCounterPosition;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_AbsoluteCounterPosition;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_CurrentTransportActions;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_LastChange;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_A_ARG_TYPE_SeekMode;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_A_ARG_TYPE_SeekTarget;
FOUNDATION_EXPORT NSString *const AVTransport1_SV_A_ARG_TYPE_InstanceID;



// State Variable Values: TransportState
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_TransportState_STOPPED;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_TransportState_PLAYING;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_TransportState_TRANSITIONING;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_TransportState_PAUSED_PLAYBACK;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_TransportState_PAUSED_RECORDING;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_TransportState_RECORDING;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_TransportState_NO_MEDIA_PRESENT;



// State Variable Values: PlaybackStorageMedium
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_UNKNOWN;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_DV;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_MINI_DV;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_VHS;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_W_VHS;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_S_VHS;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_D_VHS;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_VHSC;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_VIDEO8;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_HI8;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_CD_ROM;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_CD_DA;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_CD_R;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_CD_RW;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_VIDEO_CD;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_SACD;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_MD_AUDIO;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_MD_PICTURE;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_ROM;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_VIDEO;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_R;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVDPlusRW;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_RW;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_RAM;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_DVD_AUDIO;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_DAT;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_LD;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_HDD;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_MICRO_MV;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_NETWORK;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_NONE;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_PlaybackStorageMedium_NOT_IMPLEMENTED;



// State Variable Values: CurrentPlayMode
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentPlayMode_NORMAL;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentPlayMode_SHUFFLEL;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentPlayMode_REPEAT_ONE;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentPlayMode_REPEAT_ALLL;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentPlayMode_RANDOM;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentPlayMode_DIRECT_1;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentPlayMode_INTRO;



// State Variable Values: RecordMediumWriteStatus
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_RecordMediumWriteStatus_WRITABLE;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_RecordMediumWriteStatus_PROTECTED;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_RecordMediumWriteStatus_NOT_WRITABLE;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_RecordMediumWriteStatus_UNKNOWN;



// State Variable Values: CurrentRecordQualityMode
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentRecordQualityMode_0_EP;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentRecordQualityMode_1_LP;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentRecordQualityMode_2_SP;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentRecordQualityMode_0_BASIC;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentRecordQualityMode_1_MEDIUM;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentRecordQualityMode_2_HIGH;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_CurrentRecordQualityMode_NOT_IMPLEMENTED;



// State Variable Values: A_ARG_TYPE_SeekMode
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_TRACK_NR;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_ABS_TIME;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_REL_TIME;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_ABS_COUNT;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_REL_COUNT;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_CHANNEL_FREQ;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_TAPE_INDEX;
FOUNDATION_EXPORT NSString *const AVTransport1_SVV_A_ARG_TYPE_SeekMode_FRAME;
