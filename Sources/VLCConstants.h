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

#define kVLCApplicationGroupIdentifier @"group.org.videolan.vlc-ios"

#define kVLCSettingPasscodeKey @"Passcode"
#define kVLCSettingPasscodeOnKey @"PasscodeProtection"
#define kVLCSettingPasscodeAllowTouchID @"AllowTouchID"
#define kVLCSettingContinueAudioInBackgroundKey @"BackgroundAudioPlayback"
#define kVLCSettingStretchAudio @"audio-time-stretch"
#define kVLCSettingStretchAudioOnValue @"1"
#define kVLCSettingStretchAudioOffValue @"0"
#define kVLCSettingTextEncoding @"subsdec-encoding"
#define kVLCSettingTextEncodingDefaultValue @"Windows-1252"
#define kVLCSettingSkipLoopFilter @"avcodec-skiploopfilter"
#define kVLCSettingSkipLoopFilterNone @(0)
#define kVLCSettingSkipLoopFilterNonRef @(1)
#define kVLCSettingSkipLoopFilterNonKey @(3)
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
#define kVLCSettingEqualizerProfileDefaultValue @(0)
#define kVLCSettingPlaybackForwardSkipLength @"playback-forward-skip-length"
#define kVLCSettingPlaybackForwardSkipLengthDefaultValue @(60)
#define kVLCSettingPlaybackBackwardSkipLength @"playback-forward-skip-length"
#define kVLCSettingPlaybackBackwardSkipLengthDefaultValue @(60)
#define kVLCSettingOpenAppForPlayback @"open-app-for-playback"
#define kVLCSettingOpenAppForPlaybackDefaultValue @YES

#define kVLCShowRemainingTime @"show-remaining-time"
#define kVLCRecentURLs @"recent-urls"
#define kVLCPrivateWebStreaming @"private-streaming"
#define kVLChttpScanSubtitle @"http-scan-subtitle"

#define kSupportedFileExtensions @"\\.(3gp|3gp|3gp2|3gpp|amv|asf|avi|axv|divx|dv|flv|f4v|gvi|gxf|m1v|m2p|m2t|m2ts|m2v|m4v|mks|mkv|moov|mov|mp2v|mp4|mpeg|mpeg1|mpeg2|mpeg4|mpg|mpv|mt2s|mts|mxf|mxg|nsv|nuv|oga|ogg|ogm|ogv|ogx|spx|ps|qt|rec|rm|rmvb|tod|ts|tts|vlc|vob|vro|webm|wm|wmv|wtv|xesc)$"
#define kSupportedSubtitleFileExtensions @"\\.(srt|sub|cdg|idx|utf|ass|ssa|aqt|jss|psb|rt|smi|txt|smil)$"
#define kSupportedAudioFileExtensions @"\\.(aac|aiff|aif|amr|aob|ape|axa|caf|flac|it|m2a|m4a|m4b|mka|mlp|mod|mp1|mp2|mp3|mpa|mpc|mpga|oga|ogg|oma|opus|rmi|s3m|spx|tta|voc|vqf|wav|w64|wma|wv|xa|xm)$"

#define kBlobHash @"521923d214b9ae628da7987cf621e94c4afdd726"

#define kVLCDarwinNotificationNowPlayingInfoUpdate @"org.videolan.ios-app.nowPlayingInfoUpdate"

#define kVLCMigratedToUbiquitousStoredServerList @"kVLCMigratedToUbiquitousStoredServerList"
#define kVLCStoredServerList @"kVLCStoredServerList"
#define kVLCStoreDropboxCredentials @"kVLCStoreDropboxCredentials"
#define kVLCStoreOneDriveCredentials @"kVLCStoreOneDriveCredentials"
#define kVLCStoreBoxCredentials @"kVLCStoreBoxCredentials"
#define kVLCStoreGDriveCredentials @"kVLCStoreGDriveCredentials"

#define kVLCUserActivityPlaying @"org.videolan.vlc-ios.playing"
#define kVLCUserActivityLibrarySelection @"org.videolan.vlc-ios.libraryselection"
#define kVLCUserActivityLibraryMode @"org.videolan.vlc-ios.librarymode"

/* LEGACY KEYS, DO NOT USE IN NEW CODE */
#define kVLCFTPServer @"ftp-server"
#define kVLCFTPLogin @"ftp-login"
#define kVLCFTPPassword @"ftp-pass"
#define kVLCPLEXServer @"plex-server"
#define kVLCPLEXPort @"plex-port"
