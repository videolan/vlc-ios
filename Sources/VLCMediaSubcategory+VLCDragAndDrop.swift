/*****************************************************************************
 * VLCMediaSubcategory+VLCDragAndDrop.swift
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

//@available(iOS 11.0, *)
//extension MediaLibraryBaseModel: VLCDragAndDropManagerDelegate {
//
//    func dragAndDropManagerRequestsFile(manager: NSObject, atIndexPath indexPath: IndexPath) -> Any? {
//        return files[indexPath.row]
//    }
//
//    func dragAndDropManagerInsertItem(manager: NSObject, item: NSManagedObject, atIndexPath indexPath: IndexPath) {
//        if item as? MLLabel != nil && indexPath.row < files.count {
//            files.remove(at: indexPath.row)
//        }
//        // TODO: handle insertion
//        //files.insert(item, at: indexPath.row)
//    }
//
//    func dragAndDropManagerDeleteItem(manager: NSObject, atIndexPath indexPath: IndexPath) {
//        files.remove(at: indexPath.row)
//    }
//
//    func dragAndDropManagerCurrentSelection(manager: NSObject) -> AnyObject? {
//
//        //TODO: Handle playlists and Collections
//        fatalError()
//    }
//
//    func dragAndDropManagerRemoveFileFromFolder(manager: NSObject, file: NSManagedObject) {
//        //TODO: handle removing from playlists and Collections
//        fatalError()
//    }
//}
