/*****************************************************************************
* EditActions.swift
*
* Copyright © 2019-2023 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

enum completionState {
    case inProgress
    case success
    case fail
}

class EditActions {
    private let rootViewController: UIViewController
    private let model: MediaLibraryBaseModel
    private let mediaLibraryService: MediaLibraryService
    private var completion: ((completionState) -> Void)?
    var objects = [VLCMLObject]()

    private lazy var addToCollectionViewController: AddToCollectionViewController = {
        var addToCollectionViewController = AddToCollectionViewController()
        addToCollectionViewController.delegate = self
        return addToCollectionViewController
    }()

    init(model: MediaLibraryBaseModel, mediaLibraryService: MediaLibraryService) {
        self.rootViewController = UIApplication.shared.keyWindow!.rootViewController!
        self.model = model
        self.mediaLibraryService = mediaLibraryService
    }
}

// MARK: - Main edit actions

extension EditActions {
    private func addToCollection(_ collection: [MediaCollectionModel], for type: MediaCollectionModel.Type) {
        addToCollectionViewController.mlCollection = collection
        addToCollectionViewController.updateInterface(for: type)
        let navigationController = UINavigationController(rootViewController: addToCollectionViewController)
        rootViewController.present(navigationController, animated: true, completion: nil)
    }

    private func createMediaGroup(from mediaGroupIds: [VLCMLIdentifier],
                                  _ completion: ((completionState) -> Void)? = nil) {
        let alertInfo = TextFieldAlertInfo(alertTitle: NSLocalizedString("MEDIA_GROUPS", comment: ""),
                                           placeHolder: NSLocalizedString("MEDIA_GROUPS_PLACEHOLDER",
                                                                          comment: ""))

        presentTextFieldAlert(with: alertInfo) {
            [unowned self] text -> Void in
            guard text != "" else {
                DispatchQueue.main.async {
                    VLCAlertViewController.alertViewManager(title: NSLocalizedString("ERROR_EMPTY_NAME",
                                                                                     comment: ""),
                                                            viewController: self.rootViewController)
                    completion?(.fail)
                }
                return
            }
            self.createMediaGroup(with: text)
        }
    }

    func addToPlaylist(_ completion: ((completionState) -> Void)? = nil) {
        self.completion = completion
        if !mediaLibraryService.playlists().isEmpty {
            addToCollection(mediaLibraryService.playlists(), for: VLCMLPlaylist.self)
        } else {
            addToNewPlaylist()
        }
    }

    func addToMediaGroup(_ completion: ((completionState) -> Void)? = nil) {
        self.completion = completion

        var mediaGroupIds = [VLCMLIdentifier]()
        objects.forEach() { mediaGroupIds.append($0.identifier()) }

        guard var mediaGroups = mediaLibraryService.medialib.mediaGroups() else {
            assertionFailure("EditActions: addToMediaGroup: Failed to retrieve mediaGroups.")
            completion?(.fail)
            return
        }

        // Filter out visible groups and action originated source media groups
        mediaGroups = mediaGroups.filter() {
            if mediaGroupIds.contains($0.identifier()) {
                // Do not include the current selection
                return false
            } else if $0.nbTotalMedia() == 1 && !$0.userInteracted() {
                // Do not include elements shown as a media
                return false
            }
            return true
        }
        addToCollection(mediaGroups, for: VLCMLMediaGroup.self)
    }

    func removeFromMediaGroup(_ completion: ((completionState) -> Void)? = nil) {
        self.completion = completion
        guard !objects.isEmpty else {
            completion?(.fail)
            return
        }

        guard let media = objects as? [VLCMLMedia] else {
            assertionFailure("EditActions: removeFromMediaGroup: Unknown type inside media group.")
            completion?(.fail)
            return
        }

        guard let collectionModel = model as? CollectionModel else {
            assertionFailure("EditActions: removeFromMediaGroup: Unknown model type for media groups.")
            completion?(.fail)
            return
        }

        if let mediaGroup = collectionModel.mediaCollection as? VLCMLMediaGroup,
            mediaGroup.nbTotalMedia() == media.count {
            guard mediaGroup.destroy() else {
                assertionFailure("EditActions: removeFromMediaGroup: Failed to destroy mediaGroup.")
                completion?(.fail)
                return
            }
        } else {
            media.forEach() { $0.removeFromGroup() }
        }
        collectionModel.filterFilesFromDeletion(of: media)
        completion?(.success)
    }

    func rename(_ completion: ((completionState) -> Void)? = nil) {
        self.completion = completion
        if !objects.isEmpty {
            let mlObject = objects.first
            guard let mlObjectName = getObjectTitle(for: mlObject) else {
                VLCAlertViewController.alertViewManager(title: NSLocalizedString("ERROR_RENAME_FAILED", comment: ""),
                                                        errorMessage: NSLocalizedString("ERROR_RENAME_FAILED", comment: ""),
                                                        viewController: self.rootViewController)
                self.completion?(.fail)
                return
            }

            // Not using VLCAlertViewController to have more customization in text fields
            let alertInfo = TextFieldAlertInfo(alertTitle: String(format: NSLocalizedString("RENAME_MEDIA_TO", comment: ""), mlObjectName),
                                               textfieldText: mlObjectName,
                                               confirmActionTitle: NSLocalizedString("BUTTON_RENAME", comment: ""))
            presentTextFieldAlert(with: alertInfo, completionHandler: {
                [unowned self] text -> Void in
                guard text != "" else {
                    VLCAlertViewController.alertViewManager(title: NSLocalizedString("ERROR_RENAME_FAILED", comment: ""),
                                                            errorMessage: NSLocalizedString("ERROR_EMPTY_NAME", comment: ""),
                                                            viewController: self.rootViewController)
                    self.completion?(.fail)
                    return
                }

                if let media = mlObject as? VLCMLMedia {
                    media.updateTitle(text)
                } else if let playlist = mlObject as? VLCMLPlaylist {
                    playlist.updateName(text)
                } else if let mediaGroup = mlObject as? VLCMLMediaGroup,
                    let mediaGroupViewModel = self.model as? MediaGroupViewModel {
                    mediaGroupViewModel.rename(mediaGroup, to: text)
                }
                self.objects.removeFirst()
                self.completion?(.inProgress)
                self.rename(completion)
            })
        } else {
            self.completion?(.success)
        }
    }

    func delete(_ completion: ((completionState) -> Void)? = nil) {
        let mediaTitle = getObjectTitle(for: objects.first) ?? ""
        self.completion = completion
        var title = String(format: NSLocalizedString("DELETE_SINGLE_TITLE", comment: ""), mediaTitle)
        if objects.count != 1 {
            title = String(format: NSLocalizedString("DELETE_MULTIPLE_TITLE", comment: ""), mediaTitle, objects.count-1)
        }
        var message = NSLocalizedString("DELETE_MESSAGE", comment: "")
        if model is PlaylistModel {
            message = NSLocalizedString("DELETE_MESSAGE_PLAYLIST", comment: "")
        } else if (model as? CollectionModel)?.mediaCollection is VLCMLPlaylist {
            message = NSLocalizedString("DELETE_MESSAGE_PLAYLIST_CONTENT", comment: "")
        }

        let cancelButton = VLCAlertButton(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                          style: .cancel)
        let deleteButton = VLCAlertButton(title: NSLocalizedString("BUTTON_DELETE", comment: ""),
                                          style: .destructive,
                                          action: {
                                            [unowned self] action in
                                            self.model.anyDelete(self.objects)
                                            self.objects.removeAll()
                                            self.completion?(.success)
        })

        VLCAlertViewController.alertViewManager(title: title,
                                                errorMessage: message,
                                                viewController: rootViewController,
                                                buttonsAction: [cancelButton,
                                                                deleteButton])
    }

    func share(origin: UIView, _ completion: ((completionState) -> Void)? = nil) {
        self.completion = completion
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        guard let controller = VLCActivityViewControllerVendor.activityViewController(forFiles: URLs(),
                                                                                      presenting: nil,
                                                                                      presenting: rootViewController,
                                                                                      completionHandler: {
                [unowned self] _ in
                self.completion?(.success)
            }
        ) else {
            UIApplication.shared.endIgnoringInteractionEvents()
            self.completion?(.fail)
            return
        }
        controller.popoverPresentationController?.sourceView = origin
        controller.popoverPresentationController?.permittedArrowDirections = .any
        controller.popoverPresentationController?.sourceRect = origin.bounds
        rootViewController.present(controller, animated: true) {
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }
}

// MARK: - Private helpers

private extension EditActions {
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

    private func getObjectTitle(for mlObject: VLCMLObject?) -> String? {
        guard let mlObject = mlObject else {
            return nil
        }
        if let media = mlObject as? VLCMLMedia {
            return media.title
        } else if let playlist = mlObject as? VLCMLPlaylist {
            return playlist.name
        } else if let mediaGroup = mlObject as? VLCMLMediaGroup {
            if mediaGroup.nbTotalMedia() == 1 && !mediaGroup.userInteracted() {
                guard let media = mediaGroup.media(of: .video)?.first else {
                    assertionFailure("EditActions: rename/delete Failed to retrieve media.")
                    return nil
                }
                return media.title
            }
            else {
                return mediaGroup.name()
            }
        } else if let artist = mlObject as? VLCMLArtist {
            return artist.artistName()
        } else if let album = mlObject as? VLCMLAlbum {
            return album.albumName()
        } else if let genre = mlObject as? VLCMLGenre {
            return genre.title()
        } else {
            assertionFailure("EditActions: Rename/Delete called with wrong model.")
            return nil
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

        rootViewController.present(alertController, animated: true, completion: nil)
    }

    private func URLs() -> [URL] {
        var fileURLs = [URL]()

        for object in objects {
            if let media = object as? VLCMLMedia {
                if let file = media.mainFile() {
                    fileURLs.append(file.mrl)
                }
            } else if let mediaCollection = object as? MediaCollectionModel {
                if let files = mediaCollection.files() {
                    for media in files {
                        if let file = media.mainFile() {
                            fileURLs.append(file.mrl)
                        }
                    }
                }
            }
        }
        return fileURLs
    }

    // MARK: Media Groups

    private func createMediaGroup(with name: String) {
        var media = [VLCMLMedia]()
        var mediaGroupIds = [VLCMLIdentifier]()

        objects.forEach() {
            if let mediaGroup = $0 as? VLCMLMediaGroup {
                media += mediaGroup.media(of: .video) ?? []
                mediaGroupIds.append(mediaGroup.identifier())
            } else if let medium = $0 as? VLCMLMedia {
                media.append(medium)
            } else {
                assertionFailure("EditActions: createMediaGroup: Unknown type.")
            }
        }

        if let mediaGroupModel = model as? MediaGroupViewModel {
            if !mediaGroupModel.create(with: name, from: mediaGroupIds, content: media) {
                completion?(.fail)
                return
            }
        }
        completion?(.success)
    }

    // MARK: Playlist

    private func addToNewPlaylist() {
        let alertInfo = TextFieldAlertInfo(alertTitle: NSLocalizedString("PLAYLISTS", comment: ""),
                                           placeHolder: NSLocalizedString("PLAYLIST_PLACEHOLDER",
                                                                          comment: ""))
        presentTextFieldAlert(with: alertInfo) {
            [unowned self] text -> Void in
            guard text != "" else {
                DispatchQueue.main.async {
                    VLCAlertViewController.alertViewManager(title: NSLocalizedString("ERROR_EMPTY_NAME",
                                                                                     comment: ""),
                                                            viewController: self.rootViewController)
                }
                return
            }
            self.createPlaylist(text)
        }
    }

    private func createPlaylist(_ name: String) {
        guard let playlist = mediaLibraryService.createPlaylist(with: name) else {
            assertionFailure("EditActions: createPlaylist: Failed to create a playlist.")
            DispatchQueue.main.async {
                VLCAlertViewController.alertViewManager(title: NSLocalizedString("ERROR_PLAYLIST_CREATION",
                                                                                 comment: ""),
                                                        viewController: self.rootViewController)
            }
            completion?(.fail)
            return
        }

        for media in objects {
            if !playlist.appendMedia(withIdentifier: media.identifier()) {
                assertionFailure("EditActions: createPlaylist: Failed to add item.")
            }
        }
        completion?(.success)
    }
}

// MARK: - AddToCollectionViewControllerDelegate

extension EditActions: AddToCollectionViewControllerDelegate {
    func addToCollectionViewController(_ addToCollectionViewController: AddToCollectionViewController,
                                       didSelectCollection collection: MediaCollectionModel) {

        var tmpMedia = [VLCMLMedia]()

        if let mediaGroups = objects as? [VLCMLMediaGroup] {
            mediaGroups.forEach() { tmpMedia += $0.media(of: .video) ?? [] }
        } else if let media = objects as? [VLCMLMedia] {
            tmpMedia = media
        } else {
            assertionFailure("EditActions: AddToCollectionViewControllerDelegate: Failed to retrieve type.")
            completion?(.fail)
            return
        }

        if let mediaGroup = collection as? VLCMLMediaGroup,
            let mediaGroupModel = self.model as? MediaGroupViewModel {
            mediaGroupModel.append(tmpMedia, to: mediaGroup)
        } else if let playlist = collection as? VLCMLPlaylist {
            for medium in tmpMedia {
                if !playlist.appendMedia(withIdentifier: medium.identifier()) {
                    assertionFailure("EditActions: AddToPlaylistViewControllerDelegate: Failed to add item.")
                    completion?(.fail)
                }
            }
        }
        addToCollectionViewController.dismiss(animated: true, completion: nil)
        completion?(.success)
    }

    func addToCollectionViewController(_ addToCollectionViewController: AddToCollectionViewController,
                                       newCollectionName name: String,
                                       from mlType: MediaCollectionModel.Type) {
        if mlType is VLCMLPlaylist.Type {
            createPlaylist(name)
        } else if mlType is VLCMLMediaGroup.Type {
            createMediaGroup(with: name)
        }
        addToCollectionViewController.dismiss(animated: true, completion: nil)
    }

    func addToCollectionViewControllerMoveCollections(_
        addToCollectionViewController: AddToCollectionViewController) {
        guard let mediaGroups = objects as? [VLCMLMediaGroup] else {
            assertionFailure("EditActions: Cannot move out if not VLCMLMediaGroups.")
            completion?(.fail)
            return
        }

        guard let mediaGroupViewModel = model as? MediaGroupViewModel else {
            assertionFailure("EditActions: Cannot move out if not MediaGroupViewModel.")
            completion?(.fail)
            return
        }

        var mediaGroupsIds = [VLCMLIdentifier]()

        mediaGroups.forEach() {
            // Skip mediaGroups that are shown as media
            if $0.userInteracted() || $0.nbTotalMedia() > 1 {
                mediaGroupsIds.append($0.identifier())
                $0.destroy()
            }
        }
        mediaGroupViewModel.filterFilesFromDeletion(of: mediaGroupsIds)
        addToCollectionViewController.dismiss(animated: true, completion: nil)
        completion?(.success)
    }
}
