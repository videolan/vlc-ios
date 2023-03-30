/*****************************************************************************
 * VLCTVConstants.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#define kVLCRecentURLs @"recent-urls"
#define kVLCRecentURLTitles @"recent-url-titles"
#define kVLCStoreDropboxCredentials @"kVLCStoreDropboxCredentials"
#define kVLCStoreOneDriveCredentials @"kVLCStoreOneDriveCredentials"
#define kVLCStoreBoxCredentials @"kVLCStoreBoxCredentials"
#define kVLCStoreGDriveCredentials @"kVLCStoreGDriveCredentials"

#define kSupportedFileExtensions @"\\.(3g2|3gp|3gp2|3gpp|amv|asf|avi|bik|bin|crf|divx|drc|dv|evo|f4v|flv|gvi|gxf|hevc|iso|m1v|m2v|m2t|m2ts|m4v|mkv|mov|mp2|mp2v|mp4|mp4v|mpe|mpeg|mpeg1|mpeg2|mpeg4|mpg|mpv2|mts|mtv|mxf|mxg|nsv|nuv|ogg|ogm|ogv|ogx|ps|rec|rm|rmvb|rpl|thp|tod|ts|tts|txd|vob|vro|webm|wm|wmv|wtv|xesc)$"
#define kSupportedSubtitleFileExtensions @"\\.(cdg|idx|srt|sub|utf|ass|ssa|aqt|jss|psb|rt|smi|txt|smil|stl|usf|dks|pjs|mpl2|mks|vtt|ttml|dfxp)$"
#define kSupportedAudioFileExtensions @"\\.(3ga|669|a52|aac|ac3|adt|adts|aif|aifc|aiff|amb|amr|aob|ape|au|awb|caf|dts|flac|it|kar|m4a|m4b|m4p|m5p|mid|mka|mlp|mod|mpa|mp1|mp2|mp3|mpc|mpga|mus|oga|ogg|oma|opus|qcp|ra|rmi|s3m|sid|spx|tak|thd|tta|voc|vqf|w64|wav|wma|wv|xa|xm)$"
#define kSupportedPlaylistFileExtensions @"\\.(asx|b4s|cue|ifo|m3u|m3u8|pls|ram|rar|sdp|vlc|xspf|wax|wvx|zip|conf)$"

#define kSupportedProtocolSchemes @"(rtsp|mms|mmsh|udp|rtp|rtmp|sftp|ftp|smb)$"

#define kVLCSettingPlaybackSpeedDefaultValue @"playback-speed"
#define kVLCSettingNetworkCaching @"network-caching"
#define kVLCSettingNetworkCachingDefaultValue @(999)
#define kVLCSettingNetworkRTSPTCP @"rtsp-tcp"
#define kVLCSaveDebugLogs @"kVLCSaveDebugLogs"
#define kVLCSettingNetworkSatIPChannelList @"satip-channelist"
#define kVLCSettingNetworkSatIPChannelListCustom @"CustomList"
#define kVLCSettingNetworkSatIPChannelListUrl @"satip-channellist-url"
#define kVLCSettingSkipLoopFilter @"avcodec-skiploopfilter"
#define kVLCSettingSkipLoopFilterNone @(0)
#define kVLCSettingSkipLoopFilterNonRef @(1)
#define kVLCSettingSkipLoopFilterNonKey @(3)
#define kVLCSettingDeinterlace @"deinterlace"
#define kVLCSettingDeinterlaceDefaultValue @(-1)
#define kVLCSettingHardwareDecoding @"codec"
#define kVLCSettingHardwareDecodingDefault @""
#define kVLCSettingSubtitlesFont @"quartztext-font"
#define kVLCSettingSubtitlesFontDefaultValue @"HelveticaNeue"
#define kVLCSettingSubtitlesFontSize @"quartztext-rel-fontsize"
#define kVLCSettingSubtitlesFontSizeDefaultValue @"16"
#define kVLCSettingSubtitlesBoldFont @"quartztext-bold"
#define kVLCSettingSubtitlesBoldFontDefaultValue @NO
#define kVLCSettingSubtitlesFontColor @"quartztext-color"
#define kVLCSettingSubtitlesFontColorDefaultValue @"16777215"
#define kVLCSubtitlesCacheFolderName @"cached-subtitles"
#define kVLCSettingTextEncoding @"subsdec-encoding"
#define kVLCSettingTextEncodingDefaultValue @"Windows-1252"
#define kVLCSettingStretchAudio @"audio-time-stretch"
#define kVLCSettingStretchAudioOnValue @"1"
#define kVLCSettingStretchAudioOffValue @"0"
#define kVLCSettingContinueAudioInBackgroundKey @"BackgroundAudioPlayback"
#define kVLCSettingDefaultPreampLevel @"pre-amp-level"
#define kVLCSettingSubtitlesFilePath @"sub-file"
#define kVLCSettingEqualizerProfile @"EqualizerProfile"
#define kVLCSettingEqualizerProfileDisabled @"EqualizerDisabled"
#define kVLCSettingEqualizerProfileDefaultValue @(0)
#define kVLCSettingPlaybackForwardSkipLength @"playback-forward-skip-length"
#define kVLCSettingPlaybackForwardSkipLengthDefaultValue @(10)
#define kVLCSettingPlaybackBackwardSkipLength @"playback-backward-skip-length"
#define kVLCSettingPlaybackBackwardSkipLengthDefaultValue @(10)
#define kVLCSettingSaveHTTPUploadServerStatus @"isHTTPServerOn"
#define kVLCAutomaticallyPlayNextItem @"AutomaticallyPlayNextItem"
#define kVLCSettingDownloadArtwork @"download-artwork"
#define kVLCSettingUseSPDIF @"kVLCSettingUseSPDIF"
#define kVLCSettingBackupMediaLibrary @"BackupMediaLibrary"
#define kVLCSettingBackupMediaLibraryDefaultValue @NO

#define kVLCSettingLastUsedSubtitlesSearchLanguage @"kVLCSettingLastUsedSubtitlesSearchLanguage"
#define kVLCSettingWiFiSharingIPv6 @"wifi-sharing-ipv6"
#define kVLCSettingWiFiSharingIPv6DefaultValue @(NO)

#define kVLCfortvOSMovieDBKey @""

#define kVLCStoredServerList @"kVLCStoredServerList"

#define kVLCHTTPUploadDirectory @"Upload"

#define kVLCSettingCastingAudioPassthrough @"sout-chromecast-audio-passthrough"
#define kVLCSettingCastingConversionQuality @"sout-chromecast-conversion-quality"

#define kVLCForceSMBV1 @"smb-force-v1"
