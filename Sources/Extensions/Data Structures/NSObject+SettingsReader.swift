/*****************************************************************************
* NSObjectExtension.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
*
* Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import Foundation

enum SettingsSpecifierCache {
    private static var specifiersByKey: [String: NSDictionary]?
    private static let settingsBundle: Bundle? = Bundle.main.path(forResource: "Settings", ofType: "bundle").flatMap(Bundle.init(path:))

    static func specifier(for preferenceKey: String) -> NSDictionary? {
        if specifiersByKey == nil {
            specifiersByKey = load()
        }
        return specifiersByKey?[preferenceKey]
    }

    static func localizedString(for key: String) -> String {
        let localized = settingsBundle?.localizedString(forKey: key, value: key, table: "Root") ?? key
        return localized == key ? NSLocalizedString(key, comment: "") : localized
    }

    static func customValue(for preferenceKey: String) -> CustomValueSpecifier? {
        guard let dictionary = specifier(for: preferenceKey)?["CustomValue"] as? NSDictionary else {
            return nil
        }
        return CustomValueSpecifier(preferenceKey: preferenceKey, dictionary: dictionary)
    }

    static func titlesAndValues(for preferenceKey: String) -> (titles: [String], values: NSArray)? {
        guard let prefSpecification = specifier(for: preferenceKey),
            let titles = prefSpecification["Titles"] as? [String],
            let values = prefSpecification["Values"] as? NSArray else {
            return nil
        }
        return (titles, values)
    }

    static func purge() {
        specifiersByKey = nil
    }

    private static func load() -> [String: NSDictionary] {
        let (resource, withExtension, subdirectory) = ("Root", "inApp.plist", "Settings.bundle")
        let preferenceSpecifiers = "PreferenceSpecifiers"

        guard let settingsURL = Bundle.main.url(forResource: resource, withExtension: withExtension, subdirectory: subdirectory),
            let settings = NSDictionary(contentsOf: settingsURL),
            let preferences = settings[preferenceSpecifiers] as? [NSDictionary] else {
            return [:]
        }

        var specifiers = [String: NSDictionary](minimumCapacity: preferences.count)
        for prefSpecification in preferences {
            if let key = prefSpecification["Key"] as? String {
                specifiers[key] = prefSpecification
            }
        }
        return specifiers
    }
}

extension NSObject {
    func getSettingsBundle() -> Bundle? {
        if let settingsBundlePath = Bundle.main.path(forResource: "Settings", ofType: "bundle") {
            return Bundle.init(path: settingsBundlePath)
        }
        return nil
    }

    func getSettingsSpecifier(for preferenceKey: String) -> SettingSpecifier? {
        guard let prefSpecification = SettingsSpecifierCache.specifier(for: preferenceKey) else {
            return nil
        }

        let title = prefSpecification["Title"] as? String ?? ""
        let infobuttonvalue = prefSpecification["infobuttonvalue"] as? String ?? ""
        let defaultValue = prefSpecification["DefaultValue"]
        var specifier = [Specifier]()

        if let (titles, values) = SettingsSpecifierCache.titlesAndValues(for: preferenceKey) {
            for (itemTitle, value) in zip(titles, values) {
                specifier.append(Specifier(itemTitle: itemTitle, value: value))
            }
        }

        return SettingSpecifier(title: title,
                                preferenceKey: preferenceKey,
                                infobuttonvalue: infobuttonvalue,
                                defaultValue: defaultValue,
                                specifier: specifier,
                                customValue: SettingsSpecifierCache.customValue(for: preferenceKey))
    }

    func getSubtitle(for preferenceKey: String) -> String? {
        if preferenceKey == kVLCSettingPlaybackSpeedDefaultValue {
            let value = UserDefaults.standard.object(forKey: preferenceKey)
            if let stringValue = value as? String, stringValue == "custom" {
                let customSpeed = UserDefaults.standard.float(forKey: "playback-speed-custom")
                return PlaybackSpeedFormatter.string(forSpeed: customSpeed)
            }
        }

        guard let userDefaultValue = UserDefaults.standard.value(forKey: preferenceKey),
            let (titles, values) = SettingsSpecifierCache.titlesAndValues(for: preferenceKey) else {
            return nil
        }

        let customValue = SettingsSpecifierCache.customValue(for: preferenceKey)
        let userDefaultAsString = String(describing: userDefaultValue)

        if let customValue = customValue, String(describing: customValue.sentinel) == userDefaultAsString {
            return customValue.formattedString(for: customValue.storedValue)
        }

        for (title, value) in zip(titles, values) {
            if String(describing: value) == userDefaultAsString {
                return title
            }
        }

        if let customValue = customValue {
            return customValue.formattedString(for: customValue.storedValue)
        }

        return nil
    }

    func getSelectedItem(for preferenceKey: String) -> Int? {
        guard let userDefaultValue = UserDefaults.standard.value(forKey: preferenceKey),
            let (titles, values) = SettingsSpecifierCache.titlesAndValues(for: preferenceKey) else {
            return nil
        }

        let userDefaultAsString = String(describing: userDefaultValue)
        for (index, (_, value)) in zip(titles, values).enumerated() {
            if String(describing: value) == userDefaultAsString {
                return index
            }
        }

        if let customValue = SettingsSpecifierCache.customValue(for: preferenceKey) {
            let index = values.index(of: customValue.sentinel)
            return index == NSNotFound ? nil : index
        }

        return nil
    }
}
