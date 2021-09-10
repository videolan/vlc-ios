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

extension NSObject {

    private func bestMatchingLocale() -> URL? {
        guard let collatorIdentifier = Locale.current.collatorIdentifier else { return nil }
        guard let language = Locale.current.languageCode else { return nil }

        var scripts: [String] = [""]
        var regions: [String] = [""]

        if let script = Locale.current.scriptCode {
            scripts.insert("-\(script)", at: 0)
        }
        if let region = Locale.current.regionCode {
            regions.insert("-\(region)", at: 0)
        }

        // Check if the default URL for current locale settings would work
        let lprojPath = "Settings.bundle/\(collatorIdentifier).lproj"
        let lprojURL = Bundle.main.url(forResource: "Root",
                                       withExtension: "strings",
                                       subdirectory: lprojPath)
        if let path = lprojURL?.path,
           FileManager.default.fileExists(atPath: path) {
            return lprojURL
        }

        // If not, for more exotic cases like using a language in a country where this language is not official (like de_FR),
        // we check combinations with available lproj files.
        for region in regions {
            for script in scripts {
                let lprojPath = "Settings.bundle/\(language)\(script)\(region).lproj"
                let lprojURL = Bundle.main.url(forResource: "Root",
                                               withExtension: "strings",
                                               subdirectory: lprojPath)
                if let path = lprojURL?.path,
                   FileManager.default.fileExists(atPath: path) {
                    return lprojURL
                }
            }
        }
        return nil
    }

    func getLocaleDictionary() -> NSDictionary? {
        // Use English as default instead of returning nil, leading to empty localisation
        guard let defaultURL = Bundle.main.url(forResource: "Root",
                                               withExtension: "strings",
                                               subdirectory: "Settings.bundle/en.lproj") else { return nil }

        let url = bestMatchingLocale()

        guard let dict = NSDictionary(contentsOf: url ?? defaultURL) else { return nil }
        return dict
    }

    func getSettingsSpecifier(for preferenceKey: String) -> SettingSpecifier? {
        var settingsSpecifierDict: SettingSpecifier?
        let (resource, withExtension, subdirectory) = ("Root", "inApp.plist", "Settings.bundle")
        let preferenceSpecifiers = "PreferenceSpecifiers"

        if let settingsURL = Bundle.main.url(forResource: resource, withExtension: withExtension, subdirectory: subdirectory),
            let settings = NSDictionary(contentsOf: settingsURL),
            let preferences = settings[preferenceSpecifiers] as? [NSDictionary] {
            for prefSpecification in preferences {
                if prefSpecification["Key"] as? String == preferenceKey {
                    let title = prefSpecification["Title"] as? String ?? ""
                    var specifier = [Specifier]()
                    if let titles = prefSpecification["Titles"] as? [String], let values = prefSpecification["Values"] as? NSArray {
                        for (itemTitle, value) in zip(titles, values) {
                            let newSpecifier = Specifier(itemTitle: itemTitle, value: value)
                            specifier.append(newSpecifier)
                        }
                    }
                    let newSpecifierObject = SettingSpecifier(title: title, preferenceKey: preferenceKey, specifier: specifier)
                    settingsSpecifierDict = newSpecifierObject
                }
                else {
                    continue
                }
            }
        }
        return settingsSpecifierDict
    }

    func getSubtitle(for preferenceKey: String) -> String? {
        guard let userDefaultValue = UserDefaults.standard.value(forKey: preferenceKey) else { return nil }
        let (forResource, withExtension, subdirectory) = ("Root", "inApp.plist", "Settings.bundle")
        let preferenceSpecifiers = "PreferenceSpecifiers"
        let userDefaultAsString = String(describing: userDefaultValue)

        if let settingsURL = Bundle.main.url(forResource: forResource, withExtension: withExtension, subdirectory: subdirectory),
            let settings = NSDictionary(contentsOf: settingsURL),
            let preferences = settings[preferenceSpecifiers] as? [NSDictionary] {
            for prefSpecification in preferences {
                if prefSpecification["Key"] as? String == preferenceKey {
                    if let titles = prefSpecification["Titles"] as? [String], let values = prefSpecification["Values"] as? NSArray {
                        for (title, value) in zip(titles, values) {
                            if String(describing: value) == userDefaultAsString {
                                return title
                            }
                        }
                    }
                }
            }
        }
        return nil
    }

    func getSelectedItem(for preferenceKey: String) -> Int? {
        guard let userDefaultValue = UserDefaults.standard.value(forKey: preferenceKey) else { return nil }
        let (forResource, withExtension, subdirectory) = ("Root", "inApp.plist", "Settings.bundle")
        let preferenceSpecifiers = "PreferenceSpecifiers"
        let userDefaultAsString = String(describing: userDefaultValue)
        var count = 0

        if let settingsURL = Bundle.main.url(forResource: forResource, withExtension: withExtension, subdirectory: subdirectory),
            let settings = NSDictionary(contentsOf: settingsURL),
            let preferences = settings[preferenceSpecifiers] as? [NSDictionary] {
            for prefSpecification in preferences {
                if prefSpecification["Key"] as? String == preferenceKey {
                    if let titles = prefSpecification["Titles"] as? [String], let values = prefSpecification["Values"] as? NSArray {
                        for (_, value) in zip(titles, values) {
                            if String(describing: value) == userDefaultAsString {
                                return count
                            }
                            count += 1
                        }

                    }
                }
            }
        }
        return nil
    }
}
