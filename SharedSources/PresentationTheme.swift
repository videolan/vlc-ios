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

@objcMembers public class ColorPalette : NSObject {

    public let isDark: Bool
    public let name: String
    public let background:UIColor
    public let cellBackgroundA:UIColor
    public let cellBackgroundB:UIColor
    public let cellDetailTextColor:UIColor
    public let cellTextColor:UIColor
    public let lightTextColor:UIColor
    public let sectionHeaderTextColor:UIColor
    public let sectionHeaderTintColor:UIColor
    public let settingsBackground:UIColor
    public let settingsCellBackground:UIColor
    public let settingsSeparatorColor:UIColor
    public let tabBarColor:UIColor
    public let orangeUI:UIColor

    public init(isDark: Bool,
                name: String,
                background:UIColor,
                cellBackgroundA:UIColor,
                cellBackgroundB:UIColor,
                cellDetailTextColor:UIColor,
                cellTextColor:UIColor,
                lightTextColor:UIColor,
                sectionHeaderTextColor:UIColor,
                sectionHeaderTintColor:UIColor,
                settingsBackground:UIColor,
                settingsCellBackground:UIColor,
                settingsSeparatorColor:UIColor,
                tabBarColor:UIColor,
                orangeUI:UIColor) {
        self.isDark = isDark
        self.name = name
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

@objcMembers public class PresentationTheme : NSObject {

    public static let brightTheme = PresentationTheme(colors: brightPalette)
    public static let darkTheme = PresentationTheme(colors: darkPalette)

    static var current: PresentationTheme = {
        let isDarkTheme = UserDefaults.standard.bool(forKey: kVLCSettingAppTheme)
        return isDarkTheme ? PresentationTheme.darkTheme : PresentationTheme.brightTheme
        }()
        {
        didSet {
            NotificationCenter.default.post(name: .VLCThemeDidChangeNotification, object: self)
            AppearanceManager.setupAppearance(theme: self.current)
        }
    }
    public init(colors: ColorPalette) {
        self.colors = colors
    }

    public let colors: ColorPalette
}

@objc public extension UIColor {

    public convenience init(_ rgbValue:UInt32, _ alpha:CGFloat = 1.0) {
        let r = CGFloat((rgbValue & 0xFF0000) >> 16)/255.0
        let g = CGFloat((rgbValue & 0xFF00) >> 8)/255.0
        let b = CGFloat(rgbValue & 0xFF)/255.0
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
                                background: UIColor(0xf9f9f7),
                                cellBackgroundA: UIColor(0xf9f9f7),
                                cellBackgroundB: UIColor(0xe5e5e3),
                                cellDetailTextColor: UIColor(0xd3d3d3),
                                cellTextColor: UIColor(0x000000),
                                lightTextColor: UIColor(0x888888),
                                sectionHeaderTextColor: UIColor(0xf9f9f7),
                                sectionHeaderTintColor: UIColor(0xe5efe3),
                                settingsBackground: UIColor(0xdcdcdc),
                                settingsCellBackground: UIColor(0xf9f9f7),
                                settingsSeparatorColor: UIColor(0xd3d3d3),
                                tabBarColor: UIColor(0xffffff),
                                orangeUI: UIColor(0xff8800))

let darkPalette = ColorPalette(isDark: true,
                               name: "Dark",
                               background: UIColor(0x292b36),
                               cellBackgroundA: UIColor(0x292b36),
                               cellBackgroundB: UIColor(0x000000),
                               cellDetailTextColor: UIColor(0xd3d3d3),
                               cellTextColor: UIColor(0xffffff),
                               lightTextColor: UIColor(0xb8b8b8),
                               sectionHeaderTextColor: UIColor(0x828282),
                               sectionHeaderTintColor: UIColor(0x3c3c3c),
                               settingsBackground: UIColor(0x292b36),
                               settingsCellBackground: UIColor(0x3d3f40),
                               settingsSeparatorColor: UIColor(0xa9a9a9),
                               tabBarColor: UIColor(0xffffff),
                               orangeUI: UIColor(0xff8800))
