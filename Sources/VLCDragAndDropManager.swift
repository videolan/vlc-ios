/*****************************************************************************
 * VLCDragAndDropManager.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import MobileCoreServices

@available(iOS 11.0, *)
struct DropError: Error {
    enum ErrorKind {
        case moveFileToDocuments
        case loadFileRepresentationFailed
    }

    let kind: ErrorKind
}
@available(iOS 11.0, *)
@objc protocol VLCDragAndDropManagerDelegate : NSObjectProtocol {
    func dragAndDropManagerRequestsFile(manager:VLCDragAndDropManager, atIndexPath indexPath:IndexPath) -> AnyObject?
    func dragAndDropManagerInsertItem(manager:VLCDragAndDropManager, item:NSManagedObject, atIndexPath indexPath:IndexPath)
    func dragAndDropManagerDeleteItem(manager:VLCDragAndDropManager, atIndexPath indexPath:IndexPath)
    func dragAndDropManagerRemoveFileFromFolder(manager:VLCDragAndDropManager, file:NSManagedObject)
    func dragAndDropManagerCurrentSelection(manager:VLCDragAndDropManager) -> AnyObject?
}

@available(iOS 11.0, *)
class VLCDragAndDropManager: NSObject, UICollectionViewDragDelegate, UITableViewDragDelegate, UICollectionViewDropDelegate, UITableViewDropDelegate, UIDropInteractionDelegate
{
    @objc weak var delegate:VLCDragAndDropManagerDelegate?

    let utiTypeIdentifiers:[String] = VLCDragAndDropManager.supportedTypeIdentifiers()

    /// Returns the supported type identifiers that VLC can process.
    /// It fetches the identifiers in LSItemContentTypes from all the CFBundleDocumentTypes in the info.plist.
    /// Video, Audio and Subtitle formats
    ///
    /// - Returns: Array of UTITypeIdentifiers
    private class func supportedTypeIdentifiers() -> [String] {
        var typeIdentifiers:[String] = []
        if let documents = Bundle.main.infoDictionary?["CFBundleDocumentTypes"] as? [[String:Any]] {
            for item in documents {
                if let value = item["LSItemContentTypes"] as? Array<String> {
                    typeIdentifiers.append(contentsOf: value)
                }
            }
        }
        return typeIdentifiers
    }

    //MARK: - TableView
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return canHandleDropSession(session: session)
    }

    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(forIndexPath:indexPath)
    }

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
         return dragItems(forIndexPath:indexPath)
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        let operation = dropOperation(hasActiveDrag: tableView.hasActiveDrag, firstSessionItem: session.items.first, withDestinationIndexPath: destinationIndexPath)
        return UITableViewDropProposal(operation: operation, intent: .insertIntoDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let section = tableView.numberOfSections - 1
        let row = tableView.numberOfRows(inSection: section)
        let destinationPath = coordinator.destinationIndexPath ?? IndexPath(row: row, section: section)

        for item in coordinator.items {
            let itemProvider = item.dragItem.itemProvider
            //we're not gonna handle moving of folders
            if let sourceItem = item.dragItem.localObject, fileIsCollection(file: sourceItem as AnyObject) {
                continue
            }

            if fileIsFolder(atIndexPath:destinationPath) { //handle dropping onto a folder
                addDragItem(tableView:tableView, dragItem:item, toFolderAt:destinationPath)
                continue
            }

            if item.sourceIndexPath != nil { //element within VLC
                moveItem(tableView:tableView, item:item, toIndexPath:destinationPath)
                continue
            }
            //Element dragging from another App
            let placeholder = UITableViewDropPlaceholder(insertionIndexPath: destinationPath, reuseIdentifier: VLCPlaylistTableViewCell.cellIdentifier(), rowHeight: VLCPlaylistTableViewCell.heightOfCell())
            let placeholderContext = coordinator.drop(item.dragItem, to: placeholder)
            createFileWith(itemProvider:itemProvider) {
                [weak self] file, error in

                guard let strongSelf = self else { return }

                if let file = file {
                    placeholderContext.commitInsertion() {
                        insertionIndexPath in
                        strongSelf.delegate?.dragAndDropManagerInsertItem(manager: strongSelf, item: file, atIndexPath: insertionIndexPath)
                    }
                }
                if let error = error as? DropError {
                    strongSelf.handleError(error: error, itemProvider: item.dragItem.itemProvider)
                    placeholderContext.deletePlaceholder()
                }
            }
        }
    }

    private func inFolder() -> Bool {
        return delegate?.dragAndDropManagerCurrentSelection(manager: self) as? MLLabel != nil
    }

    private func moveItem(tableView:UITableView, item:UITableViewDropItem, toIndexPath destinationPath:IndexPath) {
        if let mlFile = item.dragItem.localObject as? MLFile, mlFile.labels.count > 0 && !inFolder() {
            tableView.performBatchUpdates({
                tableView.insertRows(at: [destinationPath], with: .automatic)
                delegate?.dragAndDropManagerInsertItem(manager: self, item: mlFile, atIndexPath: destinationPath)
                delegate?.dragAndDropManagerRemoveFileFromFolder(manager:self, file:mlFile)
            }, completion:nil)
        }
    }

    private func addDragItem(tableView:UITableView, dragItem item:UITableViewDropItem, toFolderAt index:IndexPath) {
        if let sourcepath = item.sourceIndexPath { //local file that just needs to be moved
            tableView.performBatchUpdates({
                if let file = delegate?.dragAndDropManagerRequestsFile(manager:self, atIndexPath: sourcepath) as? MLFile {
                    tableView.deleteRows(at: [sourcepath], with: .automatic)
                    addFile(file:file, toFolderAt:index)
                    delegate?.dragAndDropManagerDeleteItem(manager: self, atIndexPath:sourcepath)
                }
            }, completion:nil)
            return
        }
        // file from other app
        createFileWith(itemProvider:item.dragItem.itemProvider) {
            [weak self] file, error in

            if let strongSelf = self, let file = file {
                strongSelf.addFile(file:file, toFolderAt:index)
            }
        }
    }

    //MARK: - Collectionview
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return canHandleDropSession(session: session)
    }

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return dragItems(forIndexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(forIndexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let operation = dropOperation(hasActiveDrag: collectionView.hasActiveDrag, firstSessionItem: session.items.first, withDestinationIndexPath: destinationIndexPath)
        return UICollectionViewDropProposal(operation: operation, intent: .insertIntoDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let section = collectionView.numberOfSections - 1
        let row = collectionView.numberOfItems(inSection: section)
        let destinationPath = coordinator.destinationIndexPath ?? IndexPath(row: row, section: section)

        for item in coordinator.items {
            if let sourceItem = item.dragItem.localObject, fileIsCollection(file: sourceItem as AnyObject) { //We're not handling moving of Collection
                continue
            }
            if fileIsFolder(atIndexPath:destinationPath) { //handle dropping onto a folder
                addDragItem(collectionView:collectionView, dragItem:item, toFolderAt:destinationPath)
                continue
            }
            if item.sourceIndexPath != nil { //element within VLC
                moveItem(collectionView:collectionView, item:item, toIndexPath:destinationPath)
                continue
            }
            //Element from another App
            let placeholder = UICollectionViewDropPlaceholder(insertionIndexPath: destinationPath, reuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier())
            let placeholderContext = coordinator.drop(item.dragItem, to: placeholder)
            createFileWith(itemProvider:item.dragItem.itemProvider) {
                [weak self] file, error in

                guard let strongSelf = self else { return }

                if let file = file {
                    placeholderContext.commitInsertion() {
                        insertionIndexPath in
                        strongSelf.delegate?.dragAndDropManagerInsertItem(manager: strongSelf, item: file, atIndexPath: insertionIndexPath)
                    }
                }
                if let error = error as? DropError {
                    strongSelf.handleError(error: error, itemProvider: item.dragItem.itemProvider)
                    placeholderContext.deletePlaceholder()
                }
            }
        }
    }

    private func moveItem(collectionView:UICollectionView, item:UICollectionViewDropItem, toIndexPath destinationPath:IndexPath) {
        if let mlFile = item.dragItem.localObject as? MLFile, mlFile.labels.count > 0 && !inFolder() {
            collectionView.performBatchUpdates({
                collectionView.insertItems(at: [destinationPath])
                delegate?.dragAndDropManagerInsertItem(manager: self, item: mlFile, atIndexPath: destinationPath)
                delegate?.dragAndDropManagerRemoveFileFromFolder(manager:self, file:mlFile)
            }, completion:nil)
        }
    }

    private func addDragItem(collectionView:UICollectionView, dragItem item:UICollectionViewDropItem, toFolderAt index:IndexPath) {
        if let sourcepath = item.sourceIndexPath {
            //local file that just needs to be moved
            collectionView.performBatchUpdates({
                if let file = delegate?.dragAndDropManagerRequestsFile(manager:self, atIndexPath: sourcepath) as? MLFile {
                    collectionView.deleteItems(at:[sourcepath])
                    addFile(file:file, toFolderAt:index)
                    delegate?.dragAndDropManagerDeleteItem(manager: self, atIndexPath:sourcepath)
                }
            }, completion:nil)
        } else {
            // file from other app
            createFileWith(itemProvider:item.dragItem.itemProvider) {
                [weak self] file, error in
                if let strongSelf = self, let file = file {
                    strongSelf.addFile(file:file, toFolderAt:index)
                }
            }
        }
    }

    //MARK: - DropInteractionDelegate for EmptyView

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return canHandleDropSession(session: session)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        for item in session.items {
            createFileWith(itemProvider:item.itemProvider) {
                [weak self] _, error in
                if let error = error as? DropError {
                    self?.handleError(error: error, itemProvider: item.itemProvider)
                }
                //no need to handle the file case since the libraryVC updates itself after getting a file
            }
        }
    }

    //MARK: - Shared Methods
    //Checks if the session has items conforming to typeidentifiers
    private func canHandleDropSession(session:UIDropSession) -> Bool {
        if (session.localDragSession != nil) {
            return true
        }
        return session.hasItemsConforming(toTypeIdentifiers: utiTypeIdentifiers)
    }

    /// Returns a drop operation type
    ///
    /// - Parameters:
    ///   - hasActiveDrag: State if the drag started within the app
    ///   - item: UIDragItem from session
    /// - Returns: UIDropOperation
    private func dropOperation(hasActiveDrag: Bool, firstSessionItem item: AnyObject?, withDestinationIndexPath destinationIndexPath:IndexPath?) -> UIDropOperation {
        let inAlbum = delegate?.dragAndDropManagerCurrentSelection(manager: self) as? MLAlbum != nil
        let inShow = delegate?.dragAndDropManagerCurrentSelection(manager: self) as? MLShow != nil
        //you can move files into a folder or copy from anothr app into a folder
        if fileIsFolder(atIndexPath:destinationIndexPath) {
            //no dragging entire shows and albums into folders
            if let dragItem = item, let mlFile = dragItem.localObject as? MLFile, mlFile.isAlbumTrack() ||  mlFile.isShowEpisode() {
                return .forbidden
            }
            return hasActiveDrag ? .move : .copy
        }
        //you can't reorder
        if inFolder() {
            return hasActiveDrag ? .forbidden : .copy
        }
        //you can't reorder in or drag into an Album or Show
        if inAlbum || inShow {
            return .cancel
        }
        //we're dragging a file out of a folder
        if let dragItem = item, let mlFile = dragItem.localObject as? MLFile, mlFile.labels.count > 0 {
            return .copy
        }
        //no reorder from another app into the top layer
        return hasActiveDrag ? .forbidden : .copy
    }

    /// show an Alert when dropping failed
    ///
    /// - Parameters:
    ///   - error: the type of error that happend
    ///   - itemProvider: the itemProvider to retrieve the suggestedName
    private func handleError(error: DropError, itemProvider: NSItemProvider) {
        let message: String
        let filename = itemProvider.suggestedName ?? NSLocalizedString("THIS_FILE", comment:"")
        switch (error.kind) {
        case .loadFileRepresentationFailed:
            message = String(format: NSLocalizedString("NOT_SUPPORTED_FILETYPE", comment: ""), filename)
        case .moveFileToDocuments:
            message = String(format: NSLocalizedString("FILE_EXISTS", comment: ""), filename)
        }
        let alert = UIAlertController(title: NSLocalizedString("ERROR", comment:""), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:""), style: .default, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    private func fileIsFolder(atIndexPath indexPath:IndexPath?) -> Bool {
        if let indexPath = indexPath {
            let file = delegate?.dragAndDropManagerRequestsFile(manager: self, atIndexPath: indexPath)
            return file as? MLLabel != nil
        }
        return false
    }

    private func fileIsCollection(file:AnyObject?) -> Bool {
        let isFolder = file as? MLLabel != nil
        let isAlbum = file as? MLAlbum != nil
        let isShow = file as? MLShow != nil
        return isFolder || isAlbum || isShow
    }

    private func fileIsCollection(atIndexPath indexPath:IndexPath?) -> Bool {
        if let indexPath = indexPath {
            let file = delegate?.dragAndDropManagerRequestsFile(manager: self, atIndexPath: indexPath)
            return fileIsCollection(file:file)
        }
        return false
    }

    //creating dragItems for the file at indexpath
    private func dragItems(forIndexPath indexPath:IndexPath) -> [UIDragItem] {
        if let file = delegate?.dragAndDropManagerRequestsFile(manager: self, atIndexPath: indexPath) {
            if fileIsCollection(atIndexPath: indexPath) {
                return dragItemsforCollection(file: file)
            }
            return dragItem(fromFile:file)
        }
        assert(false, "we can't generate a dragfile if the delegate can't return a file ")
        return []
    }

    /// Iterates over the items of a collection to create dragitems.
    /// Since we're not storing collections as folders we have to provide single files
    ///
    /// - Parameter file: Can be of type MLAlbum, MLLabel or MLShow
    /// - Returns: An array of UIDragItems
    private func dragItemsforCollection(file: AnyObject) -> [UIDragItem] {
        var dragItems = [UIDragItem]()
        var set = Set<AnyHashable>()
        if let folder = file as? MLLabel {
            set = folder.files
        } else if let album = file as? MLAlbum {
            for track in album.tracks {
                if let mlfile = (track as? MLAlbumTrack)?.files.first {
                    _ = set.insert(mlfile)
                }
            }
        } else if let show = file as? MLShow {
            for episode in show.episodes {
                if let mlfile = (episode as? MLShowEpisode)?.files {
                    set = set.union(mlfile)
                }
            }
        } else {
            assert(false, "can't get dragitems from a file that is not a collection")
        }
        for convertibleFile in set {
            if let mlfile = convertibleFile as? MLFile, let item = dragItem(fromFile:mlfile).first {
                dragItems.append(item)
            }
        }
        return dragItems
    }

    //Provides an item for other applications
    private func dragItem(fromFile file:AnyObject) -> [UIDragItem] {
        guard let file = mlFile(from: file), let path = file.url else {
            assert(false, "can't create a dragitem if there is no file or the file has no url")
            return []
        }

        let data = try? Data(contentsOf: path, options: .mappedIfSafe)
        let itemProvider = NSItemProvider()
        itemProvider.suggestedName = path.lastPathComponent
        //maybe use UTTypeForFileURL
        if let identifiers = try? path.resourceValues(forKeys: [.typeIdentifierKey]), let identifier = identifiers.typeIdentifier {
            //here we can show progress
            itemProvider.registerDataRepresentation(forTypeIdentifier: identifier, visibility: .all) { completion -> Progress? in
                completion(data, nil)
                return nil
            }
            let dragitem = UIDragItem(itemProvider: itemProvider)
            dragitem.localObject = file
            return [dragitem]
        }
        assert(false, "we can't provide a typeidentifier")
        return []
    }

    private func mlFile(from file:AnyObject) -> MLFile? {
        if let episode = file as? MLShowEpisode, let convertedfile = episode.files.first as? MLFile{
            return convertedfile
        }

        if let track = file as? MLAlbumTrack, let convertedfile = track.files.first as? MLFile{
            return convertedfile
        }

        if let convertedfile = file as? MLFile {
            return convertedfile
        }
        return nil
    }

    private func addFile(file:MLFile, toFolderAt folderIndex:IndexPath) {
        let label = delegate?.dragAndDropManagerRequestsFile(manager: self, atIndexPath: folderIndex) as! MLLabel
        DispatchQueue.main.async {
            _ = label.files.insert(file)
            file.labels = [label]
            file.folderTrackNumber = NSNumber(integerLiteral: label.files.count - 1)
        }
    }

    /// try to create a file from the dropped item
    ///
    /// - Parameters:
    ///   - itemProvider: itemprovider which is used to load the files from
    ///   - completion: callback with the successfully created file or error if it failed
    private func createFileWith(itemProvider:NSItemProvider, completion: @escaping ((MLFile?, Error?) -> Void))
    {
        itemProvider.loadFileRepresentation(forTypeIdentifier: kUTTypeData as String) {
            [weak self] (url, error) in
            guard let strongSelf = self else { return }

            guard let url = url else {
                DispatchQueue.main.async {
                    completion(nil, DropError(kind: .loadFileRepresentationFailed))
                }
                return
            }
            //returns nil for local session but this should also not be called for a local session
            guard let destinationURL = strongSelf.moveFileToDocuments(fromURL: url) else {
                DispatchQueue.main.async {
                    completion(nil, DropError(kind: .moveFileToDocuments))
                }
                return
            }
            DispatchQueue.global(qos: .background).async {
                let sharedlib = MLMediaLibrary.sharedMediaLibrary() as? MLMediaLibrary
                sharedlib?.addFilePaths([destinationURL.path])

                if let file = MLFile.file(for: destinationURL).first as? MLFile {
                    DispatchQueue.main.async {
                        //we dragged into a folder
                        if let selection = strongSelf.delegate?.dragAndDropManagerCurrentSelection(manager: strongSelf) as? MLLabel {
                            file.labels = [selection]
                        }
                        completion(file, nil)
                    }
                }
            }
        }
    }

    private func moveFileToDocuments(fromURL filepath:URL?) -> URL? {
        let searchPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let newDirectoryPath = searchPaths.first
        guard let directoryPath = newDirectoryPath, let url = filepath else {
            return nil
        }
        let destinationURL = URL(fileURLWithPath: "\(directoryPath)" + "/" + "\(url.lastPathComponent)")
        do {
            try FileManager.default.moveItem(at: url, to: destinationURL)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
        return destinationURL
    }
}
