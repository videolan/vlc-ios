/*****************************************************************************
 * VLCConstants.h
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

#define kVLCSettingPasscodeOnKey @"PasscodeProtection"
#define kVLCSettingPasscodeAllowTouchID @"AllowTouchID"
#define kVLCSettingPasscodeAllowFaceID @"AllowFaceID"
#define kVLCSettingHideLibraryInFilesApp @"HideLibraryInFilesApp"
#define kVLCThemeDidChangeNotification @"themeDidChangeNotfication"
#define kVLCSettingAppTheme @"darkMode"
#define kVLCSettingAppThemeBright 0
#define kVLCSettingAppThemeDark 1
#define kVLCSettingAppThemeSystem 2
#define kVLCSettingAppThemeBlack @"blackTheme"
#define kVLCOptimizeItemNamesForDisplay @"MLDecrapifyTitles"
#define kVLCSettingAbout @"about"
#define kVLCAutomaticallyPlayNextItem @"AutomaticallyPlayNextItem"
#define kVLCSettingEnableMediaCellTextScrolling @"EnableMediaCellTextScrolling"
#define kVLCSettingContinueAudioInBackgroundKey @"BackgroundAudioPlayback"
#define kVLCSettingStretchAudio @"audio-time-stretch"
#define kVLCSettingDefaultPreampLevel @"pre-amp-level"
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
#define kVLCSubtitlesCacheFolderName @"cached-subtitles"
#define kVLCSettingDeinterlace @"deinterlace"
#define kVLCSettingDeinterlaceDefaultValue @(-1)
#define kVLCSettingHardwareDecoding @"codec"
#define kVLCSettingHardwareDecodingDefault @""
#define kVLCSettingNetworkCaching @"network-caching"
#define kVLCSettingNetworkCachingDefaultValue @(999)
#define kVLCSettingNetworkRTSPTCP @"rtsp-tcp"
#define kVLCSaveDebugLogs @"kVLCSaveDebugLogs"
#define kVLCSettingNetworkSatIPChannelList @"satip-channelist"
#define kVLCSettingNetworkSatIPChannelListCustom @"CustomList"
#define kVLCSettingNetworkSatIPChannelListUrl @"satip-channellist-url"
#define kVLCSettingsDecrapifyTitles @"MLDecrapifyTitles"
#define kVLCSettingVolumeGesture @"EnableVolumeGesture"
#define kVLCSettingPlayPauseGesture @"EnablePlayPauseGesture"
#define kVLCSettingBrightnessGesture @"EnableBrightnessGesture"
#define kVLCSettingSeekGesture @"EnableSeekGesture"
#define kVLCSettingCloseGesture @"EnableCloseGesture"
#define kVLCSettingVideoFullscreenPlayback @"AlwaysUseFullscreenForVideo"
#define kVLCSettingContinuePlayback @"ContinuePlayback"
#define kVLCSettingContinueAudioPlayback @"ContinueAudioPlayback"
#define kVLCSettingPlaybackSpeedDefaultValue @"playback-speed"
#define kVLCSettingWiFiSharingIPv6 @"wifi-sharing-ipv6"
#define kVLCSettingWiFiSharingIPv6DefaultValue @(NO)
#define kVLCSettingEqualizerProfile @"EqualizerProfile"
#define kVLCSettingEqualizerProfileDisabled @"EqualizerDisabled"
#define kVLCSettingEqualizerProfileDefaultValue @(0)
#define kVLCSettingPlaybackForwardBackwardEqual @"playback-forward-backward-equal"
#define kVLCSettingPlaybackTapSwipeEqual @"playback-tap-swipe-equal"
#define kVLCSettingPlaybackForwardSkipLength @"playback-forward-skip-length"
#define kVLCSettingPlaybackForwardSkipLengthDefaultValue @(10)
#define kVLCSettingPlaybackBackwardSkipLength @"playback-backward-skip-length"
#define kVLCSettingPlaybackBackwardSkipLengthDefaultValue @(10)
#define kVLCSettingPlaybackForwardSkipLengthSwipe @"playback-forward-skip-length-swipe"
#define kVLCSettingPlaybackForwardSkipLengthSwipeDefaultValue @(10)
#define kVLCSettingPlaybackBackwardSkipLengthSwipe @"playback-backward-skip-length-swipe"
#define kVLCSettingPlaybackBackwardSkipLengthSwipeDefaultValue @(10)
#define kVLCSettingOpenAppForPlayback @"open-app-for-playback"
#define kVLCSettingOpenAppForPlaybackDefaultValue @YES
#define kVLCSettingShowThumbnails @"ShowThumbnails"
#define kVLCSettingShowThumbnailsDefaultValue @YES
#define kVLCSettingShowArtworks @"ShowArtworks"
#define kVLCSettingShowArtworksDefaultValue @YES
#define kVLCSettingsDisableGrouping @"MLDisableGrouping"
#define kVLCkVLCSettingsDisableGroupingDefaultValue @NO
#define kVLCSettingCastingAudioPassthrough @"sout-chromecast-audio-passthrough"
#define kVLCSettingCastingConversionQuality @"sout-chromecast-conversion-quality"
#define kVLCSettingBackupMediaLibrary @"BackupMediaLibrary"
#define kVLCSettingBackupMediaLibraryDefaultValue @NO
#define kVLCSettingLastUsedSubtitlesSearchLanguage @"kVLCSettingLastUsedSubtitlesSearchLanguage"

#define kVLCForceSMBV1 @"smb-force-v1"

#define kVLCRecentFavoriteURL @"recent-favorite-url"
#define kVLCFavoriteGroupAlias @"favorite-group-alias"
#define kVLCNetworkServerFavoritesUpdated @"add-to-favorite"
#define kVLCShowRemainingTime @"show-remaining-time"
#define kVLCRecentURLs @"recent-urls"
#define kVLCRecentURLTitles @"recent-url-titles"
#define kVLCPrivateWebStreaming @"private-streaming"
#define kVLChttpScanSubtitle @"http-scan-subtitle"
#define kVLCHTTPUploadDirectory @"Upload"
#define kVLCAudioLibraryGridLayout @"kVLCAudioLibraryGridLayout"
#define kVLCAudioLibraryHideFeatArtists @"kVLCAudioLibraryHideFeatArtists"
#define kVLCAudioLibraryHideTrackNumbers @"kVLCAudioLibraryHideTrackNumbers"
#define kVLCVideoLibraryGridLayout @"kVLCVideoLibraryGridLayout"

#define kVLCPlayerShouldRememberState @"PlayerShouldRememberState"
#define kVLCPlayerShouldRememberBrightness @"PlayerShouldRememberBrightness"
#define KVLCPlayerBrightness @"playerbrightness"
#define kVLCPlayerIsShuffleEnabled @"PlayerIsShuffleEnabled"
#define kVLCPlayerIsShuffleEnabledDefaultValue @NO
#define kVLCPlayerIsRepeatEnabled @"PlayerIsRepeatEnabled"
#define kVLCPlayerIsRepeatEnabledDefaultValue @(0)
#define kVLCPlayerShowPlaybackSpeedShortcut @"kVLCPlayerShowPlaybackSpeedShortcut"

#define kSupportedFileExtensions @"\\.(669|3g2|3gp|3gp2|3gpp|amv|asf|avi|bik|bin|crf|divx|drc|dv|evo|f4v|far|flv|gvi|gxf|hevc|iso|it|m1v|m2v|m2t|m2ts|m4v|mkv|mov|mp2|mp2v|mp4|mp4v|mpe|mpeg|mpeg1|mpeg2|mpeg4|mpg|mpv2|mtm|mts|mtv|mxf|mxg|nsv|nuv|ogg|ogm|ogv|ogx|ps|rec|rm|rmvb|rpl|s3m|thp|tod|ts|tts|txd|vlc|vob|vro|webm|wm|wmv|wtv|xesc|xm)$"
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

#define kVLCSortDefault @"SortDefault"
#define kVLCSortDescendingDefault @"SortDescendingDefault"
#define kVLCHasLaunchedBefore @"hasLaunchedBefore"

#define kVLCTabBarIndex @"TabBarIndex"

#define kVLCGroupLayout @"kVLCGroupLayout"

#define kVLCEqualizerSnapBands @"EqualizerSnapBands"

/* LEGACY KEYS, DO NOT USE IN NEW CODE */
#define kVLCFTPServer @"ftp-server"
#define kVLCFTPLogin @"ftp-login"
#define kVLCFTPPassword @"ftp-pass"
#define kVLCPLEXServer @"plex-server"
#define kVLCPLEXPort @"plex-port"
