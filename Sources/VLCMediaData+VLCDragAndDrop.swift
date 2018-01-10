/*****************************************************************************
 * VLCMediaData+VLCDragAndDrop.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@available(iOS 11.0, *)
extension VLCMediaDataSource: VLCDragAndDropManagerDelegate {
    func dragAndDropManagerRequestsFile(manager: VLCDragAndDropManager, atIndexPath indexPath: IndexPath) -> AnyObject? {
        if !(indexPath.row < numberOfFiles()) {
            return nil
        }
        return object(at: UInt(indexPath.row))
    }

    func dragAndDropManagerInsertItem(manager: VLCDragAndDropManager, item: NSManagedObject, atIndexPath indexPath: IndexPath) {
        if item as? MLLabel != nil && indexPath.row < numberOfFiles() {
            removeObject(at: UInt(indexPath.row))
        }
        insert(item, at: UInt(indexPath.row))
    }

    func dragAndDropManagerDeleteItem(manager: VLCDragAndDropManager, atIndexPath indexPath: IndexPath) {
        if !(indexPath.row < numberOfFiles()) {
            return
        }
        removeObject(at: UInt(indexPath.row))
    }

    func dragAndDropManagerCurrentSelection(manager: VLCDragAndDropManager) -> AnyObject? {
        return currentSelection()
    }

    func dragAndDropManagerRemoveFileFromFolder(manager: VLCDragAndDropManager, file: NSManagedObject) {
        return removeMediaObject(fromFolder: file)
    }
}
