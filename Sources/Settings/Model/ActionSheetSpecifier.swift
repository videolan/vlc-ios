/*****************************************************************************
 * ActionSheetSpecifier.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2020 VideoLAN. All rights reserved.
 *
 * Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class ActionSheetSpecifier: NSObject {

    var settingsBundle = Bundle()
    private let userDefaults = UserDefaults.standard
    private var settingSpecifier: SettingSpecifier?
    var preferenceKey: String? {
        didSet {
            loadData()
        }
    }

    var selectedIndex: IndexPath {
        guard let preferenceKey = preferenceKey else {
            assertionFailure("No Preference Key Provided")
            return IndexPath(row: 0, section: 0)
        }
        guard let row = getSelectedItem(for: preferenceKey) else {
            return IndexPath(row: 0, section: 0)
        }
        return IndexPath(row: row, section: 0)
    }

    private func loadData() {
        guard let preferenceKey = preferenceKey else {
            assertionFailure("No Preference Key Provided")
            return
        }
        settingSpecifier = getSettingsSpecifier(for: preferenceKey)
    }
}

extension ActionSheetSpecifier: ActionSheetDelegate {

    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        settingSpecifier?.specifier[indexPath.row].itemTitle
    }

    func actionSheet(collectionView: UICollectionView, didSelectItem item: Any, At indexPath: IndexPath) {
        guard let preferenceKey = preferenceKey else {
            assertionFailure("No Preference Key Provided")
            return
        }
        userDefaults.set(settingSpecifier?.specifier[indexPath.row].value, forKey: preferenceKey)
        if preferenceKey == kVLCSettingAppTheme {
            PresentationTheme.themeDidUpdate()
        }
        if #available(iOS 10, *) {
            NotificationFeedbackGenerator().success()
        }
    }

    func actionSheetDidFinishClosingAnimation(_ actionSheet: ActionSheet) {
        AppearanceManager.setupUserInterfaceStyle()
    }
}

extension ActionSheetSpecifier: ActionSheetDataSource {

    func headerViewTitle() -> String? {
        guard let title = settingSpecifier?.title else {
            assertionFailure("No Title found for Settings Specifier")
            return nil
        }
        return settingsBundle.localizedString(forKey: title, value: title, table: "Root")
    }

    func numberOfRows() -> Int {
        guard let rowCount = settingSpecifier?.specifier.count else {
            assertionFailure("No Content Found for Specifier \(preferenceKey ?? "Null Specifier")")
            return 0
        }
        if preferenceKey == kVLCSettingAppTheme {

        if #available(iOS 13, *) {
            return rowCount
        }
        else {
            return rowCount - 1
        }
        }
        return rowCount
    }

    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActionSheetCell.identifier, for: indexPath) as? ActionSheetCell
            else {
                return UICollectionViewCell()
        }
        guard let itemTitle = settingSpecifier?.specifier[indexPath.row].itemTitle else {
            return UICollectionViewCell()
        }
        cell.name.text = settingsBundle.localizedString(forKey: itemTitle, value: itemTitle, table: "Root")
        return cell
    }
}
