/*****************************************************************************
 * PresentationTheme.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

extension Notification.Name {
    static let VLCThemeDidChangeNotification = Notification.Name("themeDidChangeNotfication")
}

@objcMembers public class ColorPalette: NSObject {

    public let isDark: Bool
    public let name: String
    public let statusBarStyle: UIStatusBarStyle
    public let navigationbarColor: UIColor
    public let navigationbarTextColor: UIColor
    public let background: UIColor
    public let cellBackgroundA: UIColor
    public let cellBackgroundB: UIColor
    public let cellDetailTextColor: UIColor
    public let cellTextColor: UIColor
    public let lightTextColor: UIColor
    public let sectionHeaderTextColor: UIColor
    public let sectionHeaderTintColor: UIColor
    public let settingsBackground: UIColor
    public let settingsCellBackground: UIColor
    public let settingsSeparatorColor: UIColor
    public let tabBarColor: UIColor
    public let orangeUI: UIColor

    public init(isDark: Bool,
                name: String,
                statusBarStyle: UIStatusBarStyle,
                navigationbarColor: UIColor,
                navigationbarTextColor: UIColor,
                background: UIColor,
                cellBackgroundA: UIColor,
                cellBackgroundB: UIColor,
                cellDetailTextColor: UIColor,
                cellTextColor: UIColor,
                lightTextColor: UIColor,
                sectionHeaderTextColor: UIColor,
                sectionHeaderTintColor: UIColor,
                settingsBackground: UIColor,
                settingsCellBackground: UIColor,
                settingsSeparatorColor: UIColor,
                tabBarColor: UIColor,
                orangeUI: UIColor) {
        self.isDark = isDark
        self.name = name
        self.statusBarStyle = statusBarStyle
        self.navigationbarColor = navigationbarColor
        self.navigationbarTextColor = navigationbarTextColor
        self.background = background
        self.cellBackgroundA = cellBackgroundA
        self.cellBackgroundB = cellBackgroundB
        self.cellDetailTextColor = cellDetailTextColor
        self.cellTextColor = cellTextColor
        self.lightTextColor = lightTextColor
        self.sectionHeaderTextColor = sectionHeaderTextColor
        self.sectionHeaderTintColor = sectionHeaderTintColor
        self.settingsBackground = settingsBackground
        self.settingsCellBackground = settingsCellBackground
        self.settingsSeparatorColor = settingsSeparatorColor
        self.tabBarColor = tabBarColor
        self.orangeUI = orangeUI
    }
}

@objcMembers public class PresentationTheme: NSObject {

    public static let brightTheme = PresentationTheme(colors: brightPalette)
    public static let darkTheme = PresentationTheme(colors: darkPalette)

    static var current: PresentationTheme = {
        let isDarkTheme = UserDefaults.standard.bool(forKey: kVLCSettingAppTheme)
        return isDarkTheme ? PresentationTheme.darkTheme : PresentationTheme.brightTheme
    }() {
        didSet {
            AppearanceManager.setupAppearance(theme: self.current)
            NotificationCenter.default.post(name: .VLCThemeDidChangeNotification, object: self)
        }
    }

    public init(colors: ColorPalette) {
        self.colors = colors
    }

    public let colors: ColorPalette
}

@objc public extension UIColor {

    public convenience init(_ rgbValue: UInt32, _ alpha: CGFloat = 1.0) {
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0xFF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }

    private func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            assertionFailure()
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count == 4 {
            a = Float(components[3])
        }

        if alpha {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }

    var toHex: String? {
        return toHex()
    }
}

let brightPalette = ColorPalette(isDark: false,
                                 name: "Default",
                                 statusBarStyle: .default,
                                 navigationbarColor: UIColor(0xFFFFFF),
                                 navigationbarTextColor: UIColor(0x000000),
                                 background: UIColor(0xF9F9F7),
                                 cellBackgroundA: UIColor(0xF9F9F7),
                                 cellBackgroundB: UIColor(0xE5E5E3),
                                 cellDetailTextColor: UIColor(0xA9A9A9),
                                 cellTextColor: UIColor(0x000000),
                                 lightTextColor: UIColor(0x888888),
                                 sectionHeaderTextColor: UIColor(0xF9F9F7),
                                 sectionHeaderTintColor: UIColor(0xE5EFE3),
                                 settingsBackground: UIColor(0xDCDCDC),
                                 settingsCellBackground: UIColor(0xF9F9F7),
                                 settingsSeparatorColor: UIColor(0xD3D3D3),
                                 tabBarColor: UIColor(0xFFFFFF),
                                 orangeUI: UIColor(0xFF8800))

let darkPalette = ColorPalette(isDark: true,
                               name: "Dark",
                               statusBarStyle: .lightContent,
                               navigationbarColor: UIColor(0x292B36),
                               navigationbarTextColor: UIColor(0xD3D3D3),
                               background: UIColor(0x292B36),
                               cellBackgroundA: UIColor(0x292B36),
                               cellBackgroundB: UIColor(0x000000),
                               cellDetailTextColor: UIColor(0xD3D3D3),
                               cellTextColor: UIColor(0xFFFFFF),
                               lightTextColor: UIColor(0xB8B8B8),
                               sectionHeaderTextColor: UIColor(0x828282),
                               sectionHeaderTintColor: UIColor(0x3C3C3C),
                               settingsBackground: UIColor(0x292B36),
                               settingsCellBackground: UIColor(0x3D3F40),
                               settingsSeparatorColor: UIColor(0xA9A9A9),
                               tabBarColor: UIColor(0x292B36),
                               orangeUI: UIColor(0xFF8800))
