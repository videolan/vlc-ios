/*****************************************************************************
 * PlaybackSpeedCustomHelpers.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2025 VLC authors and VideoLAN
 *
 * Authors: Yue(Zelda) Zhang <lichtseeker@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@objc class PlaybackSpeedFormatter: NSObject {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    @objc static func string(forSpeed speed: Float) -> String {
        let value = formatter.string(from: NSNumber(value: speed)) ?? String(format: "%.2f", speed)
        return String(format: NSLocalizedString("PLAYBACK_SPEED_FORMAT", comment: ""), value)
    }
}

class PlaybackSpeedCustomManager {
    static let shared = PlaybackSpeedCustomManager()

    private static let customSpeedKey = "playback-speed-custom"
    private let userDefaults = UserDefaults.standard

    private init() {}

    private var currentSpeedSetting: String {
        return userDefaults.object(forKey: kVLCSettingPlaybackSpeedDefaultValue) as? String ?? "1.0"
    }

    var effectiveSpeedValue: Float {
        if currentSpeedSetting == "custom" {
            return userDefaults.float(forKey: Self.customSpeedKey)
        }

        let presetSpeedValue = userDefaults.float(forKey: kVLCSettingPlaybackSpeedDefaultValue)
        if presetSpeedValue > 0 {
            return presetSpeedValue
        }

        if let floatValue = Float(currentSpeedSetting) {
            return floatValue
        }
        return 1.0
    }
}

enum UIUtils {
#if !os(tvOS)
    static func createToolbar() -> UIToolbar {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        toolBar.barStyle = PresentationTheme.current.colors.toolBarStyle
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.items = [flexSpace]
        return toolBar
    }
#endif
}
