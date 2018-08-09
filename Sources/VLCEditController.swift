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

protocol VLCEditControllerDataSource {
    func toolbarNeedsUpdate(editing: Bool)
}

class VLCEditController: NSObject {
    private var selectedCellIndexPaths = Set<IndexPath>()
    private let collectionView: UICollectionView
    private let category: MediaLibraryBaseModel

    private lazy var editToolbar: VLCEditToolbar = {
        let editToolbar = VLCEditToolbar(frame: CGRect(x: 0, y: 550,
                                                       width: collectionView.frame.width, height: 50))
        editToolbar.isHidden = true
        editToolbar.delegate = self
        return editToolbar
    }()

    init(collectionView: UICollectionView, category: MediaLibraryBaseModel) {
        self.collectionView = collectionView
        self.category = category
        super.init()

        collectionView.addSubview(editToolbar)
        collectionView.bringSubview(toFront: editToolbar)
    }
}

// MARK: - Helpers

private extension VLCEditController {
    private func resetCell(at indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? VLCMediaViewEditCell {
            cell.checkView.isEnabled = false
        }
        collectionView.reloadData()
    }

    private func resetAllVisibleCell() {
        for case let cell as VLCMediaViewEditCell in collectionView.visibleCells {
            cell.checkView.isEnabled = false
        }
    }
}

extension VLCEditController: VLCEditControllerDataSource {
    func toolbarNeedsUpdate(editing: Bool) {
        editToolbar.isHidden = !editing
        if !editing {
            // not in editing mode anymore should reset
            selectedCellIndexPaths.removeAll(keepingCapacity: false)
        }
    }
}

extension VLCEditController: VLCEditToolbarDelegate {
    func createPlaylist() {
        if let model = category as? PlaylistModel {
            model.create(name: "new playlist")
        } else if let model = category as? VideoModel {
            let playlist = model.medialibrary.createPlaylist(with: "new playlist videomo")
            for indexPath in selectedCellIndexPaths {
                if let media = dataSet[indexPath.row] as? VLCMLMedia {
                    playlist.appendMedia(withIdentifier: media.identifier())
                }
            }
        }
    }

    func delete() {
        var objectsToDelete = [VLCMLObject]()

        for indexPath in selectedCellIndexPaths {
            objectsToDelete.append(category.anyfiles[indexPath.row])
        }

        let cancelButton = VLCAlertButton(title: NSLocalizedString("BUTTON_CANCEL", comment: ""))
        let deleteButton = VLCAlertButton(title: NSLocalizedString("BUTTON_DELETE", comment: ""),
                                          action: {
                                            [weak self] action in
                                            self?.category.delete(objectsToDelete)
                                            self?.selectedCellIndexPaths.removeAll()
                                            self?.resetAllVisibleCell()
        })

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("DELETE_TITLE", comment: ""),
                                                errorMessage: NSLocalizedString("DELETE_MESSAGE", comment: ""),
                                                viewController: (UIApplication.shared.keyWindow?.rootViewController)!,
                                                buttonsAction: [cancelButton,
                                                                deleteButton])
    }

    func rename() {
        for indexPath in selectedCellIndexPaths {
            if let media = category.anyfiles[indexPath.row] as? VLCMLMedia {
                // Not using VLCAlertViewController to have more customization in text fields
                let alertController = UIAlertController(title: String(format: NSLocalizedString("RENAME_MEDIA_TO", comment: ""), media.title),
                                                        message: "",
                                                        preferredStyle: .alert)

                alertController.addTextField(configurationHandler: {
                    textField in
                    textField.placeholder = NSLocalizedString("NEW_NAME", comment: "")
                })

                let cancelButton = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                                 style: .default)


                let confirmAction = UIAlertAction(title: NSLocalizedString("BUTTON_DONE", comment: ""), style: .default) {
                    [weak alertController, weak self] _ in
                    guard let alertController = alertController,
                        let textField = alertController.textFields?.first else { return }
                    media.updateTitle(textField.text)
                    self?.resetCell(at: indexPath)
                }

                alertController.addAction(cancelButton)
                alertController.addAction(confirmAction)

                UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

extension VLCEditController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return category.anyfiles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCMediaViewEditCell.identifier,
                                                         for: indexPath) as? VLCMediaViewEditCell {
            if let media = category.anyfiles[indexPath.row] as? VLCMLMedia {
                cell.titleLabel.text = media.title
                cell.subInfoLabel.text = media.formatDuration()
                cell.sizeLabel.text = media.formatSize()
            }
            return cell
        }
        return UICollectionViewCell()
    }
}

extension VLCEditController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? VLCMediaViewEditCell {
            cell.checkView.isEnabled = !cell.checkView.isEnabled
            if cell.checkView.isEnabled {
                // cell selected, saving indexPath
                selectedCellIndexPaths.insert(indexPath)
            } else {
                selectedCellIndexPaths.remove(indexPath)
            }
        }
    }
}

extension VLCEditController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentInset = collectionView.contentInset
        // FIXME: 5 should be cell padding, but not usable maybe static?
        let insetToRemove = contentInset.left + contentInset.right + (5 * 2)
        return CGSize(width: collectionView.frame.width - insetToRemove, height: VLCMediaViewEditCell.height)
    }
}
