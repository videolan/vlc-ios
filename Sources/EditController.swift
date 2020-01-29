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

protocol EditControllerDelegate: class {
    func editController(editController: EditController, cellforItemAt indexPath: IndexPath) -> BaseCollectionViewCell?
    func editController(editController: EditController, present viewController: UIViewController)

    func editControllerDidFinishEditing(editController: EditController?)
}

class EditController: UIViewController {
    // Cache selectedIndexPath separately to indexPathsForSelectedItems in order to have persistance
    private var selectedCellIndexPaths = Set<IndexPath>()
    private let model: MediaLibraryBaseModel
    private let mediaLibraryService: MediaLibraryService
    private let presentingView: UICollectionView
    private(set) var editActions: EditActions

    weak var delegate: EditControllerDelegate?

    init(mediaLibraryService: MediaLibraryService,
         model: MediaLibraryBaseModel,
         presentingView: UICollectionView) {
        self.mediaLibraryService = mediaLibraryService
        self.model = model
        self.presentingView = presentingView
        self.editActions = EditActions(model: model, mediaLibraryService: mediaLibraryService)
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
}

// MARK: - VLCEditToolbarDelegate

extension EditController: EditToolbarDelegate {
    private func getSelectedObjects() {
        let files = model.anyfiles

        for index in selectedCellIndexPaths where index.row < files.count {
            if let mediaCollection = files[index.row] as? MediaCollectionModel {
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
                editActions.objects.append(files[index.row])
            }
        }
    }

    func editToolbarDidAddToPlaylist(_ editToolbar: EditToolbar) {
        guard !selectedCellIndexPaths.isEmpty else {
            assertionFailure("EditController: Add to playlist called without selection")
            return
        }
        editActions.objects.removeAll()
        getSelectedObjects()
        editActions.addToPlaylist({
            [weak self] state in
            if state == .success || state == .fail {
                self?.resetSelections(resetUI: false)
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        })
    }

    func editToolbarDidDelete(_ editToolbar: EditToolbar) {
        guard !selectedCellIndexPaths.isEmpty else {
            assertionFailure("EditController: Delete called without selection")
            return
        }
        editActions.objects.removeAll()
        for indexPath in selectedCellIndexPaths.sorted(by: { $0 > $1 }) {
            editActions.objects.append(model.anyfiles[indexPath.row])
        }

        editActions.delete({
            [weak self] state in
            if state == .success || state == .fail {
                self?.resetSelections(resetUI: false)
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        })
    }

    func editToolbarDidShare(_ editToolbar: EditToolbar) {
        guard !selectedCellIndexPaths.isEmpty else {
            assertionFailure("EditController: Share called without selection")
            return
        }
        editActions.objects.removeAll()
        getSelectedObjects()
        editActions.share(origin: editToolbar.shareButton, {
            [weak self] state in
            if state == .success || state == .fail {
                self?.resetSelections(resetUI: false)
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        })
    }

    func editToolbarDidRename(_ editToolbar: EditToolbar) {
        guard !selectedCellIndexPaths.isEmpty else {
            assertionFailure("EditController: Rename called without selection")
            return
        }
        editActions.objects.removeAll()
        for indexPath in selectedCellIndexPaths.sorted(by: { $0 > $1 }) {
            editActions.objects.append(model.anyfiles[indexPath.row])
        }
        editActions.rename({
            [weak self] state in
            if state == .success || state == .fail {
                self?.resetSelections(resetUI: true)
                self?.delegate?.editControllerDidFinishEditing(editController: self)
            }
        })
    }
}

// MARK: - UICollectionViewDelegate

extension EditController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCellIndexPaths.insert(indexPath)
        // Isolate selectionViewOverlay changes inside EditController
        if let cell = collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell {
            cell.selectionViewOverlay?.isHidden = false
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedCellIndexPaths.remove(indexPath)
        if let cell = collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell {
            cell.selectionViewOverlay?.isHidden = true
        }
    }
}

// MARK: - UICollectionViewDataSource

extension EditController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.anyfiles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: model.cellType.defaultReuseIdentifier,
                                                         for: indexPath) as? BaseCollectionViewCell {
            cell.media = model.anyfiles[indexPath.row]
            cell.isSelected = selectedCellIndexPaths.contains(indexPath)
            cell.isAccessibilityElement = true
            cell.checkImageView?.isHidden = false

            if let cell = cell as? MediaCollectionViewCell,
                let collectionModel = model as? CollectionModel, collectionModel.mediaCollection is VLCMLPlaylist {
                cell.dragIndicatorImageView.isHidden = false
            }
            if cell.media is VLCMLMedia {
                cell.secondDescriptionLabelView?.isHidden = false
                cell.descriptionSeparatorLabel?.isHidden = false
            }

            if cell.isSelected {
                cell.selectionViewOverlay?.isHidden = false
            }
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

