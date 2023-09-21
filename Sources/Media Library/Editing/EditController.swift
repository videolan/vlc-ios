/*****************************************************************************
 * EditController.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol EditControllerDelegate: AnyObject {
    func editController(editController: EditController, cellforItemAt indexPath: IndexPath) -> BaseCollectionViewCell?
    func editController(editController: EditController, present viewController: UIViewController)
    func editControllerDidSelectMultipleItem(editContrller: EditController)
    func editControllerDidDeSelectMultipleItem()
    func editControllerDidFinishEditing(editController: EditController?)
    func editControllerGetCurrentThumbnail() -> UIImage?
    func editControllerGetAlbumHeaderSize(with width: CGFloat) -> CGSize
    func editControllerUpdateNavigationBar(offset: CGFloat)
    func editControllerSetNavigationItemTitle(with title: String?)
    func editControllerUpdateIsAllSelected(with allSelected: Bool)
}

class EditController: UIViewController {
    // Cache selectedIndexPath separately to indexPathsForSelectedItems in order to have persistance
    private var selectedCellIndexPaths = Set<IndexPath>()
    private let model: MediaLibraryBaseModel
    private let mediaLibraryService: MediaLibraryService
    private let presentingView: UICollectionView
    private let searchDataSource: LibrarySearchDataSource
    private(set) var editActions: EditActions
    private var isAllSelected: Bool = false
    private var currentDataSet: [VLCMLObject] {
        return searchDataSource.isSearching ? searchDataSource.searchData : model.anyfiles
    }

    weak var delegate: EditControllerDelegate?

    init(mediaLibraryService: MediaLibraryService,
         model: MediaLibraryBaseModel,
         presentingView: UICollectionView, searchDataSource: LibrarySearchDataSource) {
        self.mediaLibraryService = mediaLibraryService
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
        for indexPath in selectedCellIndexPaths {
            presentingView.deselectItem(at: indexPath, animated: true)
            if resetUI {
                collectionView(presentingView, didDeselectItemAt: indexPath)
            }
        }
        selectedCellIndexPaths.removeAll()
        isAllSelected = false
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
    private struct TextFieldAlertInfo {
        var alertTitle: String
        var alertDescription: String
        var placeHolder: String
        var textfieldText: String
        var confirmActionTitle: String

        init(alertTitle: String = "",
             alertDescription: String = "",
             placeHolder: String = "",
             textfieldText: String = "",
             confirmActionTitle: String = NSLocalizedString("BUTTON_DONE", comment: "")) {
            self.alertTitle = alertTitle
            self.alertDescription = alertDescription
            self.placeHolder = placeHolder
            self.textfieldText = textfieldText
            self.confirmActionTitle = confirmActionTitle
        }
    }

    private func presentTextFieldAlert(with info: TextFieldAlertInfo,
                                       completionHandler: @escaping (String) -> Void) {
        let alertController = UIAlertController(title: info.alertTitle,
                                                message: info.alertDescription,
                                                preferredStyle: .alert)

        alertController.addTextField(configurationHandler: {
            textField in
            textField.text = info.textfieldText
            textField.placeholder = info.placeHolder
        })

        let cancelButton = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                         style: .cancel)


        let confirmAction = UIAlertAction(title: info.confirmActionTitle, style: .default) {
            [weak alertController] _ in
            guard let alertController = alertController,
                let textField = alertController.textFields?.first else { return }
            completionHandler(textField.text ?? "")
        }

        alertController.addAction(cancelButton)
        alertController.addAction(confirmAction)

        present(alertController, animated: true, completion: nil)
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
    private func getSelectedObjects() {
        for index in selectedCellIndexPaths where index.row < currentDataSet.count {
            if let mediaCollection = currentDataSet[index.row] as? MediaCollectionModel {
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
                editActions.objects.append(currentDataSet[index.row])
            }
        }
    }

    func editToolbarDidAddToPlaylist(_ editToolbar: EditToolbar) {
        guard !selectedCellIndexPaths.isEmpty else {
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
        guard !selectedCellIndexPaths.isEmpty else {
            return
        }
        editActions.objects.removeAll()

        for index in selectedCellIndexPaths where index.row < currentDataSet.count {
            editActions.objects.append(currentDataSet[index.row])
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
        guard !selectedCellIndexPaths.isEmpty else {
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
        guard !selectedCellIndexPaths.isEmpty else {
            return
        }
        
        editActions.objects.removeAll()
        
        for indexPath in selectedCellIndexPaths.sorted(by: { $0 > $1 }) {
            editActions.objects.append(currentDataSet[indexPath.row])
        }

        editActions.delete({
            [weak self] state in
            if state == .success || state == .fail {
                self?.searchDataSource.deleteInSearch(indexes: self?.selectedCellIndexPaths)
                self?.resetSelections(resetUI: false)
                self?.delegate?.editControllerSetNavigationItemTitle(with: nil)
                self?.delegate?.editControllerDidDeSelectMultipleItem()
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        })
    }

    func editToolbarDidShare(_ editToolbar: EditToolbar) {
        guard !selectedCellIndexPaths.isEmpty else {
            return
        }
        editActions.objects.removeAll()
        getSelectedObjects()
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
        guard !selectedCellIndexPaths.isEmpty else {
            return
        }
        
        editActions.objects.removeAll()
        
        for indexPath in selectedCellIndexPaths.sorted(by: { $0 > $1 }) {
            editActions.objects.append(currentDataSet[indexPath.row])
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
}

// MARK: - UICollectionViewDelegate

extension EditController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCellIndexPaths.insert(indexPath)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)

        if !selectedCellIndexPaths.isEmpty {
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
        
        if currentDataSet.count == selectedCellIndexPaths.count {
            isAllSelected = true
            delegate?.editControllerUpdateIsAllSelected(with: true)
        }

        let title = getTitle(for: selectedCellIndexPaths.count)
        delegate?.editControllerSetNavigationItemTitle(with: title)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedCellIndexPaths.remove(indexPath)
        collectionView.deselectItem(at: indexPath, animated: false)

        if selectedCellIndexPaths.isEmpty {
            delegate?.editControllerDidDeSelectMultipleItem()
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell {
            cell.selectionViewOverlay?.isHidden = true
        }

        let title: String?

        if selectedCellIndexPaths.isEmpty {
            title = nil
        } else {
            title = getTitle(for: selectedCellIndexPaths.count)
        }

        if isAllSelected {
            isAllSelected = false
            delegate?.editControllerUpdateIsAllSelected(with: false)
        }

        delegate?.editControllerSetNavigationItemTitle(with: title)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let model = model as? CollectionModel,
              model.mediaCollection is VLCMLAlbum,
              let size = delegate?.editControllerGetAlbumHeaderSize(with: collectionView.frame.size.width) else {
            return .init(width: 0, height: 0)
        }

        return size
    }
}

// MARK: - UICollectdiionViewDataSource

extension EditController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentDataSet.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: model.cellType.defaultReuseIdentifier,
                                                         for: indexPath) as? BaseCollectionViewCell {
            cell.isSelected = selectedCellIndexPaths.contains(indexPath)
            cell.isAccessibilityElement = true
            cell.checkImageView?.isHidden = false

            var showOverlay: Bool = true

            if let cell = cell as? MediaCollectionViewCell {
                cell.showCheckmark(true)
                cell.disableScrollView()
                if let collectionModel = model as? CollectionModel, collectionModel.mediaCollection is VLCMLPlaylist {
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
            
            cell.media = currentDataSet[indexPath.row]
            return cell
        } else {
            assertionFailure("We couldn't dequeue a reusable cell, the cell might not be registered or is not a MediaEditCell")
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let collectionModel = model as? CollectionModel, let playlist = collectionModel.mediaCollection as? VLCMLPlaylist else {
            assertionFailure("can Move should've been false")
            return
        }
        playlist.moveMedia(fromPosition: UInt32(sourceIndexPath.row), toDestination: UInt32(destinationIndexPath.row))
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if let collectionModel = model as? CollectionModel, collectionModel.mediaCollection is VLCMLPlaylist {
            return true
        }
        return false
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: AlbumHeader.headerID, for: indexPath)

        guard let header = headerView as? AlbumHeader,
              let collectionModel = model as? CollectionModel,
              collectionModel.mediaCollection is VLCMLAlbum else {
            return headerView
        }

        if let currentThumbnail = delegate?.editControllerGetCurrentThumbnail() {
            header.updateImage(with: currentThumbnail)
        }

        header.shouldDisablePlayButtons(true)

        return header
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let delegate = delegate as? MediaCategoryViewController {
            delegate.scrollViewDidScroll(scrollView)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension EditController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var toWidth = collectionView.frame.size.width
        if #available(iOS 11.0, *) {
            toWidth = collectionView.safeAreaLayoutGuide.layoutFrame.width
        }

        return model.cellType.cellSizeForWidth(toWidth)
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

