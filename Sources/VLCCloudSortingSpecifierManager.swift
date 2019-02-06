/*****************************************************************************
 * VLCCloudSortingSpecifierManager.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2018 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Zhizhang Deng <andy@dzz007.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class VLCCloudSortingSpecifierManager: NSObject {
    @objc weak var controller: VLCCloudStorageTableViewController?
    
    var items: NSArray {
        let items: NSArray = [NSLocalizedString("NAME", comment: ""),
            NSLocalizedString("MODIFIED_DATE", comment: "")]
        return items
    }
    
    var index = Int()
    
    @objc var selectedIndex: IndexPath {
        return IndexPath(row: index, section: 0)
    }
    
    @objc override init() {
        index = 0
        super.init()
    }
}

// MARK: VLCActionSheetDelegate

extension VLCCloudSortingSpecifierManager: VLCActionSheetDelegate {
    
    func headerViewTitle() -> String? {
        return NSLocalizedString("SORT_BY", comment: "")
    }
    
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        return items[indexPath.row]
    }
    
    func actionSheet(collectionView: UICollectionView, didSelectItem item: Any, At indexPath: IndexPath) {
        controller?.controller!.sortBy = VLCCloudSortingCriteria.init(rawValue: items.index(of: item))!
        index = items.index(of: item)
        controller?.requestInformationForCurrentPath()
    }
}

// MARK: VLCActionSheetDataSource

extension VLCCloudSortingSpecifierManager: VLCActionSheetDataSource {
    
    func numberOfRows() -> Int {
        return items.count
    }
    
    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCSettingsSheetCell.identifier, for: indexPath) as? VLCSettingsSheetCell else {
            return UICollectionViewCell()
        }
        
        if indexPath.row < items.count {
            cell.name.text = items[indexPath.row] as? String
        }
        
        return cell
    }
}
