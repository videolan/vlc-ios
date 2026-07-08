/*****************************************************************************
* EditButtons.swift
*
* Copyright © 2019 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*                     Diogo Simao Marques <dogo@videolabs.io>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

@objc enum EditButtonType: Int {
    case addToPlaylist
    case addToMediaGroup
    case removeFromMediaGroup
    case rename
    case delete
    case share
    case play
    case playNextInQueue
    case appendToQueue
    case playAsAudio
    case markAsSeen
    case markAsUnseen

    // For testing, remove later
    case updateAppContext
    case sendMessage
    case sendMessageData
    case transferFile
    case transferUserInfo
    case transferComplicationUserInfo
    case transferMetadata
}

class EditButton {
    var identifier: EditButtonType
    var title: String
    var image: String
    var accessibilityLabel: String
    var accessibilityHint: String

    init(identifier: EditButtonType, title: String, image: String, accessibilityLabel: String, accessibilityHint: String) {
        self.identifier = identifier
        self.title = title
        self.image = image
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }

    private var resolvedImage: UIImage? {
        if #available(iOS 13.0, *) {
            return UIImage(named: image) ?? UIImage(systemName: image)
        }
        return UIImage(named: image)
    }

    func button(_ target: Any?, _ selector: Selector) -> UIButton {
        let generatedButton = UIButton(type: .system)
        generatedButton.setImage(resolvedImage, for: .normal)
        generatedButton.addTarget(target, action: selector, for: .touchUpInside)
        generatedButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        generatedButton.tintColor = .orange
        generatedButton.accessibilityLabel = accessibilityLabel
        generatedButton.accessibilityHint = accessibilityHint
        return generatedButton
    }

    @available(iOS 13.0, *)
    func action(_ handler: @escaping (UIAction) -> Void) -> UIAction {
        let generatedAction = UIAction(title: title,
                                       image: resolvedImage?.withTintColor(PresentationTheme.current.colors.orangeUI, renderingMode: .alwaysOriginal),
                                       identifier: UIAction.Identifier(rawValue: image),
                                       handler: handler)
        generatedAction.accessibilityLabel = accessibilityLabel
        generatedAction.accessibilityHint = accessibilityHint
        return generatedAction
    }
}

class EditButtonsFactory {
    static func buttonList(for model: MediaLibraryBaseModel) -> [EditButtonType] {
        var actionList = [EditButtonType]()

        actionList.append(.play)
        actionList.append(.playNextInQueue)
        actionList.append(.appendToQueue)
        actionList.append(.addToPlaylist)
        if model is MediaGroupViewModel {
            actionList.append(.addToMediaGroup)
            actionList.append(.playAsAudio)
        } else if let collectionModel = model as? CollectionModel,
            collectionModel.mediaCollection is VLCMLMediaGroup {
            actionList.append(.removeFromMediaGroup)
            actionList.append(.playAsAudio)
        }

        if !(model is ArtistModel) && !(model is GenreModel) && !(model is AlbumModel) {
            actionList.append(.rename)
        }
        actionList.append(.delete)
        actionList.append(.share)

        // For testing
//        actionList.append(.updateAppContext)
//        actionList.append(.sendMessage)
//        actionList.append(.sendMessageData)
//        actionList.append(.transferFile)
//        actionList.append(.transferUserInfo)
//        actionList.append(.transferComplicationUserInfo)
//        actionList.append(.transferMetadata)

        return actionList
    }

    static func generate(buttons: [EditButtonType]) -> [EditButton] {
        var editButtons = [EditButton]()
        for button in buttons {
            switch button {
                case .addToPlaylist:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("ADD_TO_PLAYLIST", comment: ""),
                                                  image: "addToPlaylist",
                                                  accessibilityLabel: NSLocalizedString("ADD_TO_PLAYLIST", comment: ""),
                                                  accessibilityHint: NSLocalizedString("ADD_TO_PLAYLIST_HINT", comment: "")))
                case .addToMediaGroup:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("ADD_TO_MEDIA_GROUP", comment: ""),
                                                  image: "addToMediaGroup",
                                                  accessibilityLabel: NSLocalizedString("ADD_TO_MEDIA_GROUP", comment: ""),
                                                  accessibilityHint: NSLocalizedString("ADD_TO_MEDIA_GROUP_HINT",
                                                                                       comment: "")))
                case .removeFromMediaGroup:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("REMOVE_FROM_MEDIA_GROUP", comment: ""),
                                                  image: "removeFromMediaGroup",
                                                  accessibilityLabel: NSLocalizedString("REMOVE_FROM_MEDIA_GROUP",
                                                                                        comment: ""),
                                                  accessibilityHint: NSLocalizedString("REMOVE_FROM_MEDIA_GROUP_HINT",
                                                                                       comment: "")))
                case .rename:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("BUTTON_RENAME", comment: ""),
                                                  image: "rename",
                                                  accessibilityLabel: NSLocalizedString("BUTTON_RENAME", comment: ""),
                                                  accessibilityHint: NSLocalizedString("RENAME_HINT", comment: "")))
                case .delete:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("BUTTON_DELETE", comment: ""),
                                                  image: "delete",
                                                  accessibilityLabel: NSLocalizedString("BUTTON_DELETE", comment: ""),
                                                  accessibilityHint: NSLocalizedString("DELETE_HINT", comment: "")))
                case .share:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("SHARE_LABEL", comment: ""),
                                                  image: "share",
                                                  accessibilityLabel: NSLocalizedString("SHARE_LABEL", comment: ""),
                                                  accessibilityHint: NSLocalizedString("SHARE_HINT", comment: "")))
                case .play:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("PLAY_LABEL", comment: ""),
                                                  image: "MiniPlay",
                                                  accessibilityLabel: NSLocalizedString("PLAY_LABEL", comment: ""),
                                                  accessibilityHint: NSLocalizedString("PLAY_HINT", comment: "")))
                case .playNextInQueue:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("PLAY_NEXT_IN_QUEUE_LABEL", comment: ""),
                                                  image: "playNextInQueue",
                                                  accessibilityLabel: NSLocalizedString("PLAY_NEXT_IN_QUEUE_LABEL", comment: ""),
                                                  accessibilityHint: NSLocalizedString("PLAY_NEXT_IN_QUEUE_HINT", comment: "")))
                case .appendToQueue:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("APPEND_TO_QUEUE_LABEL", comment: ""),
                                                  image: "appendToQueue",
                                                  accessibilityLabel: NSLocalizedString("APPEND_TO_QUEUE_LABEL", comment: ""),
                                                  accessibilityHint: NSLocalizedString("APPEND_TO_QUEUE_HINT", comment: "")))
                case .playAsAudio:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("PLAY_AS_AUDIO", comment: ""),
                                                  image: "Audio",
                                                  accessibilityLabel: NSLocalizedString("PLAY_AS_AUDIO", comment: ""),
                                                  accessibilityHint: NSLocalizedString("PLAY_AS_AUDIO_HINT", comment: "")))
                case .markAsSeen:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("MARK_AS_PLAYED", comment: ""),
                                                  image: "eye.fill",
                                                  accessibilityLabel: NSLocalizedString("MARK_AS_PLAYED", comment: ""),
                                                  accessibilityHint: NSLocalizedString("MARK_AS_PLAYED_HINT", comment: "")))
                case .markAsUnseen:
                    editButtons.append(EditButton(identifier: button,
                                                  title: NSLocalizedString("MARK_AS_UNPLAYED", comment: ""),
                                                  image: "eye.slash.fill",
                                                  accessibilityLabel: NSLocalizedString("MARK_AS_UNPLAYED", comment: ""),
                                                  accessibilityHint: NSLocalizedString("MARK_AS_UNPLAYED_HINT", comment: "")))
                case .updateAppContext:
                editButtons.append(EditButton(identifier: button,
                                              title: "Update App Context",
                                              image: "addToPlaylist",
                                              accessibilityLabel: NSLocalizedString("PLAY_AS_AUDIO", comment: ""),
                                              accessibilityHint: NSLocalizedString("PLAY_AS_AUDIO_HINT", comment: "")))
                case .sendMessage:
                editButtons.append(EditButton(identifier: button,
                                              title: "Send message",
                                              image: "MiniPlay",
                                              accessibilityLabel: NSLocalizedString("PLAY_AS_AUDIO", comment: ""),
                                              accessibilityHint: NSLocalizedString("PLAY_AS_AUDIO_HINT", comment: "")))
                case .sendMessageData:
                editButtons.append(EditButton(identifier: button,
                                              title: "Send message data",
                                              image: "addToMediaGroup",
                                              accessibilityLabel: NSLocalizedString("PLAY_AS_AUDIO", comment: ""),
                                              accessibilityHint: NSLocalizedString("PLAY_AS_AUDIO_HINT", comment: "")))
                case .transferFile:
                editButtons.append(EditButton(identifier: button,
                                              title: "Transfer File",
                                              image: "playNextInQueue",
                                              accessibilityLabel: NSLocalizedString("PLAY_AS_AUDIO", comment: ""),
                                              accessibilityHint: NSLocalizedString("PLAY_AS_AUDIO_HINT", comment: "")))
                case .transferUserInfo:
                editButtons.append(EditButton(identifier: button,
                                              title: "Transfer User Info",
                                              image: "share",
                                              accessibilityLabel: NSLocalizedString("PLAY_AS_AUDIO", comment: ""),
                                              accessibilityHint: NSLocalizedString("PLAY_AS_AUDIO_HINT", comment: "")))
                case .transferComplicationUserInfo:
                editButtons.append(EditButton(identifier: button,
                                              title: "Transfer Complication User Info",
                                              image: "delete",
                                              accessibilityLabel: NSLocalizedString("PLAY_AS_AUDIO", comment: ""),
                                              accessibilityHint: NSLocalizedString("PLAY_AS_AUDIO_HINT", comment: "")))
                case .transferMetadata:
                editButtons.append(EditButton(identifier: button,
                                              title: "Transfer Metadata",
                                              image: "",
                                              accessibilityLabel: "Transfer Metadata",
                                              accessibilityHint: "Transfer MetaData hint"))
            }
        }
        return editButtons
    }
}
