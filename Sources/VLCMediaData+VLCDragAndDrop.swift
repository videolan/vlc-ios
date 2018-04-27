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
        return object(at: indexPath.row, subcategory: manager.mediaType.subcategory)
    }

    func dragAndDropManagerInsertItem(manager: VLCDragAndDropManager, item: NSManagedObject, atIndexPath indexPath: IndexPath) {
        if item as? MLLabel != nil && indexPath.row < numberOfFiles(subcategory: manager.mediaType.subcategory) {
            removeObject(at: indexPath.row, subcategory: manager.mediaType.subcategory)
        }
        insert(item as! MLFile, at: indexPath.row, subcategory: manager.mediaType.subcategory)

    }

    func dragAndDropManagerDeleteItem(manager: VLCDragAndDropManager, atIndexPath indexPath: IndexPath) {
        return removeObject(at: indexPath.row, subcategory: manager.mediaType.subcategory)
    }

    func dragAndDropManagerCurrentSelection(manager: VLCDragAndDropManager) -> AnyObject? {

        //  TODO: Handle playlists and Collections
        fatalError()
    }

    func dragAndDropManagerRemoveFileFromFolder(manager: VLCDragAndDropManager, file: NSManagedObject) {
        // TODO: handle removing from playlists and Collections
        fatalError()
    }
}
