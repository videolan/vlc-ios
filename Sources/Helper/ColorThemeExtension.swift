/*****************************************************************************
 * ColorThemeExtension.swift
 *
 * Copyright © 2021 VLC authors and VideoLAN
 * Copyright © 2021 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension UICollectionViewController {
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
                // Since traitCollectionDidChange is called in, for example rotations, we make sure that
                // there was a userInterfaceStyle change.
                return
            }
            guard UserDefaults.standard.integer(forKey: kVLCSettingAppTheme) == kVLCSettingAppThemeSystem else {
                // Theme is specificly set, do not follow systeme theme.
                return
            }

            let isSystemDarkTheme = traitCollection.userInterfaceStyle == .dark
            PresentationTheme.current = isSystemDarkTheme ? PresentationTheme.darkTheme : PresentationTheme.brightTheme

        }
    }
}

extension UITableViewController {
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
                // Since traitCollectionDidChange is called in, for example rotations, we make sure that
                // there was a userInterfaceStyle change.
                return
            }
            guard UserDefaults.standard.integer(forKey: kVLCSettingAppTheme) == kVLCSettingAppThemeSystem else {
                // Theme is specificly set, do not follow systeme theme.
                return
            }

            let isSystemDarkTheme = traitCollection.userInterfaceStyle == .dark
            PresentationTheme.current = isSystemDarkTheme ? PresentationTheme.darkTheme : PresentationTheme.brightTheme

        }
    }
}
