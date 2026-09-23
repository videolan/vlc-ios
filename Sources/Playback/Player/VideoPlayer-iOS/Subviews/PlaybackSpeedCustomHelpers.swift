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

    var appliesToAllMedia: Bool {
        get {
            return userDefaults.bool(forKey: kVLCSettingPlaybackSpeedAppliesToAll)
        }
        set {
            userDefaults.set(newValue, forKey: kVLCSettingPlaybackSpeedAppliesToAll)
        }
    }

    var defaultSpeed: Float {
        let speed = effectiveSpeedValue
        return speed > 0 ? speed : 1
    }

    func setDefaultSpeed(_ speed: Float) {
        if Self.presetSpeedValues.contains(speed) {
            userDefaults.set(speed, forKey: kVLCSettingPlaybackSpeedDefaultValue)
        } else {
            userDefaults.set("custom", forKey: kVLCSettingPlaybackSpeedDefaultValue)
            userDefaults.set(String(format: "%.2f", speed), forKey: Self.customSpeedKey)
        }
    }

    private static let presetSpeedValues: [Float] = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 3.5, 4]
}

@objc class PlaybackDelayFormatter: NSObject {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        formatter.positivePrefix = formatter.plusSign
        formatter.zeroSymbol = "0"
        return formatter
    }()

    @objc static func string(forDelay delay: Float) -> String {
        let value = formatter.string(from: NSNumber(value: delay.rounded())) ?? String(format: "%.0f", delay)
        return String(format: NSLocalizedString("DELAY_MS_FORMAT", comment: ""), value)
    }
}

enum PlaybackSpeedScale {
    static let minimumSpeed: Float = 0.25
    static let maximumSpeed: Float = 8
    static let sliderNeutralValue: Float = 0.5

    static func speed(forSliderValue value: Float) -> Float {
        let base: Float = value < sliderNeutralValue ? 4 : 8
        return rounded(pow(base, value / sliderNeutralValue - 1))
    }

    static func sliderValue(forSpeed speed: Float) -> Float {
        let base: Float = speed < 1 ? 4 : 8
        return sliderNeutralValue * (1 + log(speed) / log(base))
    }

    static func rounded(_ speed: Float) -> Float {
        return min(max((speed * 100).rounded() / 100, minimumSpeed), maximumSpeed)
    }

    static func steppedSpeed(from speed: Float, increasing: Bool) -> Float {
        let hundredths = Int((speed * 100).rounded())
        let stepped = increasing ? (hundredths / 5 + 1) * 5 : (hundredths - 1) / 5 * 5
        return rounded(Float(stepped) / 100)
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
