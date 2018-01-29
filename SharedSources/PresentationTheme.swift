/*****************************************************************************
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

let VLCThemeDidChangeNotification = Notification.Name("themeDidChangeNotfication")

public final class ColorPalette : NSObject {

    @objc public let isDark: Bool
    @objc public let name: String
    @objc public let background:UIColor
    @objc public let cellBackgroundA:UIColor
    @objc public let cellBackgroundB:UIColor
    @objc public let cellDetailTextColor:UIColor
    @objc public let cellTextColor:UIColor
    @objc public let sectionHeaderTextColor:UIColor
    @objc public let sectionHeaderTintColor:UIColor
    @objc public let settingsBackground:UIColor
    @objc public let settingsCellBackground:UIColor
    @objc public let settingsSeparatorColor:UIColor
    @objc public let tabBarColor:UIColor
    @objc public let orangeUI:UIColor

    public init(isDark: Bool,
                name: String,
                background:UIColor,
                cellBackgroundA:UIColor,
                cellBackgroundB:UIColor,
                cellDetailTextColor:UIColor,
                cellTextColor:UIColor,
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
        self.sectionHeaderTextColor = sectionHeaderTextColor
        self.sectionHeaderTintColor = sectionHeaderTintColor
        self.settingsBackground = settingsBackground
        self.settingsCellBackground = settingsCellBackground
        self.settingsSeparatorColor = settingsSeparatorColor
        self.tabBarColor = tabBarColor
        self.orangeUI = orangeUI
    }
}

public class PresentationTheme : NSObject {

    @objc public let colors:ColorPalette
    @objc public static let whiteTheme = PresentationTheme(colors: whitePalette)
    @objc public static let darkTheme = PresentationTheme(colors: darkPalette)
    public init(colors: ColorPalette) {
        self.colors = colors
    }
    @objc static var current: PresentationTheme = {
        let darkTheme = UserDefaults.standard.bool(forKey: kVLCSettingAppTheme)
        return darkTheme ? PresentationTheme.darkTheme : PresentationTheme.whiteTheme
        }()
        {
        didSet {
            NotificationCenter.default.post(name: VLCThemeDidChangeNotification, object: self)
        }
    }
}

public extension UIColor {

    public convenience init(_ rgbValue:UInt32, _ alpha:CGFloat = 1.0) {
        let red = ((CGFloat)((rgbValue & 0xFF0000) >> 16))/255.0
        let green = ((CGFloat)((rgbValue & 0xFF00) >> 8))/255.0
        let blue = ((CGFloat)(rgbValue & 0xFF))/255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

public let whitePalette = ColorPalette(isDark: false,
                                       name: "Default",
                                       background: UIColor(0xf9f9f7),
                                       cellBackgroundA: UIColor(0xf9f9f7),
                                       cellBackgroundB: UIColor(0xe5e5e3),
                                       cellDetailTextColor: .lightGray,
                                       cellTextColor: UIColor(0x000000),
                                       sectionHeaderTextColor: UIColor(0xf9f9f7),
                                       sectionHeaderTintColor: UIColor(0xe5efe3),
                                       settingsBackground:UIColor(0xdcdcdc),
                                       settingsCellBackground:UIColor(0xf9f9f7),
                                       settingsSeparatorColor:.lightGray,
                                       tabBarColor: UIColor(0x000000),
                                       orangeUI: UIColor(0xff8400))

public let darkPalette = ColorPalette(isDark: true,
                                      name: "Dark",
                                      background: UIColor(0x292b36),
                                      cellBackgroundA: UIColor(0x292b36),
                                      cellBackgroundB: UIColor(0x000000),
                                      cellDetailTextColor: .lightGray,
                                      cellTextColor:UIColor(0xffffff),
                                      sectionHeaderTextColor: UIColor(0x828282),
                                      sectionHeaderTintColor:UIColor(0x3c3c3c),
                                      settingsBackground:UIColor(0x292b36),
                                      settingsCellBackground:UIColor(0x3d3f40),
                                      settingsSeparatorColor:.darkGray,
                                      tabBarColor: UIColor(0xffffff),
                                      orangeUI: UIColor(0xff8400))
