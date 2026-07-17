/*****************************************************************************
 * VLCConstants.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *          Pratik Ray <raypratik365@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#define kVLCSettingPasscodeOnKey @"PasscodeProtection"
#define kVLCSettingPasscodeEnableBiometricAuth @"EnableBiometricAuth"
#define kVLCSettingHideLibraryInFilesApp @"HideLibraryInFilesApp"
#define kVLCSettingParentalControl @"ParentalControl"
#define kVLCThemeDidChangeNotification @"themeDidChangeNotfication"
#define kVLCSettingAppTheme @"darkMode"
#define kVLCSettingAppThemeBright 0
#define kVLCSettingAppThemeDark 1
#define kVLCSettingAppThemeSystem 2
#define kVLCSettingAppThemeBlack @"blackTheme"
#define kVLCOptimizeItemNamesForDisplay @"MLDecrapifyTitles"
#define kVLCSettingAbout @"about"
#define kVLCAutomaticallyPlayNextItem @"AutomaticallyPlayNextItem"
#define kVLCPlaylistPlayNextItem @"PlaylistPlayNextItem"
#define kVLCLastPlayedPlaylist @"LastPlayedPlaylist"
#define kVLCIsCurrentlyPlayingPlaylist @"isPlaylistCurrentlyPlaying"
#define kVLCCurrentPlaylistMediasQueue @"currentPlaylistMediasQueue"
#define kVLCSettingEnableMediaCellTextScrolling @"EnableMediaCellTextScrolling"
#define kVLCSettingContinueAudioInBackgroundKey @"BackgroundAudioPlayback"
#define kVLCSettingStretchAudio @"audio-time-stretch"
#define kVLCSettingDefaultPreampLevel @"pre-amp-level"
#define kVLCSettingTextEncoding @"subsdec-encoding"
#define kVLCSettingTextEncodingDefaultValue @"Windows-1252"
#define kVLCSettingSkipLoopFilter @"avcodec-skiploopfilter"
#define kVLCSettingSkipLoopFilterNone @"0"
#define kVLCSettingSkipLoopFilterNonRef @"1"
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
#define kVLCSettingDeinterlaceDefaultValue @"-1"
#define kVLCSettingHardwareDecoding @"codec"
#define kVLCSettingHardwareDecodingDefault @""
#define kVLCSettingRotationLock @"kVLCSettingRotationLock"
#define kVLCSettingNetworkCaching @"network-caching"
#define kVLCSettingNetworkCachingDefaultValue @(999)
#define kVLCSettingNetworkRTSPTCP @"rtsp-tcp"
#define kVLCSettingNetworkRTSPHTTP @"rtsp-http"
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
#define kVLCSettingSnapshotGesture @"EnableSnapshotGesture"
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
#define kVLCSettingPlaybackLongTouchSpeedUp @"LongTouchSpeedUp"
#define kVLCSettingPlaybackBackwardSkipLengthSwipeDefaultValue @(10)
#define kVLCSettingPlaybackLockscreenSkip @"playback-lockscreen-skip"
#define kVLCSettingPlaybackRemoteControlSkip @"playback-remote-control-skip"
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
#define kVLCResetSettings @"kVLCResetSettings"
#define kVLCSettingAlwaysPlayURLs @"kVLCSettingAlwaysPlayURLs"
#define kVLCSettingDisableSubtitles @"kVLCSettingDisableSubtitles"
#define kVLCSettingPlayerControlDuration @"kVLCSettingPlayerControlDuration"
#define kVLCSettingPlayerControlDurationDefaultValue @(4)
#define kVLCSettingPauseWhenShowingControls @"kVLCSettingPauseWhenShowingControls"
#define kVLCSettingEnableScrollToCurrentlyPlayingMedia @"kVLCSettingEnableScrollToCurrentlyPlayingMedia"

#define kVLCForceSMBV1 @"smb-force-v1"

#define kVLCAudioLibraryGridLayoutALBUMS @"kVLCAudioLibraryGridLayoutALBUMS"
#define kVLCAudioLibraryGridLayoutARTISTS @"kVLCAudioLibraryGridLayoutARTISTS"
#define kVLCAudioLibraryGridLayoutGENRES @"kVLCAudioLibraryGridLayoutGENRES"
#define kVLCVideoLibraryGridLayoutALL_VIDEOS @"kVLCVideoLibraryGridLayoutALL_VIDEOS"
#define kVLCVideoLibraryGridLayoutVIDEO_GROUPS @"kVLCVideoLibraryGridLayoutVIDEO_GROUPS"
#define kVLCVideoLibraryGridLayoutVLCMLMediaGroupCollections @"kVLCVideoLibraryGridLayoutVLCMLMediaGroupCollections"

#define kVLCShowRemainingTime @"show-remaining-time"
#define kVLCRecentURLs @"recent-urls"
#define kVLCRecentURLTitles @"recent-url-titles"
#define kVLCPrivateWebStreaming @"private-streaming"
#define kVLCHTTPUploadDirectory @"Upload"
#define kVLCAudioLibraryGridLayout @"kVLCAudioLibraryGridLayout"
#define kVLCAudioLibraryHideFeatArtists @"kVLCAudioLibraryHideFeatArtists"
#define kVLCAudioLibraryHideTrackNumbers @"kVLCAudioLibraryHideTrackNumbers"
#define kVLCVideoLibraryGridLayout @"kVLCVideoLibraryGridLayout"

#define KVLCFolderViewLayout @"KVLCFolderViewLayout"
#define kVLCLastPlayedMediaIdentifier @"LastPlayedMediaIdentifier"
#define kVLCRestoreLastPlayedMedia @"RestoreLastPlayedMedia"

#define kVLCPlayerOpenInMiniPlayer @"OpenInMiniPlayer"
#define kVLCPlayerShouldRememberState @"PlayerShouldRememberState"
#define kVLCPlayerShouldRememberBrightness @"PlayerShouldRememberBrightness"
#define KVLCPlayerBrightness @"playerbrightness"
#define kVLCPlayerIsShuffleEnabled @"PlayerIsShuffleEnabled"
#define kVLCPlayerIsShuffleEnabledDefaultValue @NO
#define kVLCPlayerIsRepeatEnabled @"PlayerIsRepeatEnabled"
#define kVLCPlayerIsRepeatEnabledDefaultValue @(0)
#define kVLCPlayerShowPlaybackSpeedShortcut @"kVLCPlayerShowPlaybackSpeedShortcut"

#define kVLCCustomProfileEnabled @"kVLCCustomProfileEnabled"
#define kVLCCustomEqualizerProfiles @"kVLCCustomEqualizerProfiles"

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
#define kVLCHasNaggedThisMonth @"kVLCHasNaggedThisMonth"
#define kVLCNumberOfLaunches @"kVLCNumberOfLaunches"
#define kVLCHasActiveSubscription @"kVLCHasActiveSubscription"

#define kVLCTabBarIndex @"TabBarIndex"

#define kVLCGroupLayout @"kVLCGroupLayout"

#define kVLCEqualizerSnapBands @"EqualizerSnapBands"

#define kVLCDonationAnonymousCustomerID @"kVLCDonationAnonymousCustomerID"

/* LEGACY KEYS, DO NOT USE IN NEW CODE */
#define kVLCFTPServer @"ftp-server"
#define kVLCFTPLogin @"ftp-login"
#define kVLCFTPPassword @"ftp-pass"
#define kVLCPLEXServer @"plex-server"
#define kVLCPLEXPort @"plex-port"

#define kVLCCurrentPlayingModel @"CurrentPlayingModel"

#define kVLCDefaultPageSize 500
#define kVLCPrefetchDistance 100

#define kVLCAudioTabIndex @"kVLCAudioTabIndex"

#define kVLCMediaLibrarySyncID @"kVLCMediaLibrarySyncID"
#define kVLCiPhoneMediaID @"kVLCiPhoneMediaID"
#define kVLCiPhoneMediaFileName @"kVLCiPhoneMediaFileName"

#define kVLCiPhoneAlbumID @"kVLCiPhoneAlbumID"
#define kVLCiPhoneAlbumName @"kVLCiPhoneAlbumName"

#define kVLCiPhoneArtistID @"kVLCiPhoneArtistID"
#define kVLCiPhoneArtistName @"kVLCiPhoneArtistName"


#define kVLCWatchMessageType @"kVLCWatchMessageType"

#define kVLCMediaLibraryDBFileName @"medialibrary.db"
#define kVLCSnapshotMediaLibraryDBFileName @"medialibrary-snapshot.db"
