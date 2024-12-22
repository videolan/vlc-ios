/*****************************************************************************
* SettingsSection.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020-2023 VideoLAN. All rights reserved.
*
* Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
*          Soomin Lee < bubu@mikan.io >
*          Edgar Fouillet <vlc # edgar.fouillet.eu>
*          Diogo Simao Marques <dogo@videolabs.io>
*          Felix Paul Kühne <fkuehne # videolan.org>
*          Eshan Singh <eeeshan789@icloud.com>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import Foundation
import LocalAuthentication

// MARK: - SettingsItem
struct SettingsItem: Equatable {
    let title: String
    let subtitle: String?
    let action: Action
    let emphasizedTitle: Bool

    @available(*, deprecated, message: "access from self.action")
    var preferenceKey: String? {
        switch action {
        case .toggle(let preferenceKey):
            return preferenceKey
        case .showActionSheet(_, let preferenceKey, _):
            return preferenceKey
        default:
            return nil
        }
    }

    init(title: String, subtitle: String?, action: Action, emphasizedTitle: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.emphasizedTitle = emphasizedTitle
    }

    enum Action: Equatable {
        case isLoading
        case toggle(preferenceKey: String)
        case showActionSheet(title: String, preferenceKey: String, hasInfo: Bool)
        case donation
        case openPrivacySettings
        case forceRescanAlert
        case exportMediaLibrary
        case displayResetAlert
    }
}

// MARK: - SettingsSection
struct SettingsSection: Equatable {
    let title: String?
    let items: [SettingsItem]

    var isEmpty: Bool {
        items.isEmpty
    }

    static func sections(isLabActivated: Bool, isBackingUp: Bool, isForwardBackwardEqual: Bool, isTapSwipeEqual: Bool) -> [SettingsSection] {
        [
            MainOptions.section(),
            DonationOptions.section(),
            GenericOptions.section(),
            PrivacyOptions.section(),
            GestureControlOptions.section(isForwardBackwardEqual: isForwardBackwardEqual, isTapSwipeEqual: isTapSwipeEqual),
            VideoOptions.section(),
            SubtitlesOptions.section(),
            AudioOptions.section(),
            CastingOptions.section(),
            MediaLibraryOptions.section(isBackingUp: isBackingUp),
            NetworkOptions.section(),
            Lab.section(isLabActivated: isLabActivated),
            Reset.section()
        ].compactMap { $0 }
    }
}

// MARK: - MainOptions
enum MainOptions {
    static var privacy: SettingsItem {
        .init(
            title: "SETTINGS_PRIVACY_TITLE",
            subtitle: "SETTINGS_PRIVACY_SUBTITLE",
            action: .openPrivacySettings
        )
    }

    static var appearance: SettingsItem {
        .init(
            title: "SETTINGS_DARKTHEME",
            subtitle: "SETTINGS_THEME_SYSTEM",
            action: .showActionSheet(title: "SETTINGS_DARKTHEME", preferenceKey: kVLCSettingAppTheme, hasInfo: false)
        )
    }

    static func section() -> SettingsSection? {
        .init(title: nil, items: [
            privacy,
            appearance
        ])
    }
}

// MARK: - DonationOptions
enum DonationOptions {
    static var donate: SettingsItem {
        .init(
            title: "SETTINGS_DONATE",
            subtitle: "SETTINGS_DONATE_LONG",
            action: .donation
        )
    }

    static func section() -> SettingsSection? {
        .init(title: "SETTINGS_DONATE_TITLE", items: [donate])
    }
}

// MARK: - GenericOptions
enum GenericOptions {
    static var defaultPlaybackSpeed: SettingsItem {
        .init(
            title: "SETTINGS_PLAYBACK_SPEED_DEFAULT",
            subtitle: "1.00x",
            action: .showActionSheet(title: "SETTINGS_PLAYBACK_SPEED_DEFAULT", preferenceKey: kVLCSettingPlaybackSpeedDefaultValue, hasInfo: false)
        )
    }

    static var continueAudioPlayback: SettingsItem {
        .init(
            title: "SETTINGS_CONTINUE_AUDIO_PLAYBACK",
            subtitle: "SETTINGS_CONTINUE_PLAYBACK_ALWAYS",
            action: .showActionSheet(title: "SETTINGS_CONTINUE_AUDIO_PLAYBACK", preferenceKey: kVLCSettingContinueAudioPlayback, hasInfo: true)
        )
    }

    static var playVideoInFullScreen: SettingsItem {
        .init(
            title: "SETTINGS_VIDEO_FULLSCREEN",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingVideoFullscreenPlayback)
        )
    }

    static var continueVideoPlayback: SettingsItem {
        .init(
            title: "SETTINGS_CONTINUE_VIDEO_PLAYBACK",
            subtitle: "SETTINGS_CONTINUE_PLAYBACK_ALWAYS",
            action: .showActionSheet(title: "SETTINGS_CONTINUE_VIDEO_PLAYBACK", preferenceKey: kVLCSettingContinuePlayback, hasInfo: true)
        )
    }

    static var automaticallyPlayNextItem: SettingsItem {
        .init(
            title: "SETTINGS_NETWORK_PLAY_ALL",
            subtitle: nil,
            action: .showActionSheet(title: "SETTINGS_NETWORK_PLAY_ALL", preferenceKey: kVLCAutomaticallyPlayNextItem, hasInfo: false)
        )
    }

    static var enableTextScrollingInMediaList: SettingsItem {
        .init(
            title: "SETTINGS_NETWORK_PLAY_ALL",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingEnableMediaCellTextScrolling)
        )
    }

    static var rememberPlayerState: SettingsItem {
        .init(
            title: "SETTINGS_REMEMBER_PLAYER_STATE",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCPlayerShouldRememberState)
        )
    }

    static var restoreLastPlayedMedia: SettingsItem {
        .init(
            title: "SETTINGS_RESTORE_LAST_PLAYED_MEDIA",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCRestoreLastPlayedMedia)
        )
    }

    static func section() -> SettingsSection? {
        .init(title: "SETTINGS_GENERIC_TITLE", items: [
            defaultPlaybackSpeed,
            continueAudioPlayback,
            playVideoInFullScreen,
            continueVideoPlayback,
            automaticallyPlayNextItem,
            enableTextScrollingInMediaList,
            rememberPlayerState,
            restoreLastPlayedMedia
        ])
    }

}

// MARK: - PrivacyOptions
enum PrivacyOptions {
    static var passcodeLock: SettingsItem {
        .init(
            title: "SETTINGS_PASSCODE_LOCK",
            subtitle: "SETTINGS_PASSCODE_LOCK_SUBTITLE",
            action: .toggle(preferenceKey: kVLCSettingPasscodeOnKey)
        )
    }

    static var enableBiometrics: SettingsItem? {
        let authContext = LAContext()

        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            switch authContext.biometryType {
            case .touchID:
                return .init(
                    title: "SETTINGS_PASSCODE_LOCK_ALLOWTOUCHID",
                    subtitle: nil,
                    action: .toggle(preferenceKey: kVLCSettingPasscodeAllowTouchID)
                )
            case .faceID:
                return .init(
                    title: "SETTINGS_PASSCODE_LOCK_ALLOWFACEID",
                    subtitle: nil,
                    action: .toggle(preferenceKey: kVLCSettingPasscodeAllowFaceID)
                )
            case .none:
                fallthrough
            @unknown default:
                return nil
            }
        }

        return nil
    }

    static var hideLibraryInFilesApp: SettingsItem {
        .init(
            title: "SETTINGS_HIDE_LIBRARY_IN_FILES_APP",
            subtitle: "SETTINGS_HIDE_LIBRARY_IN_FILES_APP_SUBTITLE",
            action: .toggle(preferenceKey: kVLCSettingHideLibraryInFilesApp)
        )
    }

    static func section() -> SettingsSection? {
        .init(title: "SETTINGS_PRIVACY_TITLE", items: [
            passcodeLock,
            enableBiometrics,
            hideLibraryInFilesApp
        ].compactMap({$0}))
    }
}

// MARK: - GestureControlOptions
enum GestureControlOptions {
    static var swipeUpDownForVolume: SettingsItem {
        .init(
            title: "SETTINGS_GESTURES_VOLUME",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingVolumeGesture)
        )
    }

    static var twoFingerTap: SettingsItem {
        .init(
            title: "SETTINGS_GESTURES_PLAYPAUSE",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingPlayPauseGesture)
        )
    }

    static var swipeUpDownForBrightness: SettingsItem {
        .init(
            title: "SETTINGS_GESTURES_BRIGHTNESS",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingBrightnessGesture)
        )
    }

    static var swipeRightLeftToSeek: SettingsItem {
        .init(
            title: "SETTINGS_GESTURES_SEEK",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingSeekGesture)
        )
    }

    static var pinchToClose: SettingsItem {
        .init(
            title: "SETTINGS_GESTURES_CLOSE",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingCloseGesture)
        )
    }

    static var forwardBackwardEqual: SettingsItem {
        .init(
            title: "SETTINGS_GESTURES_FORWARD_BACKWARD_EQUAL",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingPlaybackForwardBackwardEqual)
        )
    }

    static var tapSwipeEqual: SettingsItem {
        .init(
            title: "SETTINGS_GESTURES_TAP_SWIPE_EQUAL",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingPlaybackTapSwipeEqual)
        )
    }

    static var forwardSkipLength: SettingsItem {
        .init(
            title: dynamicForwardSkipDescription(),
            subtitle: nil,
            action: .showActionSheet(title: dynamicForwardSkipDescription(), preferenceKey: kVLCSettingPlaybackForwardSkipLength, hasInfo: false)
        )
    }

    static var backwardSkipLength: SettingsItem {
        .init(
            title: dynamicBackwardSkipDescription(),
            subtitle: nil,
            action: .showActionSheet(title: dynamicBackwardSkipDescription(), preferenceKey: kVLCSettingPlaybackBackwardSkipLength, hasInfo: false)
        )
    }

    static var forwardSkipLengthSwipe: SettingsItem {
        .init(
            title: dynamicForwardSwipeDescription(),
            subtitle: nil,
            action: .showActionSheet(title: dynamicForwardSwipeDescription(), preferenceKey: kVLCSettingPlaybackForwardSkipLengthSwipe, hasInfo: false)
        )
    }

    static var backwardSkipLengthSwipe: SettingsItem {
        .init(
            title: "SETTINGS_PLAYBACK_SKIP_BACKWARD_SWIPE",
            subtitle: nil,
            action: .showActionSheet(title: "SETTINGS_PLAYBACK_SKIP_BACKWARD_SWIPE", preferenceKey: kVLCSettingPlaybackBackwardSkipLengthSwipe, hasInfo: false)
        )
    }

    static var longTouchToSpeedUp: SettingsItem {
        .init(
            title: "SETINGS_LONG_TOUCH_SPEED_UP",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingPlaybackLongTouchSpeedUp)
        )
    }

    static func section(isForwardBackwardEqual: Bool, isTapSwipeEqual: Bool) -> SettingsSection? {
        .init(title: "SETTINGS_GESTURES", items: [
            swipeUpDownForVolume,
            twoFingerTap,
            swipeUpDownForBrightness,
            swipeRightLeftToSeek,
            pinchToClose,
            forwardBackwardEqual,
            tapSwipeEqual,
            forwardSkipLength,
            isForwardBackwardEqual ? nil : backwardSkipLength,
            isTapSwipeEqual ? nil : forwardSkipLengthSwipe,
            (isTapSwipeEqual || isForwardBackwardEqual) ? nil : backwardSkipLengthSwipe,
            longTouchToSpeedUp
        ].compactMap({$0}))
    }

    private static func dynamicForwardSkipDescription() -> String {
        let forwardBackwardEqual = UserDefaults.standard.bool(forKey: kVLCSettingPlaybackForwardBackwardEqual)
        let tapSwipeEqual = UserDefaults.standard.bool(forKey: kVLCSettingPlaybackTapSwipeEqual)

        if forwardBackwardEqual && tapSwipeEqual {
            return "SETTINGS_PLAYBACK_SKIP_GENERIC"
        } else if forwardBackwardEqual && !tapSwipeEqual {
            return "SETTINGS_PLAYBACK_SKIP_TAP"
        } else if !forwardBackwardEqual && !tapSwipeEqual {
            return "SETTINGS_PLAYBACK_SKIP_FORWARD_TAP"
        } else {
            return "SETTINGS_PLAYBACK_SKIP_FORWARD"
        }
    }

    private static func dynamicBackwardSkipDescription() -> String {
        let tapSwipeEqual = UserDefaults.standard.bool(forKey: kVLCSettingPlaybackTapSwipeEqual)

        if tapSwipeEqual {
            return "SETTINGS_PLAYBACK_SKIP_BACKWARD"
        } else {
            return "SETTINGS_PLAYBACK_SKIP_BACKWARD_TAP"
        }
    }

    private static func dynamicForwardSwipeDescription() -> String {
        let forwardBackwardEqual = UserDefaults.standard.bool(forKey: kVLCSettingPlaybackForwardBackwardEqual)

        if forwardBackwardEqual {
            return "SETTINGS_PLAYBACK_SKIP_SWIPE"
        } else {
            return "SETTINGS_PLAYBACK_SKIP_FORWARD_SWIPE"
        }
    }
}

// MARK: - VideoOptions
enum VideoOptions {
    static var deBlockingFilter: SettingsItem {
        .init(
            title: "SETTINGS_SKIP_LOOP_FILTER",
            subtitle: "SETTINGS_SKIP_LOOP_FILTER_NONREF",
            action: .showActionSheet(title: "SETTINGS_SKIP_LOOP_FILTER", preferenceKey: kVLCSettingSkipLoopFilter, hasInfo: true)
        )
    }

    static var deInterlace: SettingsItem {
        .init(
            title: "SETTINGS_DEINTERLACE",
            subtitle: "SETTINGS_DEINTERLACE_OFF",
            action: .showActionSheet(title: "SETTINGS_DEINTERLACE", preferenceKey: kVLCSettingDeinterlace, hasInfo: true)
        )
    }

    static var hardwareDecoding: SettingsItem {
        .init(
            title: "SETTINGS_HWDECODING",
            subtitle: "SETTINGS_HWDECODING_ON",
            action: .showActionSheet(title: "SETTINGS_HWDECODING", preferenceKey: kVLCSettingHardwareDecoding, hasInfo: true)
        )
    }

    static var rememberPlayerBrightness: SettingsItem {
        .init(
            title: "SETTINGS_REMEMBER_PLAYER_BRIGHTNESS",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCPlayerShouldRememberBrightness)
        )
    }

    static func section() -> SettingsSection? {
        .init(title: "SETTINGS_VIDEO_TITLE", items: [
            deBlockingFilter,
            deInterlace,
            hardwareDecoding,
            rememberPlayerBrightness
        ])
    }
}

// MARK: - SubtitlesOptions
enum SubtitlesOptions {
    static var disableSubtitles: SettingsItem {
        .init(
            title: "SETTINGS_SUBTITLES_DISABLE",
            subtitle: "SETTINGS_SUBTITLES_DISABLE_LONG",
            action: .toggle(preferenceKey: kVLCSettingDisableSubtitles)
        )
    }

    static var font: SettingsItem {
        .init(
            title: "SETTINGS_SUBTITLES_FONT",
            subtitle: "Arial",
            action: .showActionSheet(title: "SETTINGS_SUBTITLES_FONT", preferenceKey: kVLCSettingSubtitlesFont, hasInfo: true)
        )
    }

    static var relativeFontSize: SettingsItem {
        .init(
            title: "SETTINGS_SUBTITLES_FONTSIZE",
            subtitle: "SETTINGS_SUBTITLES_FONTSIZE_NORMAL",
            action: .showActionSheet(title: "SETTINGS_SUBTITLES_FONTSIZE", preferenceKey: kVLCSettingSubtitlesFontSize, hasInfo: true)
        )
    }

    static var useBoldFont: SettingsItem {
        .init(
            title: "SETTINGS_SUBTITLES_BOLDFONT",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingSubtitlesBoldFont)
        )
    }

    static var fontColor: SettingsItem {
        .init(
            title: "SETTINGS_SUBTITLES_FONTCOLOR",
            subtitle: "SETTINGS_SUBTITLES_FONTCOLOR_BLACK",
            action: .showActionSheet(title: "SETTINGS_SUBTITLES_FONTCOLOR", preferenceKey: kVLCSettingSubtitlesFontColor, hasInfo: true)
        )
    }

    static var textEncoding: SettingsItem {
        .init(
            title: "SETTINGS_SUBTITLES_TEXT_ENCODING",
            subtitle: "Western European (Windows-1252)",
            action: .showActionSheet(title: "SETTINGS_SUBTITLES_TEXT_ENCODING", preferenceKey: kVLCSettingTextEncoding, hasInfo: true)
        )
    }

    static func section() -> SettingsSection? {
        .init(title: "SETTINGS_SUBTITLES_TITLE", items: [
            disableSubtitles,
            font,
            relativeFontSize,
            useBoldFont,
            fontColor,
            textEncoding
        ])
    }
}

// MARK: - CastingOptions
enum CastingOptions {
    static var audioPassThrough: SettingsItem {
        .init(
            title: "SETTINGS_PTCASTING",
            subtitle: "SETTINGS_PTCASTINGLONG",
            action: .toggle(preferenceKey: kVLCSettingCastingAudioPassthrough)
        )
    }

    static var conversionQuality: SettingsItem {
        .init(
            title: "SETTINGS_CASTING_CONVERSION_QUALITY",
            subtitle: "SETTINGS_MEDIUM",
            action: .showActionSheet(title: "SETTINGS_CASTING_CONVERSION_QUALITY", preferenceKey: kVLCSettingCastingConversionQuality, hasInfo: false)
        )
    }

    static func section() -> SettingsSection? {
        .init(title: "SETTINGS_CASTING", items: [
            audioPassThrough,
            conversionQuality
        ])
    }
}

// MARK: - AudioOptions
enum AudioOptions {
    static var preampLevel: SettingsItem {
        .init(
            title: "SETTINGS_AUDIO_PREAMP_LEVEL",
            subtitle: "6 dB",
            action: .showActionSheet(title: "SETTINGS_AUDIO_PREAMP_LEVEL", preferenceKey: kVLCSettingDefaultPreampLevel, hasInfo: false)
        )
    }

    static var timeStretchingAudio: SettingsItem {
        .init(
            title: "SETTINGS_TIME_STRETCH_AUDIO",
            subtitle: "SETTINGS_TIME_STRETCH_AUDIO_LONG",
            action: .toggle(preferenceKey: kVLCSettingStretchAudio)
        )
    }

    static var audioPlaybackInBackground: SettingsItem {
        .init(
            title: "SETTINGS_BACKGROUND_AUDIO",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingContinueAudioInBackgroundKey)
        )
    }

    static func section() -> SettingsSection? {
        .init(title: "SETTINGS_AUDIO_TITLE", items: [
            preampLevel,
            timeStretchingAudio,
            audioPlaybackInBackground
        ])
    }
}

// MARK: - MediaLibraryOptions
enum MediaLibraryOptions {
    static var forceVLCToRescanTheMediaLibrary: SettingsItem {
        .init(
            title: "SETTINGS_MEDIA_LIBRARY_RESCAN",
            subtitle: nil,
            action: .forceRescanAlert,
            emphasizedTitle: true
        )
    }

    static var optimiseItemNamesForDisplay: SettingsItem {
        .init(
            title: "SETTINGS_DECRAPIFY",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingsDecrapifyTitles)
        )
    }

    static var disableGrouping: SettingsItem {
        .init(
            title: "SETTINGS_DISABLE_GROUPING",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingsDisableGrouping)
        )
    }

    static var showVideoThumbnails: SettingsItem {
        .init(
            title: "SETTINGS_SHOW_THUMBNAILS",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingShowThumbnails)
        )
    }

    static var showAudioArtworks: SettingsItem {
        .init(
            title: "SETTINGS_SHOW_ARTWORKS",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingShowArtworks)
        )
    }

    static var includeMediaLibInDeviceBackup: SettingsItem {
        .init(
            title: "SETTINGS_BACKUP_MEDIA_LIBRARY",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingBackupMediaLibrary)
        )
    }

    static var includeMediaLibInDeviceBackupWhenBackingUp: SettingsItem {
        .init(
            title: "SETTINGS_BACKUP_MEDIA_LIBRARY",
            subtitle: nil,
            action: .isLoading
        )
    }

    static func section(isBackingUp: Bool) -> SettingsSection? {
        .init(title: "SETTINGS_MEDIA_LIBRARY", items: [
            forceVLCToRescanTheMediaLibrary,
            optimiseItemNamesForDisplay,
            disableGrouping,
            showVideoThumbnails,
            showAudioArtworks,
            {
                if isBackingUp {
                    return includeMediaLibInDeviceBackupWhenBackingUp
                } else {
                    return includeMediaLibInDeviceBackup
                }
            }()
        ])
    }
}

// MARK: - NetworkOptions
enum NetworkOptions {
    static var networkCachingLevel: SettingsItem {
        .init(
            title: "SETTINGS_NETWORK_CACHING_TITLE",
            subtitle: "SETTINGS_NETWORK_CACHING_LEVEL_NORMAL",
            action: .showActionSheet(title: "SETTINGS_NETWORK_CACHING_TITLE", preferenceKey: kVLCSettingNetworkCaching, hasInfo: true)
        )
    }

    static var ipv6SupportForWiFiSharing: SettingsItem {
        .init(
            title: "SETTINGS_WIFISHARING_IPv6",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingWiFiSharingIPv6)
        )
    }

    static var forceSMBv1: SettingsItem {
        .init(
            title: "SETTINGS_FORCE_SMBV1",
            subtitle: "SETTINGS_FORCE_SMBV1_LONG",
            action: .toggle(preferenceKey: kVLCForceSMBV1)
        )
    }

    static var rtspctp: SettingsItem {
        .init(
            title: "SETTINGS_RTSP_TCP",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSettingNetworkRTSPTCP)
        )
    }

    static func section() -> SettingsSection? {
        .init(title: "SETTINGS_NETWORK", items: [
            networkCachingLevel,
            ipv6SupportForWiFiSharing,
            forceSMBv1,
            rtspctp
        ])
    }
}

// MARK: - Lab
enum Lab {
    static var debugLogging: SettingsItem {
        .init(
            title: "SETTINGS_DEBUG_LOG",
            subtitle: nil,
            action: .toggle(preferenceKey: kVLCSaveDebugLogs)
        )
    }

    static var exportLibrary: SettingsItem {
        .init(
            title: "SETTINGS_EXPORT_LIBRARY",
            subtitle: nil,
            action: .exportMediaLibrary
        )
    }

    static func section(isLabActivated: Bool) -> SettingsSection? {
        guard isLabActivated else { return nil }

        return .init(title: "SETTINGS_LAB", items: [
            debugLogging,
            exportLibrary
        ])
    }
}

// MARK: - Reset
enum Reset {
    static var resetOptions: SettingsItem {
        .init(
            title: "SETTINGS_RESET",
            subtitle: nil,
            action: .displayResetAlert
        )
    }

    static func section() -> SettingsSection? {
        .init(title: "SETTINGS_RESET_TITLE", items: [resetOptions])
    }
}
