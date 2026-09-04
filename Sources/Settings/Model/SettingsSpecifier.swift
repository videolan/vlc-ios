/*****************************************************************************
* SettingsSpecifier.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
*
* Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import Foundation

struct SettingSpecifier {
    let title: String
    let preferenceKey: String
    let infobuttonvalue: String
    let defaultValue: Any?
    let specifier: [Specifier]
    let customValue: CustomValueSpecifier?
}

struct Specifier {
    let itemTitle: String
    let value: Any
}

struct CustomValueSpecifier {
    let preferenceKey: String
    let valueKey: String
    let sentinel: NSObject
    let minimum: Double
    let maximum: Double
    let fractionDigits: Int
    let format: String?

    init?(preferenceKey: String, dictionary: NSDictionary) {
        guard let sentinel = dictionary["Sentinel"] as? NSObject,
              let minimum = dictionary["Minimum"] as? Double,
              let maximum = dictionary["Maximum"] as? Double else {
            return nil
        }

        self.preferenceKey = preferenceKey
        self.valueKey = dictionary["ValueKey"] as? String ?? preferenceKey
        self.sentinel = sentinel
        self.minimum = minimum
        self.maximum = maximum
        self.fractionDigits = dictionary["FractionDigits"] as? Int ?? 0
        self.format = dictionary["Format"] as? String
    }

    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter
    }

    var storedValue: Double {
        UserDefaults.standard.double(forKey: valueKey)
    }

    func plainString(for value: Double) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    func formattedString(for value: Double) -> String {
        guard let format = format else {
            return plainString(for: value)
        }
        return String(format: SettingsSpecifierCache.localizedString(for: format), plainString(for: value))
    }

    func value(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let number = numberFormatter.number(from: trimmed) {
            return number.doubleValue
        }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    func store(_ value: Double) {
        let defaults = UserDefaults.standard

        if fractionDigits == 0 {
            defaults.set(Int(value), forKey: valueKey)
        } else {
            defaults.set(value, forKey: valueKey)
        }

        if valueKey != preferenceKey {
            defaults.set(sentinel, forKey: preferenceKey)
        }
    }
}
