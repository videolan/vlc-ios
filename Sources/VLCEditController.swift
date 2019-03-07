/*****************************************************************************
 * VLCEditController.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VLCEditController: NSObject {
    private var selectedCellIndexPaths = Set<IndexPath>()
    private let collectionView: UICollectionView
    private let model: MediaLibraryBaseModel

    init(collectionView: UICollectionView, model: MediaLibraryBaseModel) {
        self.collectionView = collectionView
        self.model = model
        super.init()
    }

    func resetSelections() {
        selectedCellIndexPaths.removeAll(keepingCapacity: false)
    }
}

// MARK: - Helpers

private extension VLCEditController {
    private func resetCell(at indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? MediaEditCell {
            cell.isChecked = false
        }
    }

    private func resetAllVisibleCell() {
        for case let cell as MediaEditCell in collectionView.visibleCells {
            cell.isChecked = false
        }
    }

    private struct TextFieldAlertInfo {
        var alertTitle: String
        var alertDescription: String
        var placeHolder: String
        var confirmActionTitle: String

        init(alertTitle: String = "",
             alertDescription: String = "",
             placeHolder: String = "",
             confirmActionTitle: String = NSLocalizedString("BUTTON_DONE", comment: "")) {
            self.alertTitle = alertTitle
            self.alertDescription = alertDescription
            self.placeHolder = placeHolder
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
            textField.placeholder = info.placeHolder
        })

        let cancelButton = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                         style: .default)


        let confirmAction = UIAlertAction(title: info.confirmActionTitle, style: .default) {
            [weak alertController] _ in
            guard let alertController = alertController,
                let textField = alertController.textFields?.first else { return }
            completionHandler(textField.text ?? "")
        }

        alertController.addAction(cancelButton)
        alertController.addAction(confirmAction)

        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - VLCEditToolbarDelegate

extension VLCEditController: VLCEditToolbarDelegate {

    func editToolbarDidAddToPlaylist(_ edittoolbar: VLCEditToolbar) {
        if let model = model as? PlaylistModel {
            let alertInfo = TextFieldAlertInfo(alertTitle: NSLocalizedString("PLAYLISTS", comment: ""),
                placeHolder: "NEW_PLAYLIST")

            presentTextFieldAlert(with: alertInfo, completionHandler: {
                text -> Void in
                    model.create(name: text)
                })

        } else if let model = model as? VideoModel {
            let alertInfo = TextFieldAlertInfo(alertTitle: NSLocalizedString("PLAYLISTS", comment: ""),
                                               placeHolder: "NEW_PLAYLIST")

            presentTextFieldAlert(with: alertInfo, completionHandler: {
                [selectedCellIndexPaths, model] text -> Void in
                let playlist = model.medialibrary.createPlaylist(with: text)
                for indexPath in selectedCellIndexPaths {
                    if let media = model.anyfiles[indexPath.row] as? VLCMLMedia {
                        playlist.appendMedia(withIdentifier: media.identifier())
                    }
                }
            })
        }
    }

    func editToolbarDidDelete(_ edittoolbar: VLCEditToolbar) {
        var objectsToDelete = [VLCMLObject]()

        for indexPath in selectedCellIndexPaths {
            objectsToDelete.append(model.anyfiles[indexPath.row])
        }

        let cancelButton = VLCAlertButton(title: NSLocalizedString("BUTTON_CANCEL", comment: ""))
        let deleteButton = VLCAlertButton(title: NSLocalizedString("BUTTON_DELETE", comment: ""),
                                          style: .destructive,
                                          action: {
                                            [weak self] action in
                                            self?.model.delete(objectsToDelete)
                                            self?.selectedCellIndexPaths.removeAll()
                                            self?.resetAllVisibleCell()
        })

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("DELETE_TITLE", comment: ""),
                                                errorMessage: NSLocalizedString("DELETE_MESSAGE", comment: ""),
                                                viewController: (UIApplication.shared.keyWindow?.rootViewController)!,
                                                buttonsAction: [cancelButton,
                                                                deleteButton])
    }

    func editToolbarDidShare(_ edittoolbar: VLCEditToolbar) {
        assertionFailure("Implement me")
    }

    func editToolbarDidRename(_ edittoolbar: VLCEditToolbar) {
        // FIXME: Multiple renaming of files(multiple alert can get unfriendly if too many files)
        for indexPath in selectedCellIndexPaths {
            if let media = model.anyfiles[indexPath.row] as? VLCMLMedia {
                // Not using VLCAlertViewController to have more customization in text fields
                let alertInfo = TextFieldAlertInfo(alertTitle: String(format: NSLocalizedString("RENAME_MEDIA_TO", comment: ""), media.title),
                                                   placeHolder: "NEW_NAME",
                                                   confirmActionTitle: NSLocalizedString("BUTTON_RENAME", comment: ""))
                presentTextFieldAlert(with: alertInfo, completionHandler: {
                    [weak self] text -> Void in
                    guard text != "" else {
                        VLCAlertViewController.alertViewManager(title: NSLocalizedString("ERROR_RENAME_FAILED", comment: ""),
                                                                errorMessage: NSLocalizedString("ERROR_EMPTY_NAME", comment: ""),
                                                                viewController: (UIApplication.shared.keyWindow?.rootViewController)!)
                        return
                    }
                    media.updateTitle(text)
                    self?.resetCell(at: indexPath)
                })
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension VLCEditController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.anyfiles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let editCell = (model as? EditableMLModel)?.editCellType() else {
            assertionFailure("The category either doesn't implement EditableMLModel or doesn't have a editcellType defined")
            return UICollectionViewCell()
        }
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: editCell.defaultReuseIdentifier,
                                                         for: indexPath) as? MediaEditCell {
            cell.media = model.anyfiles[indexPath.row]
            cell.isChecked = selectedCellIndexPaths.contains(indexPath)
            return cell
        } else {
            assertionFailure("We couldn't dequeue a reusable cell, the cell might not be registered or is not a MediaEditCell")
            return UICollectionViewCell()
        }
    }
}

// MARK: - UICollectionViewDelegate

extension VLCEditController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? MediaEditCell {
            cell.isChecked = !cell.isChecked
            if cell.isChecked {
                // cell selected, saving indexPath
                selectedCellIndexPaths.insert(indexPath)
            } else {
                selectedCellIndexPaths.remove(indexPath)
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension VLCEditController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentInset = collectionView.contentInset
        // FIXME: 5 should be cell padding, but not usable maybe static?
        let insetToRemove = contentInset.left + contentInset.right + (5 * 2)
        return CGSize(width: collectionView.frame.width - insetToRemove, height: MediaEditCell.height)
    }
}
