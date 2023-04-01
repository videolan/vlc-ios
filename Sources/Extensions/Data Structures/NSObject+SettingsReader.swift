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
    func getSettingsBundle() -> Bundle? {
        if let settingsBundlePath = Bundle.main.path(forResource: "Settings", ofType: "bundle") {
            return Bundle.init(path: settingsBundlePath)
        }
        return nil
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
                    let infobuttonvalue = prefSpecification["infobuttonvalue"] as? String ?? ""
                    var specifier = [Specifier]()
                    if let titles = prefSpecification["Titles"] as? [String], let values = prefSpecification["Values"] as? NSArray {
                        for (itemTitle, value) in zip(titles, values) {
                            let newSpecifier = Specifier(itemTitle: itemTitle, value: value)
                            specifier.append(newSpecifier)
                        }
                    }
                    let newSpecifierObject = SettingSpecifier(title: title, preferenceKey: preferenceKey, infobuttonvalue: infobuttonvalue, specifier: specifier)
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
