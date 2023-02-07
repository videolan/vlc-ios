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
    let specifier: [Specifier]
}

struct Specifier {
    let itemTitle: String
    let value: Any
}
