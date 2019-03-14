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

protocol VLCEditControllerDelegate: class {
    func editController(editController: VLCEditController, cellforItemAt indexPath: IndexPath) -> MediaEditCell?
}

class VLCEditController: UIViewController {
    private var selectedCellIndexPaths = Set<IndexPath>()
    private let model: MediaLibraryBaseModel
    private let services: Services
    weak var delegate: VLCEditControllerDelegate?

    override func loadView() {
        super.loadView()
        let editToolbar = VLCEditToolbar(category: model)
        editToolbar.delegate = self
        self.view = editToolbar
    }

    init(services: Services, model: MediaLibraryBaseModel) {
        self.services = services
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resetSelections() {
        selectedCellIndexPaths.removeAll(keepingCapacity: false)
    }
}

// MARK: - Helpers

private extension VLCEditController {

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

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - VLCEditToolbarDelegate

extension VLCEditController: VLCEditToolbarDelegate {

    func editToolbarDidAddToPlaylist(_ editToolbar: VLCEditToolbar) {
        //Todo: replace with Viewcontroller that shows existing Playlists
        let alertInfo = TextFieldAlertInfo(alertTitle: NSLocalizedString("PLAYLISTS", comment: ""),
                                           alertDescription: NSLocalizedString("PLAYLIST_DESCRIPTION", comment: ""),
                                           placeHolder: NSLocalizedString("PLAYLIST_PLACEHOLDER", comment:""))

        presentTextFieldAlert(with: alertInfo, completionHandler: {
            [weak self, selectedCellIndexPaths, model] text -> Void in
            guard let playlist = self?.services.medialibraryManager.createPlaylist(with: text) else {
                assertionFailure("couldn't create playlist")
                return
            }
            for indexPath in selectedCellIndexPaths {
                guard let media = model.anyfiles[indexPath.row] as? VLCMLMedia else {
                    assertionFailure("we're not handling collections yet")
                    return
                }
                playlist.appendMedia(withIdentifier: media.identifier())
            }
        })
    }

    func editToolbarDidDelete(_ editToolbar: VLCEditToolbar) {
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
        })

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("DELETE_TITLE", comment: ""),
                                                errorMessage: NSLocalizedString("DELETE_MESSAGE", comment: ""),
                                                viewController: (UIApplication.shared.keyWindow?.rootViewController)!,
                                                buttonsAction: [cancelButton,
                                                                deleteButton])
    }

    func editToolbarDidShare(_ editToolbar: VLCEditToolbar) {
        assertionFailure("Implement me")
    }

    func editToolbarDidRename(_ editToolbar: VLCEditToolbar) {
        // FIXME: Multiple renaming of files(multiple alert can get unfriendly if too many files)
        for indexPath in selectedCellIndexPaths {
            if let media = model.anyfiles[indexPath.row] as? VLCMLMedia {
                // Not using VLCAlertViewController to have more customization in text fields
                let alertInfo = TextFieldAlertInfo(alertTitle: String(format: NSLocalizedString("RENAME_MEDIA_TO", comment: ""), media.title),
                                                   placeHolder: NSLocalizedString("RENAME_PLACEHOLDER", comment: ""),
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
                    if let strongself = self {
                        strongself.delegate?.editController(editController: strongself, cellforItemAt: indexPath)?.isChecked = false
                    }
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
