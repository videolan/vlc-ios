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

extension PresentationTheme {
    static func traitCollectionDidChange(from previousTraitCollection: UITraitCollection?, to traitCollection: UITraitCollection) {
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

            PresentationTheme.themeDidUpdate()
        }
    }
}

extension UICollectionViewController {
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        PresentationTheme.traitCollectionDidChange(from: previousTraitCollection, to: traitCollection)
    }
}

extension UITableViewController {
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        PresentationTheme.traitCollectionDidChange(from: previousTraitCollection, to: traitCollection)
    }
}

extension VLCOpenNetworkStreamViewController {
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        PresentationTheme.traitCollectionDidChange(from: previousTraitCollection, to: traitCollection)
    }
}

extension VLCDownloadViewController {
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        PresentationTheme.traitCollectionDidChange(from: previousTraitCollection, to: traitCollection)
    }
}

extension VLCNetworkLoginViewController {
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        PresentationTheme.traitCollectionDidChange(from: previousTraitCollection, to: traitCollection)
    }
}

extension UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
    }

    @objc func themeDidChange() {
        if #available(iOS 13.0, *) {
            navigationBar.standardAppearance = AppearanceManager.navigationbarAppearance()
            navigationBar.scrollEdgeAppearance = AppearanceManager.navigationbarAppearance()
        }
        navigationBar.barTintColor = PresentationTheme.current.colors.navigationbarColor
    }
}
