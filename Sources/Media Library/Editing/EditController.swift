/*****************************************************************************
 * EditController.swift
 *
 * Copyright © 2018-2026 VLC authors and VideoLAN
 * Copyright © 2018-2026 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol EditControllerDelegate: AnyObject {
    func editControllerDidSelectMultipleItem(editContrller: EditController)
    func editControllerDidDeSelectMultipleItem()
    func editControllerDidFinishEditing(editController: EditController?)
    func editControllerGetCurrentThumbnail() -> UIImage?
    func editControllerGetArtworkHeaderSize(with width: CGFloat) -> CGSize
    func editControllerGetTitleSections() -> MediaTitleSections?
    func editControllerSetNavigationItemTitle(with title: String?)
    func editControllerUpdateIsAllSelected(with allSelected: Bool)
}

class EditController: UIViewController {
    // Cache selectedIndexPath separately to indexPathsForSelectedItems in order to have persistance
    private var selectedItems = [IndexPath: VLCMLObject]()
    private let model: MediaLibraryBaseModel
    private let presentingView: UICollectionView
    private let searchDataSource: LibrarySearchDataSource
    private(set) var editActions: EditActions
    private var isAllSelected: Bool = false
    private var currentDataSet: [VLCMLObject] {
        if let model = model as? FolderModel {
            model.fileArrayLock.lock()
            defer { model.fileArrayLock.unlock() }
            return model.files + model.folderMediaFiles
        } else {
            return searchDataSource.isSearching ? searchDataSource.searchData : model.anyfiles
        }
    }

    private var titleSections: MediaTitleSections? {
        return delegate?.editControllerGetTitleSections()
    }

    weak var delegate: EditControllerDelegate?

    init(mediaLibraryService: MediaLibraryService,
         model: MediaLibraryBaseModel,
         presentingView: UICollectionView,
         searchDataSource: LibrarySearchDataSource) {
        self.model = model
        self.presentingView = presentingView
        self.editActions = EditActions(model: model, mediaLibraryService: mediaLibraryService)
        self.searchDataSource = searchDataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resetSelections(resetUI: Bool) {
        for indexPath in selectedItems.keys {
            presentingView.deselectItem(at: indexPath, animated: true)
            if resetUI {
                collectionView(presentingView, didDeselectItemAt: indexPath)
            }
        }
        selectedItems.removeAll()
        isAllSelected = false
    }

    func updateSelections() {
        guard !selectedItems.isEmpty else {
            return
        }

        let layout = currentLayout()
        var updatedItems = [IndexPath: VLCMLObject]()
        for object in selectedItems.values {
            if let entry = layout[ObjectIdentifier(type(of: object))]?[object.identifier()] {
                updatedItems[entry.indexPath] = entry.object
            }
        }
        selectedItems = updatedItems

        for indexPath in presentingView.indexPathsForSelectedItems ?? [] where updatedItems[indexPath] == nil {
            presentingView.deselectItem(at: indexPath, animated: false)
        }
        for indexPath in updatedItems.keys {
            presentingView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }

        let allSelected = !updatedItems.isEmpty && updatedItems.count == currentDataSet.count
        if allSelected != isAllSelected {
            isAllSelected = allSelected
            delegate?.editControllerUpdateIsAllSelected(with: allSelected)
        }

        if updatedItems.isEmpty {
            delegate?.editControllerDidDeSelectMultipleItem()
            delegate?.editControllerSetNavigationItemTitle(with: nil)
        } else {
            delegate?.editControllerDidSelectMultipleItem(editContrller: self)
            delegate?.editControllerSetNavigationItemTitle(with: getTitle(for: updatedItems.count))
        }
    }

    func shouldResetCells(_ reset: Bool) {
        guard reset else {
            return
        }

        (0..<presentingView.numberOfSections).compactMap {
            section -> [IndexPath]? in
            return (0..<presentingView.numberOfItems(inSection: section)).compactMap({
                item -> IndexPath? in
                return IndexPath(item: item, section: section)
            })}
        .flatMap { $0 }.forEach { (indexPath) in
            if let cell = presentingView.cellForItem(at: indexPath) as? MediaCollectionViewCell {
                cell.showCheckmark(false)
            }
        }
    }

    func selectAll() {
        isAllSelected = !isAllSelected
        if isAllSelected {
            (0..<presentingView.numberOfSections).compactMap {
                section -> [IndexPath]? in
                return (0..<presentingView.numberOfItems(inSection: section)).compactMap({
                    item -> IndexPath? in
                    return IndexPath(item: item, section: section)
                })}
            .flatMap { $0 }.forEach { (indexPath) in
                collectionView(presentingView, didSelectItemAt: indexPath)
            }
        } else {
            resetSelections(resetUI: true)
        }
    }
}

// MARK: - Helpers

private extension EditController {
    private func getObject(at indexPath: IndexPath) -> VLCMLObject? {
        if let titleSections {
            return titleSections.media(at: indexPath)
        }
        return currentDataSet.objectAtIndex(index: indexPath.row)
    }

    private func currentLayout() -> [ObjectIdentifier: [VLCMLIdentifier: (indexPath: IndexPath, object: VLCMLObject)]] {
        var layout = [ObjectIdentifier: [VLCMLIdentifier: (indexPath: IndexPath, object: VLCMLObject)]]()
        if let titleSections {
            for (section, entry) in titleSections.sections.enumerated() {
                for (row, media) in entry.items.enumerated() {
                    layout[ObjectIdentifier(type(of: media)), default: [:]][media.identifier()] = (IndexPath(row: row, section: section), media)
                }
            }
        } else {
            for (row, object) in currentDataSet.enumerated() {
                layout[ObjectIdentifier(type(of: object)), default: [:]][object.identifier()] = (IndexPath(row: row, section: 0), object)
            }
        }
        return layout
    }

    private var canReorder: Bool {
        guard let collectionModel = model as? CollectionModel else {
            return false
        }

        return collectionModel.mediaCollection is VLCMLPlaylist
            && collectionModel.sortModel.currentSort == .default
            && !searchDataSource.isSearching
    }

    private func order(moving movingRows: [Int], draggedFrom source: Int, to destination: Int) -> [Int] {
        let itemCount = currentDataSet.count
        let moving = Set(movingRows)
        let remainingRows = (0..<itemCount).filter({ !moving.contains($0) })
        let rowsWithoutDragged = (0..<itemCount).filter({ $0 != source })

        var insertionIndex = remainingRows.count
        if destination < rowsWithoutDragged.count {
            let anchor = rowsWithoutDragged[destination]
            insertionIndex = remainingRows.firstIndex(where: { $0 >= anchor }) ?? remainingRows.count
        }

        var newOrder = remainingRows
        newOrder.insert(contentsOf: movingRows, at: insertionIndex)
        return newOrder
    }

    private func dragPreviewParameters() -> UIDragPreviewParameters {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = PresentationTheme.current.colors.background
        return parameters
    }

    private func getTitle(for count: Int) -> String {
        var title = "\(count) "
        if count == 1 {
            title += NSLocalizedString("SINGLE_ITEM_SELECTED", comment: "")
        } else {
            title += NSLocalizedString("MULTIPLE_ITEMS_SELECTED", comment: "")
        }

        return title
    }
}

// MARK: - VLCEditToolbarDelegate

extension EditController: EditToolbarDelegate {
    private func getSelectedObjects(keepPlaylists: Bool = false) {
        for object in selectedItems.sorted(by: { $0.key < $1.key }).map({ $0.value }) {
            if keepPlaylists, let playlist = object as? VLCMLPlaylist {
                editActions.objects.append(playlist)
            } else if let folder = object as? VLCMLFolder {
                editActions.objects += folder.allMedia()
            } else if let mediaCollection = object as? MediaCollectionModel {
                guard let files = mediaCollection.files() else {
                    assertionFailure("EditController: Fail to retrieve tracks.")
                    DispatchQueue.main.async {
                        VLCAlertViewController.alertViewManager(title: NSLocalizedString("ERROR_PLAYLIST_TRACKS",
                                                                    comment: ""),
                                                                viewController: self)
                    }
                    return
                }
                editActions.objects += files
            } else {
                editActions.objects.append(object)
            }
        }
    }

    func editToolbarDidAddToPlaylist(_ editToolbar: EditToolbar) {
        guard !selectedItems.isEmpty else {
            return
        }
        editActions.objects.removeAll()
        getSelectedObjects()
        editActions.addToPlaylist({
            [weak self] state in
            if state == .success || state == .fail {
                self?.resetSelections(resetUI: false)
                self?.delegate?.editControllerSetNavigationItemTitle(with: nil)
                self?.delegate?.editControllerDidDeSelectMultipleItem()
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        })
    }

    func editToolbarDidAddToMediaGroup(_ editToolbar: EditToolbar) {
        guard !selectedItems.isEmpty else {
            return
        }
        editActions.objects.removeAll()

        for object in selectedItems.values {
            editActions.objects.append(object)
        }

        editActions.addToMediaGroup() {
            [weak self] state in
            if state == .success || state == .fail {
                self?.resetSelections(resetUI: false)
                self?.delegate?.editControllerSetNavigationItemTitle(with: nil)
                self?.delegate?.editControllerDidDeSelectMultipleItem()
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        }
    }

    func editToolbarDidRemoveFromMediaGroup(_ editToolbar: EditToolbar) {
        guard !selectedItems.isEmpty else {
            return
        }

        editActions.objects.removeAll()
        getSelectedObjects()

        editActions.removeFromMediaGroup() {
            [weak self] state in
            if state == .success || state == .fail {
                self?.resetSelections(resetUI: false)
                self?.delegate?.editControllerSetNavigationItemTitle(with: nil)
                self?.delegate?.editControllerDidDeSelectMultipleItem()
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        }
    }

    func editToolbarDidDelete(_ editToolbar: EditToolbar) {
        guard !selectedItems.isEmpty else {
            return
        }
        
        editActions.objects.removeAll()
        
        for object in selectedItems.sorted(by: { $0.key > $1.key }).map({ $0.value }) {
            editActions.objects.append(object)
        }
        let deletedObjects = editActions.objects

        editActions.delete({
            [weak self] state in
            if state == .success || state == .fail {
                self?.searchDataSource.deleteInSearch(deletedObjects)
                self?.resetSelections(resetUI: false)
                self?.delegate?.editControllerSetNavigationItemTitle(with: nil)
                self?.delegate?.editControllerDidDeSelectMultipleItem()
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        })
    }

    func editToolbarDidShare(_ editToolbar: EditToolbar) {
        guard !selectedItems.isEmpty else {
            return
        }
        editActions.objects.removeAll()
        getSelectedObjects(keepPlaylists: true)
        editActions.share(origin: editToolbar.shareButton, {
            [weak self] state in
            if state == .success || state == .fail {
                self?.resetSelections(resetUI: false)
                self?.delegate?.editControllerSetNavigationItemTitle(with: nil)
                self?.delegate?.editControllerDidDeSelectMultipleItem()
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        })
    }

    func editToolbarDidRename(_ editToolbar: EditToolbar) {
        guard !selectedItems.isEmpty else {
            return
        }
        
        editActions.objects.removeAll()

        for object in selectedItems.sorted(by: { $0.key > $1.key }).map({ $0.value })
        where !(object is VLCMLFolder) {
            editActions.objects.append(object)
        }

        editActions.rename({
            [weak self] state in
            if state == .success || state == .fail {
                self?.resetSelections(resetUI: true)
                self?.delegate?.editControllerSetNavigationItemTitle(with: nil)
                self?.delegate?.editControllerDidDeSelectMultipleItem()
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        })
    }

    func editToolbarEmptySelection(_ editToolbar: EditToolbar) -> Bool {
        return selectedItems.isEmpty
    }

    func editToolbarCanRename(_ editToolbar: EditToolbar) -> Bool {
        guard model is FolderModel else {
            return true
        }

        let dataSet = currentDataSet
        return !selectedCellIndexPaths.contains { $0.row < dataSet.count && dataSet[$0.row] is VLCMLFolder }
    }
}

// MARK: - UICollectionViewDelegate

extension EditController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedItems[indexPath] = getObject(at: indexPath)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)

        if !selectedItems.isEmpty {
            delegate?.editControllerDidSelectMultipleItem(editContrller: self)
        }
        // Isolate selectionViewOverlay changes inside EditController
        var showOverlay: Bool = true

        if collectionView.cellForItem(at: indexPath) is MediaCollectionViewCell {
            showOverlay = false
        }

        if let cell = collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell {
            cell.selectionViewOverlay?.isHidden = !showOverlay
        }
        
        if currentDataSet.count == selectedItems.count {
            isAllSelected = true
            delegate?.editControllerUpdateIsAllSelected(with: true)
        }

        let title = getTitle(for: selectedItems.count)
        delegate?.editControllerSetNavigationItemTitle(with: title)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedItems[indexPath] = nil
        collectionView.deselectItem(at: indexPath, animated: false)

        if selectedItems.isEmpty {
            delegate?.editControllerDidDeSelectMultipleItem()
        } else {
            delegate?.editControllerDidSelectMultipleItem(editContrller: self)
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell {
            cell.selectionViewOverlay?.isHidden = true
        }

        let title: String?

        if selectedItems.isEmpty {
            title = nil
        } else {
            title = getTitle(for: selectedItems.count)
        }

        if isAllSelected {
            isAllSelected = false
            delegate?.editControllerUpdateIsAllSelected(with: false)
        }

        delegate?.editControllerSetNavigationItemTitle(with: title)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if titleSections != nil {
            return .init(width: collectionView.safeAreaLayoutGuide.layoutFrame.width, height: 40)
        }

        guard let model = model as? CollectionModel else {
            return .init(width: 0, height: 0)
        }

        if model.mediaCollection is VLCMLAlbum || model.mediaCollection is VLCMLPlaylist,
           let size = delegate?.editControllerGetArtworkHeaderSize(with: collectionView.frame.size.width) {
            return size
        } else {
            return .init(width: 0, height: 0)
        }
    }
}

// MARK: - UICollectdiionViewDataSource

extension EditController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return titleSections?.sections.count ?? 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let titleSections {
            return titleSections.sections[section].items.count
        }
        return currentDataSet.count
    }

    func indexTitles(for collectionView: UICollectionView) -> [String]? {
        return titleSections?.titles
    }

    func collectionView(_ collectionView: UICollectionView, indexPathForIndexTitle title: String, at index: Int) -> IndexPath {
        return IndexPath(item: 0, section: index)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: model.cellType.defaultReuseIdentifier,
                                                         for: indexPath) as? BaseCollectionViewCell {
            cell.isSelected = selectedItems[indexPath] != nil
            cell.isAccessibilityElement = true
            cell.checkImageView?.isHidden = false

            var showOverlay: Bool = true

            if let cell = cell as? MediaCollectionViewCell {
                cell.showCheckmark(true)
                cell.disableScrollView()
                if canReorder {
                    cell.dragIndicatorImageView.isHidden = false
                } else if cell.media is VLCMLMediaGroup || cell.media is VLCMLPlaylist {
                    cell.dragIndicatorImageView.isHidden = true
                }
                cell.isEditing = true
                showOverlay = false
            }
            if cell.media is VLCMLMedia || cell.media is VLCMLMediaGroup {
                cell.secondDescriptionLabelView?.isHidden = false
                cell.descriptionSeparatorLabel?.isHidden = false
            }

            if cell.isSelected {
                cell.selectionViewOverlay?.isHidden = !showOverlay
            }
            cell.media = getObject(at: indexPath)
            return cell
        } else {
            assertionFailure("We couldn't dequeue a reusable cell, the cell might not be registered or is not a MediaEditCell")
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        if let collectionModel = model as? CollectionModel,
           collectionModel.mediaCollection is VLCMLAlbum || collectionModel.mediaCollection is VLCMLPlaylist,
           let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionArtworkHeader.headerID, for: indexPath) as? CollectionArtworkHeader {
            header.updateImage(with: delegate?.editControllerGetCurrentThumbnail(),
                               placeholderName: collectionModel.mediaCollection.placeholderName())
            header.shouldDisablePlayButtons(true)
            return header
        }

        if let titleSections,
           let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrackSectionHeader.headerID, for: indexPath) as? TrackSectionHeader {
            header.update(sectionTitle: titleSections.sections[indexPath.section].key)
            return header
        }

        return UICollectionReusableView()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let delegate = delegate as? MediaCategoryViewController {
            delegate.scrollViewDidScroll(scrollView)
        }
    }
}

// MARK: - UICollectionViewDragDelegate

extension EditController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        guard canReorder,
              collectionView.indexPathForItem(at: session.location(in: collectionView)) == indexPath else {
            return []
        }

        return [UIDragItem(itemProvider: NSItemProvider())]
    }

    func collectionView(_ collectionView: UICollectionView,
                        dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView,
                        dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return dragPreviewParameters()
    }
}

// MARK: - UICollectionViewDropDelegate

extension EditController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.localDragSession != nil
    }

    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard collectionView.hasActiveDrag, canReorder else {
            return UICollectionViewDropProposal(operation: .cancel)
        }

        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let collectionModel = model as? CollectionModel,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else {
            return
        }

        let itemCount = currentDataSet.count
        let section = sourceIndexPath.section
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: itemCount - 1, section: section)

        var movingRows = [sourceIndexPath.row]
        if selectedItems[sourceIndexPath] != nil {
            movingRows = selectedItems.keys.map({ $0.row }).filter({ $0 < itemCount }).sorted()
        }

        let newOrder = order(moving: movingRows, draggedFrom: sourceIndexPath.row, to: destinationIndexPath.row)
        var newRows = Array(repeating: 0, count: itemCount)
        for (newRow, row) in newOrder.enumerated() {
            newRows[row] = newRow
        }

        collectionView.performBatchUpdates({
            collectionModel.reorderFiles(to: newOrder)
            for row in movingRows {
                collectionView.moveItem(at: IndexPath(row: row, section: section),
                                        to: IndexPath(row: newRows[row], section: section))
            }
        })

        selectedItems = Dictionary(uniqueKeysWithValues: selectedItems.filter({ $0.key.row < itemCount }).map({
            (IndexPath(row: newRows[$0.key.row], section: $0.key.section), $0.value)
        }))

        coordinator.drop(item.dragItem, toItemAt: IndexPath(row: newRows[sourceIndexPath.row], section: section))
    }

    func collectionView(_ collectionView: UICollectionView,
                        dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return dragPreviewParameters()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension EditController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        model.cellType.cellSizeForWidth(collectionView.safeAreaLayoutGuide.layoutFrame.width,
                                        safeAreaInsets: collectionView.safeAreaInsets)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: model.cellType.edgePadding,
                            left: model.cellType.edgePadding,
                            bottom: model.cellType.edgePadding,
                            right: model.cellType.edgePadding)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return model.cellType.edgePadding
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return model.cellType.interItemPadding
    }
}

