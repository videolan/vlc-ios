/*****************************************************************************
* EditActions.swift
*
* Copyright © 2019 VLC authors and VideoLAN
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

    private lazy var addToPlaylistViewController: AddToPlaylistViewController = {
        var addToPlaylistViewController = AddToPlaylistViewController(playlists: mediaLibraryService.playlists())
        addToPlaylistViewController.delegate = self
        return addToPlaylistViewController
    }()

    init(model: MediaLibraryBaseModel, mediaLibraryService: MediaLibraryService) {
        self.rootViewController = UIApplication.shared.keyWindow!.rootViewController!
        self.model = model
        self.mediaLibraryService = mediaLibraryService
    }

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

    func addToPlaylist(_ completion: ((completionState) -> Void)? = nil) {
        self.completion = completion
        if !mediaLibraryService.playlists().isEmpty {
            addToPlaylistViewController.playlists = mediaLibraryService.playlists()
            let navigationController = UINavigationController(rootViewController: addToPlaylistViewController)
            rootViewController.present(navigationController, animated: true, completion: nil)
        } else {
            addToNewPlaylist()
        }
    }

    func rename(_ completion: ((completionState) -> Void)? = nil) {
        self.completion = completion
        if !objects.isEmpty {
            let mlObject = objects.first
            var mlObjectName = ""

            if let media = mlObject as? VLCMLMedia {
                mlObjectName = media.title
            } else if let playlist = mlObject as? VLCMLPlaylist {
                mlObjectName = playlist.name
            } else {
                assertionFailure("EditActions: Rename called with wrong model.")
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
                }
                self.objects.removeFirst()
                self.completion?(.inProgress)
                self.rename(completion)
            })
        } else {
            self.completion?(.success)
        }
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

    func delete(_ completion: ((completionState) -> Void)? = nil) {
        self.completion = completion
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
                                            self.model.delete(self.objects)
                                            self.objects.removeAll()
                                            self.completion?(.success)
        })

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("DELETE_TITLE", comment: ""),
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

// MARK: - AddToPlaylistViewControllerDelegate

extension EditActions: AddToPlaylistViewControllerDelegate {
    func addToPlaylistViewController(_ addToPlaylistViewController: AddToPlaylistViewController,
                                     didSelectPlaylist playlist: VLCMLPlaylist) {
        for media in objects {
            if !playlist.appendMedia(withIdentifier: media.identifier()) {
                assertionFailure("EditActions: AddToPlaylistViewControllerDelegate: Failed to add item.")
                completion?(.fail)
            }
        }
        addToPlaylistViewController.dismiss(animated: true, completion: nil)
        completion?(.success)
    }

    func addToPlaylistViewController(_ addToPlaylistViewController: AddToPlaylistViewController,
                                     newPlaylistWithName name: String) {
        createPlaylist(name)
        addToPlaylistViewController.dismiss(animated: true, completion: nil)
    }
}
