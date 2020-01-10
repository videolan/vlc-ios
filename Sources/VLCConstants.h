/*****************************************************************************
 * VLCConstants.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#define kVLCVersionCodename @"All Along the Watchtower"

#define kVLCSettingPasscodeOnKey @"PasscodeProtection"
#define kVLCSettingPasscodeAllowTouchID @"AllowTouchID"
#define kVLCSettingPasscodeAllowFaceID @"AllowFaceID"
#define kVLCThemeDidChangeNotification @"themeDidChangeNotfication"
#define kVLCSettingAppTheme @"darkMode"
#define kVLCSettingAppThemeBright 0
#define kVLCSettingAppThemeDark 1
#define kVLCSettingAppThemeSystem 2
#define kVLCOptimizeItemNamesForDisplay @"MLDecrapifyTitles"
#define kVLCSettingAbout @"about"
#define kVLCAutomaticallyPlayNextItem @"AutomaticallyPlayNextItem"
#define kVLCSettingContinueAudioInBackgroundKey @"BackgroundAudioPlayback"
#define kVLCSettingStretchAudio @"audio-time-stretch"
#define kVLCSettingStretchAudioOnValue @"1"
#define kVLCSettingStretchAudioOffValue @"0"
#define kVLCSettingTextEncoding @"subsdec-encoding"
#define kVLCSettingTextEncodingDefaultValue @"Windows-1252"
#define kVLCSettingSkipLoopFilter @"avcodec-skiploopfilter"
#define kVLCSettingSkipLoopFilterNone @(0)
#define kVLCSettingSkipLoopFilterNonRef @(1)
#define kVLCSettingSaveHTTPUploadServerStatus @"isHTTPServerOn"
#define kVLCSettingSubtitlesFont @"quartztext-font"
#define kVLCSettingSubtitlesFontDefaultValue @"HelveticaNeue"
#define kVLCSettingSubtitlesFontSize @"quartztext-rel-fontsize"
#define kVLCSettingSubtitlesFontSizeDefaultValue @"16"
#define kVLCSettingSubtitlesBoldFont @"quartztext-bold"
#define kVLCSettingSubtitlesBoldFontDefaultValue @NO
#define kVLCSettingSubtitlesFontColor @"quartztext-color"
#define kVLCSettingSubtitlesFontColorDefaultValue @"16777215"
#define kVLCSettingSubtitlesFilePath @"sub-file"
#define kVLCSettingDeinterlace @"deinterlace"
#define kVLCSettingDeinterlaceDefaultValue @(0)
#define kVLCSettingHardwareDecoding @"codec"
#define kVLCSettingHardwareDecodingDefault @""
#define kVLCSettingNetworkCaching @"network-caching"
#define kVLCSettingNetworkCachingDefaultValue @(999)
#define kVLCSettingsDecrapifyTitles @"MLDecrapifyTitles"
#define kVLCSettingVolumeGesture @"EnableVolumeGesture"
#define kVLCSettingPlayPauseGesture @"EnablePlayPauseGesture"
#define kVLCSettingBrightnessGesture @"EnableBrightnessGesture"
#define kVLCSettingSeekGesture @"EnableSeekGesture"
#define kVLCSettingCloseGesture @"EnableCloseGesture"
#define kVLCSettingVariableJumpDuration @"EnableVariableJumpDuration"
#define kVLCSettingVideoFullscreenPlayback @"AlwaysUseFullscreenForVideo"
#define kVLCSettingContinuePlayback @"ContinuePlayback"
#define kVLCSettingContinueAudioPlayback @"ContinueAudioPlayback"
#define kVLCSettingFTPTextEncoding @"ftp-text-encoding"
#define kVLCSettingFTPTextEncodingDefaultValue @(5) // ISO Latin 1
#define kVLCSettingPlaybackSpeedDefaultValue @"playback-speed"
#define kVLCSettingWiFiSharingIPv6 @"wifi-sharing-ipv6"
#define kVLCSettingWiFiSharingIPv6DefaultValue @(NO)
#define kVLCSettingEqualizerProfile @"EqualizerProfile"
#define kVLCSettingEqualizerProfileDisabled @"EqualizerDisabled"
#define kVLCSettingEqualizerProfileDefaultValue @(0)
#define kVLCSettingPlaybackForwardSkipLength @"playback-forward-skip-length"
#define kVLCSettingPlaybackForwardSkipLengthDefaultValue @(60)
#define kVLCSettingPlaybackBackwardSkipLength @"playback-forward-skip-length"
#define kVLCSettingPlaybackBackwardSkipLengthDefaultValue @(60)
#define kVLCSettingOpenAppForPlayback @"open-app-for-playback"
#define kVLCSettingOpenAppForPlaybackDefaultValue @YES
#define kVLCSettingShowThumbnails @"ShowThumbnails"
#define kVLCSettingShowThumbnailsDefaultValue @YES
#define kVLCSettingShowArtworks @"ShowArtworks"
#define kVLCSettingShowArtworksDefaultValue @YES
#define kVLCSettingBackupMediaLibrary @"BackupMediaLibrary"
#define kVLCSettingBackupMediaLibraryDefaultValue @NO

#define kVLCForceSMBV1 @"smb-force-v1"

#define kVLCSettingsMediaLibraryVideoGroupPrefixLength @"VideoGroupPrefixLength"
#define kVLCSettingsMediaLibraryVideoGroupPrefixLengthDefaultValue @"6"

#define kVLCShowRemainingTime @"show-remaining-time"
#define kVLCRecentURLs @"recent-urls"
#define kVLCRecentURLTitles @"recent-url-titles"
#define kVLCPrivateWebStreaming @"private-streaming"
#define kVLChttpScanSubtitle @"http-scan-subtitle"
#define kVLCHTTPUploadDirectory @"Upload"

#define kSupportedFileExtensions @"\\.(3g2|3gp|3gp2|3gpp|amv|asf|avi|bik|bin|crf|divx|drc|dv|evo|f4v|flv|gvi|gxf|iso|m1v|m2v|m2t|m2ts|m4v|mkv|mov|mp2|mp2v|mp4|mp4v|mpe|mpeg|mpeg1|mpeg2|mpeg4|mpg|mpv2|mts|mtv|mxf|mxg|nsv|nuv|ogg|ogm|ogv|ogx|ps|rec|rm|rmvb|rpl|thp|tod|ts|tts|txd|vlc|vob|vro|webm|wm|wmv|wtv|xesc)$"
#define kSupportedSubtitleFileExtensions @"\\.(cdg|idx|srt|sub|utf|ass|ssa|aqt|jss|psb|rt|smi|txt|smil|stl|usf|dks|pjs|mpl2|mks|vtt|ttml|dfxp)$"
#define kSupportedAudioFileExtensions @"\\.(3ga|669|a52|aac|ac3|adt|adts|aif|aifc|aiff|amb|amr|aob|ape|au|awb|caf|dts|flac|it|kar|m4a|m4b|m4p|m5p|mid|mka|mlp|mod|mpa|mp1|mp2|mp3|mpc|mpga|mus|oga|ogg|oma|opus|qcp|ra|rmi|s3m|sid|spx|tak|thd|tta|voc|vqf|w64|wav|wma|wv|xa|xm)$"
#define kSupportedPlaylistFileExtensions @"\\.(asx|b4s|cue|ifo|m3u|m3u8|pls|ram|rar|sdp|vlc|xspf|wax|wvx|zip|conf)$"

#define kSupportedProtocolSchemes @"(rtsp|mms|mmsh|udp|rtp|rtmp|sftp|ftp|smb)$"

#define kVLCDarwinNotificationNowPlayingInfoUpdate @"org.videolan.ios-app.nowPlayingInfoUpdate"

#if TARGET_IPHONE_SIMULATOR
#define WifiInterfaceName @"en1"
#else
#define WifiInterfaceName @"en0"
#endif

#define kVLCMigratedToUbiquitousStoredServerList @"kVLCMigratedToUbiquitousStoredServerList"
#define kVLCStoredServerList @"kVLCStoredServerList"
#define kVLCStoreDropboxCredentials @"kVLCStoreDropboxCredentials"
#define kVLCStoreOneDriveCredentials @"kVLCStoreOneDriveCredentials"
#define kVLCStoreBoxCredentials @"kVLCStoreBoxCredentials"
#define kVLCStoreGDriveCredentials @"kVLCStoreGDriveCredentials"

#define kVLCUserActivityPlaying @"org.videolan.vlc-ios.playing"

#define kVLCApplicationShortcutLocalVideo @"ApplicationShortcutLocalVideo"
#define kVLCApplicationShortcutLocalAudio @"ApplicationShortcutLocalAudio"
#define kVLCApplicationShortcutNetwork @"ApplicationShortcutNetwork"
#define kVLCApplicationShortcutPlaylist @"ApplicationShortcutPlaylist"

#define kVLCWifiAuthentificationMaxAttempts 5
#define kVLCWifiAuthentificationSuccess 0
#define kVLCWifiAuthentificationFailure 1
#define kVLCWifiAuthentificationBanned 2

/* LEGACY KEYS, DO NOT USE IN NEW CODE */
#define kVLCFTPServer @"ftp-server"
#define kVLCFTPLogin @"ftp-login"
#define kVLCFTPPassword @"ftp-pass"
#define kVLCPLEXServer @"plex-server"
#define kVLCPLEXPort @"plex-port"
