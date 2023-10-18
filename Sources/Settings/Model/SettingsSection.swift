/*****************************************************************************
* SettingsSection.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
*
* Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import Foundation
import LocalAuthentication

enum SettingsSection: Int, CaseIterable, CustomStringConvertible {
    case main
    case generic
    case privacy
    case gestureControl
    case video
    case subtitles
    case audio
    case casting
    case mediaLibrary
    case network
    case lab

    var description: String {
        switch self {
        case .main:
            return ""
        case .generic:
            return "SETTINGS_GENERIC_TITLE"
        case .privacy:
            return "SETTINGS_PRIVACY_TITLE"
        case .gestureControl:
            return "SETTINGS_GESTURES"
        case .video:
            return "SETTINGS_VIDEO_TITLE"
        case .subtitles:
            return "SETTINGS_SUBTITLES_TITLE"
        case .audio:
            return "SETTINGS_AUDIO_TITLE"
        case .casting:
            return "SETTINGS_CASTING"
        case .mediaLibrary:
            return "SETTINGS_MEDIA_LIBRARY"
        case .network:
            return "SETTINGS_NETWORK"
        case .lab:
            return "SETTINGS_LAB"
        }
    }
}

enum MainOptions: Int, CaseIterable, SectionType {
    case privacy
    case appearance

    var description: String {
        switch self {
        case .privacy:
            return "SETTINGS_PRIVACY_TITLE"
        case .appearance:
            return "SETTINGS_DARKTHEME"
        }
    }

    var containsSwitch: Bool {
        switch self {
        case .privacy:
            return false
        case .appearance:
            return false
        }
    }

    var containsInfobutton: Bool { return false }

    var subtitle: String? {
        switch self {
        case .privacy:
            return "SETTINGS_PRIVACY_SUBTITLE"
        case .appearance:
            return "SETTINGS_THEME_SYSTEM"
        }
    }

    var preferenceKey: String? {
        switch self {
        case .privacy:
            return kVLCSettingPasscodeOnKey
        case .appearance:
            return kVLCSettingAppTheme
        }
    }
}

enum GenericOptions: Int, CaseIterable, SectionType {
    case defaultPlaybackSpeed
    case continueAudioPlayback
    case playVideoInFullScreen
    case continueVideoPlayback
    case automaticallyPlayNextItem
    case enableTextScrollingInMediaList
    case rememberPlayerState

    var description: String {
        switch self {
        case .defaultPlaybackSpeed:
            return "SETTINGS_PLAYBACK_SPEED_DEFAULT"
        case .continueAudioPlayback:
            return "SETTINGS_CONTINUE_AUDIO_PLAYBACK"
        case .playVideoInFullScreen:
            return "SETTINGS_VIDEO_FULLSCREEN"
        case .continueVideoPlayback:
            return "SETTINGS_CONTINUE_VIDEO_PLAYBACK"
        case .automaticallyPlayNextItem:
            return "SETTINGS_NETWORK_PLAY_ALL"
        case .enableTextScrollingInMediaList:
            return "SETTINGS_ENABLE_MEDIA_CELL_TEXT_SCROLLING"
        case .rememberPlayerState:
            return "SETTINGS_REMEMBER_PLAYER_STATE"
        }
    }

    var containsSwitch: Bool {
        switch self {
        case .defaultPlaybackSpeed:
            return false
        case .continueAudioPlayback:
            return false
        case .playVideoInFullScreen:
            return true
        case .continueVideoPlayback:
            return false
        case .automaticallyPlayNextItem:
            return true
        case .enableTextScrollingInMediaList:
            return true
        case .rememberPlayerState:
            return true
        }
    }

    var containsInfobutton: Bool { return false }

    var subtitle: String? {
        switch self {
        case .defaultPlaybackSpeed:
            return "1.00x"
        case .continueAudioPlayback:
            return "SETTINGS_CONTINUE_PLAYBACK_ALWAYS"
        case .playVideoInFullScreen:
            return nil
        case .continueVideoPlayback:
            return "SETTINGS_CONTINUE_PLAYBACK_ALWAYS"
        case .automaticallyPlayNextItem:
            return nil
        case .enableTextScrollingInMediaList:
            return nil
        case .rememberPlayerState:
            return nil
        }
    }

    var preferenceKey: String? {
        switch self {
        case .defaultPlaybackSpeed:
            return kVLCSettingPlaybackSpeedDefaultValue
        case .continueAudioPlayback:
            return kVLCSettingContinueAudioPlayback
        case .playVideoInFullScreen:
            return kVLCSettingVideoFullscreenPlayback
        case .continueVideoPlayback:
            return kVLCSettingContinuePlayback
        case .automaticallyPlayNextItem:
            return kVLCAutomaticallyPlayNextItem
        case .enableTextScrollingInMediaList:
            return kVLCSettingEnableMediaCellTextScrolling
        case .rememberPlayerState:
            return kVLCPlayerShouldRememberState
        }
    }
}

enum PrivacyOptions: Int, CaseIterable, SectionType {
    case passcodeLock
    case enableBiometrics
    case hideLibraryInFilesApp

    var description: String {
        switch self {
        case .passcodeLock:
            return "SETTINGS_PASSCODE_LOCK"
        case .enableBiometrics:
            let authContext = LAContext()
            if #available(iOS 11.0.1, *) {
                let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
                switch authContext.biometryType {
                case .none:
                    return ""
                case .touchID:
                    return "SETTINGS_PASSCODE_LOCK_ALLOWTOUCHID"
                case .faceID:
                    return "SETTINGS_PASSCODE_LOCK_ALLOWFACEID"
                @unknown default:
                    return ""
                }
            }
            return ""
        case .hideLibraryInFilesApp:
            return "SETTINGS_HIDE_LIBRARY_IN_FILES_APP"
        }
    }

    var containsSwitch: Bool {
        switch self {
        case .passcodeLock:
            return true
        case .enableBiometrics:
            return true
        case .hideLibraryInFilesApp:
            return true
        }
    }

    var containsInfobutton: Bool { return false }

    var subtitle: String? {
        switch self {
        case .passcodeLock:
            return "SETTINGS_PASSCODE_LOCK_SUBTITLE"
        case .enableBiometrics:
            return nil
        case .hideLibraryInFilesApp:
            return "SETTINGS_HIDE_LIBRARY_IN_FILES_APP_SUBTITLE"
        }
    }

    var preferenceKey: String? {
        switch self {
        case .passcodeLock:
            return kVLCSettingPasscodeOnKey
        case .enableBiometrics:
            let authContext = LAContext()
            if #available(iOS 11.0.1, *) {
                let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
                switch authContext.biometryType {
                case .none:
                    return nil
                case .touchID:
                    return kVLCSettingPasscodeAllowTouchID
                case .faceID:
                    return kVLCSettingPasscodeAllowFaceID
                @unknown default:
                    return nil
                }
            }
            return nil
        case .hideLibraryInFilesApp:
            return kVLCSettingHideLibraryInFilesApp
        }
    }
}

enum PlaybackControlOptions: Int, CaseIterable, SectionType {
    case swipeUpDownForVolume
    case twoFingerTap
    case swipeUpDownForBrightness
    case swipeRightLeftToSeek
    case pinchToClose
    case forwardBackwardEqual
    case tapSwipeEqual
    case forwardSkipLength
    case backwardSkipLength
    case forwardSkipLengthSwipe
    case backwardSkipLengthSwipe

    var containsInfobutton: Bool { return false }

    var containsSwitch: Bool {
        switch self {
        case .swipeUpDownForVolume:
            return true
        case .twoFingerTap:
            return true
        case .swipeUpDownForBrightness:
            return true
        case .swipeRightLeftToSeek:
            return true
        case .pinchToClose:
            return true
        case .forwardBackwardEqual:
            return true
        case .tapSwipeEqual:
            return true
        case .forwardSkipLength:
            return false
        case .backwardSkipLength:
            return false
        case .forwardSkipLengthSwipe:
            return false
        case .backwardSkipLengthSwipe:
            return false
        }
    }

    var description: String {
        let forwardBackwardEqual = UserDefaults.standard.bool(forKey: kVLCSettingPlaybackForwardBackwardEqual)
        let tapSwipeEqual = UserDefaults.standard.bool(forKey: kVLCSettingPlaybackTapSwipeEqual)
        switch self {
        case .swipeUpDownForVolume:
            return "SETTINGS_GESTURES_VOLUME"
        case .twoFingerTap:
            return "SETTINGS_GESTURES_PLAYPAUSE"
        case .swipeUpDownForBrightness:
            return "SETTINGS_GESTURES_BRIGHTNESS"
        case .swipeRightLeftToSeek:
            return "SETTINGS_GESTURES_SEEK"
        case .pinchToClose:
            return "SETTINGS_GESTURES_CLOSE"
        case .forwardBackwardEqual:
            return "SETTINGS_GESTURES_FORWARD_BACKWARD_EQUAL"
        case .tapSwipeEqual:
            return "SETTINGS_GESTURES_TAP_SWIPE_EQUAL"
        case .forwardSkipLength:
            if forwardBackwardEqual && tapSwipeEqual {
                return "SETTINGS_PLAYBACK_SKIP_GENERIC"
            } else if forwardBackwardEqual && !tapSwipeEqual {
                return "SETTINGS_PLAYBACK_SKIP_TAP"
            } else if !forwardBackwardEqual && !tapSwipeEqual {
                return "SETTINGS_PLAYBACK_SKIP_FORWARD_TAP"
            }
            return  "SETTINGS_PLAYBACK_SKIP_FORWARD"
        case .backwardSkipLength:
            if tapSwipeEqual {
                return "SETTINGS_PLAYBACK_SKIP_BACKWARD"
            }
            return "SETTINGS_PLAYBACK_SKIP_BACKWARD_TAP"
        case .forwardSkipLengthSwipe:
            if forwardBackwardEqual {
                return "SETTINGS_PLAYBACK_SKIP_SWIPE"
            }
            return "SETTINGS_PLAYBACK_SKIP_FORWARD_SWIPE"
        case .backwardSkipLengthSwipe:
            return "SETTINGS_PLAYBACK_SKIP_BACKWARD_SWIPE"
        }
    }

    var subtitle: String? { return nil }

    var preferenceKey: String? {
        switch self {
        case .swipeUpDownForVolume:
            return kVLCSettingVolumeGesture
        case .twoFingerTap:
            return kVLCSettingPlayPauseGesture
        case .swipeUpDownForBrightness:
            return kVLCSettingBrightnessGesture
        case .swipeRightLeftToSeek:
            return kVLCSettingSeekGesture
        case .pinchToClose:
            return kVLCSettingCloseGesture
        case .forwardBackwardEqual:
            return kVLCSettingPlaybackForwardBackwardEqual
        case .tapSwipeEqual:
            return kVLCSettingPlaybackTapSwipeEqual
        case .forwardSkipLength:
            return kVLCSettingPlaybackForwardSkipLength
        case .backwardSkipLength:
            return kVLCSettingPlaybackBackwardSkipLength
        case .forwardSkipLengthSwipe:
            return kVLCSettingPlaybackForwardSkipLengthSwipe
        case .backwardSkipLengthSwipe:
            return kVLCSettingPlaybackBackwardSkipLengthSwipe
        }
    }
}

enum VideoOptions: Int, CaseIterable, SectionType {
    case deBlockingFilter
    case deInterlace
    case hardwareDecoding
    case rememberPlayerBrightness

    var description: String {
        switch self {
        case .deBlockingFilter:
            return "SETTINGS_SKIP_LOOP_FILTER"
        case .deInterlace:
            return "SETTINGS_DEINTERLACE"
        case .hardwareDecoding:
            return "SETTINGS_HWDECODING"
        case .rememberPlayerBrightness:
            return "SETTINGS_REMEMBER_PLAYER_BRIGHTNESS"
        }
    }

    var containsSwitch: Bool {
        switch self {
        case .deBlockingFilter:
            return false
        case .deInterlace:
            return false
        case .hardwareDecoding:
            return false
        case .rememberPlayerBrightness:
            return true
        }
    }

    var containsInfobutton: Bool { return true }

    var subtitle: String? {
        switch self {
        case .deBlockingFilter:
            return "SETTINGS_SKIP_LOOP_FILTER_NONREF"
        case .deInterlace:
            return "SETTINGS_DEINTERLACE_OFF"
        case .hardwareDecoding:
            return "SETTINGS_HWDECODING_ON"
        case .rememberPlayerBrightness:
            return nil
        }
    }

    var preferenceKey: String? {
        switch self {
        case .deBlockingFilter:
            return kVLCSettingSkipLoopFilter
        case .deInterlace:
            return kVLCSettingDeinterlace
        case .hardwareDecoding:
            return kVLCSettingHardwareDecoding
        case .rememberPlayerBrightness:
            return kVLCPlayerShouldRememberBrightness
        }
    }
}

enum SubtitlesOptions: Int, CaseIterable, SectionType {
    case font
    case relativeFontSize
    case useBoldFont
    case fontColor
    case textEncoding

    var description: String {
        switch self {
        case .font:
            return "SETTINGS_SUBTITLES_FONT"
        case .relativeFontSize:
            return "SETTINGS_SUBTITLES_FONTSIZE"
        case .useBoldFont:
            return "SETTINGS_SUBTITLES_BOLDFONT"
        case .fontColor:
            return "SETTINGS_SUBTITLES_FONTCOLOR"
        case .textEncoding:
            return "SETTINGS_SUBTITLES_TEXT_ENCODING"
        }
    }

    var containsSwitch: Bool {
        switch self {
        case .font:
            return false
        case .relativeFontSize:
            return false
        case .useBoldFont:
            return true
        case .fontColor:
            return false
        case .textEncoding:
            return false
        }
    }

    var subtitle: String? {
        switch self {
        case .font:
            return "Arial"
        case .relativeFontSize:
            return "SETTINGS_SUBTITLES_FONTSIZE_NORMAL"
        case .useBoldFont:
            return nil
        case .fontColor:
            return "SETTINGS_SUBTITLES_FONTCOLOR_BLACK"
        case .textEncoding:
            return "Western European (Windows-1252)"
        }
    }

    var preferenceKey: String? {
        switch self {
        case .font:
            return kVLCSettingSubtitlesFont
        case .relativeFontSize:
            return kVLCSettingSubtitlesFontSize
        case .useBoldFont:
            return kVLCSettingSubtitlesBoldFont
        case .fontColor:
            return kVLCSettingSubtitlesFontColor
        case .textEncoding:
            return kVLCSettingTextEncoding
        }
    }

    var containsInfobutton: Bool { return false }
}

enum CastingOptions: Int, CaseIterable, SectionType {
    case audioPassThrough
    case conversionQuality

    var description: String {
        switch self {
        case .audioPassThrough:
            return "SETTINGS_PTCASTING"
        case .conversionQuality:
            return "SETTINGS_CASTING_CONVERSION_QUALITY"
        }
    }

    var containsSwitch: Bool {
        switch self {
        case .audioPassThrough:
            return true
        case .conversionQuality:
            return false
        }
    }

    var preferenceKey: String? {
        switch self {
        case .audioPassThrough:
            return kVLCSettingCastingAudioPassthrough
        case .conversionQuality:
            return kVLCSettingCastingConversionQuality
        }
    }

    var subtitle: String? {
        switch self {
        case .audioPassThrough:
            return "SETTINGS_PTCASTINGLONG"
        case .conversionQuality:
            return "SETTINGS_MEDIUM"
        }
    }

    var containsInfobutton: Bool { return false }
}

enum AudioOptions: Int, CaseIterable, SectionType {
    case preampLevel
    case timeStretchingAudio
    case audioPlaybackInBackground

    var description: String {
        switch self {
        case .preampLevel:
            return "SETTINGS_AUDIO_PREAMP_LEVEL"
        case .timeStretchingAudio:
            return "SETTINGS_TIME_STRETCH_AUDIO"
        case .audioPlaybackInBackground:
            return "SETTINGS_BACKGROUND_AUDIO"
        }
    }

    var containsSwitch: Bool {
        switch self {
        case .preampLevel:
            return false
        default:
            return true
        }
    }
    var subtitle: String? {
        switch self {
        case .preampLevel:
            return "6 dB"
        case .timeStretchingAudio:
            return "SETTINGS_TIME_STRETCH_AUDIO_LONG"
        default:
            return nil
        }
    }

    var preferenceKey: String? {
        switch self {
        case .preampLevel:
            return kVLCSettingDefaultPreampLevel
        case .timeStretchingAudio:
            return kVLCSettingStretchAudio
        case .audioPlaybackInBackground:
            return kVLCSettingContinueAudioInBackgroundKey
        }
    }

    var containsInfobutton: Bool { return false }
}

enum MediaLibraryOptions: Int, CaseIterable, SectionType {
    case forceVLCToRescanTheMediaLibrary
    case optimiseItemNamesForDisplay
    case disableGrouping
    case showVideoThumbnails
    case showAudioArtworks
    case includeMediaLibInDeviceBackup

    var description: String {
        switch self {
        case .forceVLCToRescanTheMediaLibrary:
            return "SETTINGS_MEDIA_LIBRARY_RESCAN"
        case .optimiseItemNamesForDisplay:
            return "SETTINGS_DECRAPIFY"
        case .disableGrouping:
            return "SETTINGS_DISABLE_GROUPING"
        case .showVideoThumbnails:
            return "SETTINGS_SHOW_THUMBNAILS"
        case .showAudioArtworks:
            return "SETTINGS_SHOW_ARTWORKS"
        case .includeMediaLibInDeviceBackup:
            return "SETTINGS_BACKUP_MEDIA_LIBRARY"
        }
    }

    var containsSwitch: Bool {
        switch self {
        case .forceVLCToRescanTheMediaLibrary:
            return false
        default:
            return true
        }
    }

    var subtitle: String? { return nil }

    var preferenceKey: String? {
        switch self {
        case .forceVLCToRescanTheMediaLibrary:
            return nil
        case .optimiseItemNamesForDisplay:
            return kVLCSettingsDecrapifyTitles
        case .disableGrouping:
            return kVLCSettingsDisableGrouping
        case .showVideoThumbnails:
            return kVLCSettingShowThumbnails
        case .showAudioArtworks:
            return kVLCSettingShowArtworks
        case .includeMediaLibInDeviceBackup:
            return kVLCSettingBackupMediaLibrary
        }
    }

    var containsInfobutton: Bool { return false }
}

enum NetworkOptions: Int, CaseIterable, SectionType {
    case networkCachingLevel
    case ipv6SupportForWiFiSharing
    case forceSMBv1
    case rtspctp

    var description: String {
        switch self {
        case .networkCachingLevel:
            return "SETTINGS_NETWORK_CACHING_TITLE"
        case .ipv6SupportForWiFiSharing:
            return "SETTINGS_WIFISHARING_IPv6"
        case .forceSMBv1:
            return "SETTINGS_FORCE_SMBV1"
        case .rtspctp:
            return "SETTINGS_RTSP_TCP"
        }
    }

    var containsSwitch: Bool {
        switch self {
        case .networkCachingLevel:
            return false
        case .ipv6SupportForWiFiSharing:
            return true
        case .forceSMBv1:
            return true
        case .rtspctp:
            return true
        }
    }

    var subtitle: String? {
        switch self {
        case .networkCachingLevel:
            return "SETTINGS_NETWORK_CACHING_LEVEL_NORMAL"
        case .ipv6SupportForWiFiSharing:
            return nil
        case .forceSMBv1:
            return "SETTINGS_FORCE_SMBV1_LONG"
        case .rtspctp:
            return nil
        }
    }

    var preferenceKey: String? {
        switch self {
        case .networkCachingLevel:
            return kVLCSettingNetworkCaching
        case .ipv6SupportForWiFiSharing:
            return kVLCSettingWiFiSharingIPv6
        case .forceSMBv1:
            return kVLCForceSMBV1
        case .rtspctp:
            return kVLCSettingNetworkRTSPTCP
        }
    }

    var containsInfobutton: Bool {
        switch self {
        case .networkCachingLevel:
            return true
        case .ipv6SupportForWiFiSharing:
            return false
        case .forceSMBv1:
            return false
        case .rtspctp:
            return false
        }
    }
}

enum Lab: Int, CaseIterable, SectionType {
    case debugLogging
    case exportLibrary

    var description: String {
        switch self {
        case .debugLogging:
            return "SETTINGS_DEBUG_LOG"
        case .exportLibrary:
            return "SETTINGS_EXPORT_LIBRARY"
        }
    }

    var containsSwitch: Bool {
        switch self {
        case .exportLibrary:
            return false
        default:
            return true
        }
    }

    var subtitle: String? { return nil }

    var preferenceKey: String? {
        switch self {
        case .debugLogging:
            return kVLCSaveDebugLogs
        case .exportLibrary:
            return nil
        }
    }

    var containsInfobutton: Bool { return false }
}
