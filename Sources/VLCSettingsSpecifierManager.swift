/*****************************************************************************
 * VLCSettingsSpecifierManager.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2018 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Mike JS. Choi <mkchoi212 # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class VLCSettingsSpecifierManager: NSObject {
    
    @objc var specifier: IASKSpecifier?
    var settingsReader: IASKSettingsReader
    var settingsStore: IASKSettingsStore
    
    var items: NSArray {
        guard let items = specifier?.multipleValues() as NSArray? else {
            assertionFailure("VLCSettingsSpecifierManager: No rows provided for \(specifier?.key() ?? "null specifier")")
            return []
        }
        if specifier?.key() == kVLCSettingAppTheme {
            if #available(iOS 13.0, *) {
                return items
            } else {
                return items.subarray(with: NSRange(location: 0, length: items.count - 1)) as NSArray
            }
        }
        return items
    }
    
    @objc var selectedIndex: IndexPath {
        let index: Int
        if let selectedItem = settingsStore.object(forKey: specifier?.key()) {
            index = items.index(of: selectedItem)
        } else if let specifier = specifier {
            index = items.index(of: specifier.defaultValue() as Any)
        } else {
            fatalError("VLCSettingsSpecifierManager: No specifier provided")
        }
        return IndexPath(row: index, section: 0)
    }
    
    @objc init(settingsReader: IASKSettingsReader, settingsStore: IASKSettingsStore) {
        self.settingsReader = settingsReader
        self.settingsStore = settingsStore
        super.init()
    }
}

// MARK: VLCActionSheetDelegate

extension VLCSettingsSpecifierManager: ActionSheetDelegate {
    
    func headerViewTitle() -> String? {
        return specifier?.title()
    }
    
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        return items[indexPath.row]
    }
    
    func actionSheet(collectionView: UICollectionView, didSelectItem item: Any, At indexPath: IndexPath) {
        settingsStore.setObject(item, forKey: specifier?.key())
        settingsStore.synchronize()
        if specifier?.key() == kVLCSettingAppTheme {
            PresentationTheme.themeDidUpdate()
        }
    }
}

// MARK: VLCActionSheetDataSource

extension VLCSettingsSpecifierManager: ActionSheetDataSource {
    
    func numberOfRows() -> Int {
        return items.count
    }
    
    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActionSheetCell.identifier, for: indexPath) as? ActionSheetCell else {
            return UICollectionViewCell()
        }
        
        if let titles = specifier?.multipleTitles(), indexPath.row < titles.count {
            cell.name.text = settingsReader.title(forId: titles[indexPath.row] as? NSObject)
        }

        return cell
    }
}
