/*****************************************************************************
 * VLCTVConstants.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2023 VideoLAN. All rights reserved.
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

#define kSupportedProtocolSchemes @"(rtsp|mms|mmsh|udp|rtp|rtmp|sftp|ftp|smb)$"

#define kVLCThemeDidChangeNotification @"themeDidChangeNotfication"
#define kVLCSettingPlaybackSpeedDefaultValue @"playback-speed"
#define kVLCSettingNetworkCaching @"network-caching"
#define kVLCSettingNetworkCachingDefaultValue @(999)
#define kVLCSettingNetworkRTSPTCP @"rtsp-tcp"
#define kVLCSettingNetworkRTSPHTTP @"rtsp-http"
#define kVLCSaveDebugLogs @"kVLCSaveDebugLogs"
#define kVLCSettingNetworkSatIPChannelList @"satip-channelist"
#define kVLCSettingNetworkSatIPChannelListCustom @"CustomList"
#define kVLCSettingNetworkSatIPChannelListUrl @"satip-channellist-url"
#define kVLCSettingSkipLoopFilter @"avcodec-skiploopfilter"
#define kVLCSettingSkipLoopFilterNone @"0"
#define kVLCSettingSkipLoopFilterNonRef @"1"
#define kVLCSettingSkipLoopFilterNonKey @"3"
#define kVLCSettingDeinterlace @"deinterlace"
#define kVLCSettingDeinterlaceDefaultValue @"-1"
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
#define kVLCSettingPlaybackLockscreenSkip @"playback-lockscreen-skip"
#define kVLCSettingPlaybackRemoteControlSkip @"playback-remote-control-skip"
#define kVLCSettingSaveHTTPUploadServerStatus @"isHTTPServerOn"
#define kVLCAutomaticallyPlayNextItem @"AutomaticallyPlayNextItem"
#define kVLCPlayerUIShouldHide @"PlayerUIShouldHide"
#define KVLCContinuePlaybackWhereLeftOff @"continuemediaPlayback"
#define kVLCSettingShowThumbnails @"ShowThumbnails"
#define kVLCSettingShowThumbnailsDefaultValue @YES
#define kVLCSettingShowArtworks @"ShowArtworks"
#define kVLCSettingShowArtworksDefaultValue @YES
#define kVLCSettingDownloadArtwork @"download-artwork"
#define kVLCSettingBackupMediaLibrary @"BackupMediaLibrary"
#define kVLCSettingBackupMediaLibraryDefaultValue @NO
#define kVLCSettingDisableSubtitles @"kVLCSettingDisableSubtitles"
#define kVLCSettingPlayerControlDuration @"kVLCSettingPlayerControlDuration"
#define kVLCSettingPlayerControlDurationDefaultValue @(4)

#define kVLCLastPlayedMediaIdentifier @"LastPlayedMediaIdentifier"

#define kVLCPlayerOpenInMiniPlayer @"OpenInMiniPlayer"
#define kVLCPlayerShouldRememberState @"PlayerShouldRememberState"
#define kVLCPlayerIsShuffleEnabled @"PlayerIsShuffleEnabled"
#define kVLCPlayerIsShuffleEnabledDefaultValue @NO
#define kVLCPlayerIsRepeatEnabled @"PlayerIsRepeatEnabled"
#define kVLCPlayerIsRepeatEnabledDefaultValue @(0)

#define kVLCSettingLastUsedSubtitlesSearchLanguage @"kVLCSettingLastUsedSubtitlesSearchLanguage"
#define kVLCSettingWiFiSharingIPv6 @"wifi-sharing-ipv6"
#define kVLCSettingWiFiSharingIPv6DefaultValue @(NO)
#define kVLCSettingPlayUploadsWhileReceiving @"PlayUploadsWhileReceiving"
#define kVLCSettingPlayUploadsWhileReceivingDefaultValue @(YES)

#define kVLCfortvOSMovieDBKey @""

#define kVLCStoredServerList @"kVLCStoredServerList"

#define kVLCHTTPUploadDirectory @"Upload"
#define kVLCHTTPUploadInFlightDirectory @"In-Flight"

#define kVLCSettingCastingAudioPassthrough @"sout-chromecast-audio-passthrough"
#define kVLCSettingCastingConversionQuality @"sout-chromecast-conversion-quality"

#define kVLCForceSMBV1 @"smb-force-v1"

#define kVLCSettingsSubtitlesOffsetDelay @"kVLCSettingsSubtitlesOffsetDelay"
#define kVLCSettingsAudioOffsetDelay @"kVLCSettingsAudioOffsetDelay"
#define kVLCSettingsOffsetDefaultValue @(50)

#define kVLCSettingMediaLibraryRescan @"kVLCSettingMediaLibraryRescan"
#define kVLCSettingReset @"kVLCSettingReset"
