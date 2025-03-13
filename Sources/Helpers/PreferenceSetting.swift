/*****************************************************************************
 * PreferenceSetting.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2025 VideoLAN. All rights reserved.
 *
 * Authors: Craig Reyenga <craig.reyenga # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

/// A preference from Settings.app.
///
/// These structures are decodable from plists. Apple's schema is followed
/// closely, however, the decoder does not support everything in full.
///
/// https://developer.apple.com/library/archive/documentation/PreferenceSettings/Conceptual/SettingsApplicationSchemaReference/
enum PreferenceSetting: Equatable {
    // Apple:
    case groupSpecifier(Group)
    case titleSpecifier(Title)
    case multiValueSpecifier(MultiValue)
    case textFieldSpecifier(TextField)
    case toggleSwitchSpecifier(Toggle)
    // not implemented yet, because we don't use them:
    //    case sliderSpecifier(Slider)
    //    case radioGroupSpecifier(RadioGroup)
    //    case childPaneSpecifier(ChildPane)

    // Us:
    case custom(Custom)

    // Nobody:
    case unsupported(String)
}

// - MARK: PreferenceSettingRoot

/// Container for preference specifiers
struct PreferenceSettingRoot {
    let specifiers: [PreferenceSetting]
}

// - MARK: Types of Preferences

extension PreferenceSetting {
    struct Group: Equatable {
        let title: String
        let footerText: String?
    }
}

extension PreferenceSetting {
    struct Title: Equatable {
        let key: String
        let title: String
        let choices: Choices
    }
}

extension PreferenceSetting {
    struct MultiValue: Equatable {
        let key: String
        let title: String
        let choices: Choices
    }
}

extension PreferenceSetting {
    struct TextField: Equatable {
        let key: String
        let title: String
        let defaultValue: String
    }
}

extension PreferenceSetting {
    struct Toggle: Equatable {
        let key: String
        let title: String
        let defaultValue: Bool
    }
}

// - MARK: Custom Preferences

extension PreferenceSetting {
    enum Custom: Equatable {
        case helloWorld(HelloWorld)
    }
}

extension PreferenceSetting.Custom {
    /// An example of a custom preference. Don't use it.
    struct HelloWorld: Equatable {
        let title: String
        let population: Int
    }
}

// - MARK: Number

extension PreferenceSetting {
    /// PropertyListDecoder has a bug where values that are explicitly declared
    /// as being integer or float are actually decodable as either. There is no
    /// way to distinguish them during decoding. To get around this, we use a
    /// structure that provides both types of values and place the burden of
    /// choice between the two on the consumers of this data.
    struct Number: Equatable {
        let float: Float
        let integer: Int

        static var zero: Number {
            .init(float: 0, integer: 0)
        }

        static func from(integer: Int) -> Self {
            .init(float: Float(integer), integer: integer)
        }
    }
}

// - MARK: Choices

extension PreferenceSetting {
    /// Choices are pairings of titles and values; values can be boolean, numeric, or string.
    enum Choices: Equatable {
        case bool([BoolChoice], defaultValue: Bool)
        case number([NumberChoice], defaultValue: Number)
        case string([StringChoice], defaultValue: String)
    }

    struct BoolChoice: Equatable {
        let title: String
        let value: Bool
    }

    struct NumberChoice: Equatable {
        let title: String
        let value: Number
    }

    struct StringChoice: Equatable {
        let title: String
        let value: String
    }
}

// - MARK: Decodable

extension PreferenceSettingRoot: Decodable {
    enum CodingKeys: String, CodingKey {
        case specifiers = "PreferenceSpecifiers"
    }
}

extension PreferenceSetting: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let typeString = try container.decode(String.self, forKey: .type)
        
        switch typeString {
        case SettingType.psGroupSpecifier.rawValue:
            let pref = try Group(from: decoder)
            self = .groupSpecifier(pref)

        case SettingType.psTitleValueSpecifier.rawValue:
            let pref = try Title(from: decoder)
            self = .titleSpecifier(pref)

        case SettingType.psMultiValueSpecifier.rawValue:
            let pref = try MultiValue(from: decoder)
            self = .multiValueSpecifier(pref)

        case SettingType.psTextFieldSpecifier.rawValue:
            let pref = try TextField(from: decoder)
            self = .textFieldSpecifier(pref)

        case SettingType.psToggleSwitchSpecifier.rawValue:
            let pref = try Toggle(from: decoder)
            self = .toggleSwitchSpecifier(pref)

        case SettingType.vlcCustomSpecifier.rawValue:
            let pref = try Custom(from: decoder)
            self = .custom(pref)

        case SettingType.psSliderSpecifier.rawValue,
            SettingType.psRadioGroupSpecifier.rawValue,
            SettingType.psChildPaneSpecifier.rawValue:
            fallthrough

        default:
            self = .unsupported(typeString)

        }
    }

    enum CodingKeys: String, CodingKey {
        case type = "Type"
    }
}

extension PreferenceSetting.Group: Decodable {
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case footerText = "FooterText"
    }
}

extension PreferenceSetting.Title: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.title = try container.decode(String.self, forKey: .title)
        self.choices = try .init(from: decoder)
    }

    enum CodingKeys: String, CodingKey {
        case key = "Key"
        case title = "Title"
    }
}

extension PreferenceSetting.MultiValue: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.title = try container.decode(String.self, forKey: .title)
        self.choices = try .init(from: decoder)
    }

    enum CodingKeys: String, CodingKey {
        case key = "Key"
        case title = "Title"
    }
}

extension PreferenceSetting.TextField: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.title = try container.decode(String.self, forKey: .title)
        self.defaultValue = try container.decodeIfPresent(String.self, forKey: .defaultValue) ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case key = "Key"
        case title = "Title"
        case defaultValue = "DefaultValue"
    }
}

extension PreferenceSetting.Toggle: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.title = try container.decode(String.self, forKey: .title)
        self.defaultValue = try container.decode(Bool.self, forKey: .defaultValue)
    }

    enum CodingKeys: String, CodingKey {
        case key = "Key"
        case title = "Title"
        case defaultValue = "DefaultValue"
    }
}

extension PreferenceSetting.Custom: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let subtype = try container.decode(String.self, forKey: .subtype)

        switch subtype {
        case PreferenceSetting.CustomSettingSubType.helloWorld.rawValue:
            self = .helloWorld(try HelloWorld(from: decoder))

        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported custom setting subtype: \(subtype)"))
        }
    }

    enum CodingKeys: String, CodingKey {
        case subtype = "Subtype"
    }
}

extension PreferenceSetting.Custom.HelloWorld: Decodable {
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case population = "Population"
    }
}

extension PreferenceSetting.Choices {
    /// A value type used only for the purposes of decoding.
    fileprivate enum IntermediateValue: Decodable {
        case bool(Bool)
        case string(String)
        case number(PreferenceSetting.Number)

        var boolValue: Bool? {
            switch self {
            case let .bool(value):
                return value
            default:
                return nil
            }
        }

        var stringValue: String? {
            switch self {
            case let .string(value):
                return value
            default:
                return nil
            }
        }

        var numberValue: PreferenceSetting.Number? {
            switch self {
            case let .number(value):
                return value
            default:
                return nil
            }
        }

        var floatValue: Float? {
            switch self {
            case let .number(value):
                return value.float
            default:
                return nil
            }
        }

        var integerValue: Int? {
            switch self {
            case let .number(value):
                return value.integer
            default:
                return nil
            }
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let bool = try? container.decode(Bool.self) {
                self = .bool(bool)
                return
            }

            if let str = try? container.decode(String.self) {
                self = .string(str)
                return
            }

            let float = try container.decode(Float.self)
            let integer = try container.decode(Int.self)

            self = .number(PreferenceSetting.Number(float: float, integer: integer))
        }
    }

    enum CodingKeys: String, CodingKey {
        case titles = "Titles"
        case values = "Values"
        case defaultValue = "DefaultValue"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let titles = try container.decode([String].self, forKey: .titles)
        let values = try container.decode([IntermediateValue].self, forKey: .values)
        let defaultValue = try container.decode(IntermediateValue.self, forKey: .defaultValue)

        guard !titles.isEmpty else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "empty titles array"))
        }

        guard titles.count == values.count else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "mismatch between titles and values"))
        }

        switch defaultValue {
        case let .bool(boolValue):
            let vals = values.compactMap(\.boolValue)
            let choices = zip(titles, vals).map { t, v in
                PreferenceSetting.BoolChoice(title: t, value: v)
            }

            guard vals.count == values.count else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "values did not all decode to the same type (bool)"))
            }

            guard vals.contains(boolValue) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Default value \(boolValue) not found in values"))
            }

            self = .bool(choices, defaultValue: boolValue)

        case let .number(numberValue):
            let vals = values.compactMap(\.numberValue)
            let choices = zip(titles, vals).map { t, v in
                PreferenceSetting.NumberChoice(title: t, value: v)
            }

            guard vals.count == values.count else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "values did not all decode to the same type (integer)"))
            }

            guard vals.contains(numberValue) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Default value \(numberValue) not found in values"))
            }

            self = .number(choices, defaultValue: numberValue)

        case let .string(stringValue):
            let vals = values.compactMap(\.stringValue)
            let choices = zip(titles, vals).map { t, v in
                PreferenceSetting.StringChoice(title: t, value: v)
            }

            guard vals.count == values.count else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "values did not all decode to the same type (string)"))
            }

            guard vals.contains(stringValue) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Default value \(stringValue) not found in values"))
            }

            self = .string(choices, defaultValue: stringValue)

        }
    }
}

// - MARK: SettingType

fileprivate extension PreferenceSetting {
    enum SettingType: String {
        case psGroupSpecifier = "PSGroupSpecifier"
        case psTitleValueSpecifier = "PSTitleValueSpecifier"
        case psMultiValueSpecifier = "PSMultiValueSpecifier"
        case psTextFieldSpecifier = "PSTextFieldSpecifier"
        case psToggleSwitchSpecifier = "PSToggleSwitchSpecifier"
        case psSliderSpecifier = "PSSliderSpecifier"
        case psRadioGroupSpecifier = "PSRadioGroupSpecifier"
        case psChildPaneSpecifier = "PSChildPaneSpecifier"
        case vlcCustomSpecifier = "VLCCustomSpecifier"
    }

    enum CustomSettingSubType: String {
        case helloWorld = "HelloWorld"
    }
}
