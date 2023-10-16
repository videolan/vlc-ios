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

protocol ActionSheetSpecifierDelegate: AnyObject {
    func actionSheetSpecifierHandleToggleSwitch(for cell: ActionSheetCell, state: Bool)
}

class ActionSheetSpecifier: NSObject {

    var settingsBundle = Bundle()
    var playbackTitle: String?
    private let userDefaults = UserDefaults.standard
    private var settingSpecifier: SettingSpecifier?
    weak var delegate: ActionSheetSpecifierDelegate?
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

        guard preferenceKey != kVLCSettingAppTheme ||
                (!PresentationTheme.current.isDark || indexPath.row != numberOfRows() - 1) else {
            // Disable the selection for the black background option cell in the appearance action sheet
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
        if let title = playbackTitle {
            return settingsBundle.localizedString(forKey: title, value: title, table: "Root")
        }
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
            let isThemeDark: Bool = PresentationTheme.current.isDark
            if #available(iOS 13, *) {
                return isThemeDark ? rowCount : rowCount - 1
            } else {
                return isThemeDark ? rowCount - 1 : rowCount - 2
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

        if preferenceKey == kVLCSettingAppTheme &&
            PresentationTheme.current.isDark && indexPath.row == numberOfRows() - 1 {
            // Update the black background option cell
            cell.setAccessoryType(to: .toggleSwitch)
            cell.setToggleSwitch(state: UserDefaults.standard.bool(forKey: kVLCSettingAppThemeBlack))
            cell.name.text = settingsBundle.localizedString(forKey: "SETTINGS_THEME_BLACK", value: "", table: "Root")
            let cellIdentifier = ActionSheetCellIdentifier.blackBackground
            cell.identifier = cellIdentifier
            cell.name.accessibilityLabel = cellIdentifier.description
            cell.name.accessibilityHint = cellIdentifier.accessibilityHint
            cell.delegate = self
        } else {
            cell.name.text = settingsBundle.localizedString(forKey: itemTitle, value: itemTitle, table: "Root")
        }

        return cell
    }
}

extension ActionSheetSpecifier: ActionSheetCellDelegate {
    func actionSheetCellShouldUpdateColors() -> Bool {
        return true
    }

    func actionSheetCellDidToggleSwitch(for cell: ActionSheetCell, state: Bool) {
        delegate?.actionSheetSpecifierHandleToggleSwitch(for: cell, state: state)
    }
}
