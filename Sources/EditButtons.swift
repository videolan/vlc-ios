/*****************************************************************************
* EditButtons.swift
*
* Copyright © 2019 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

enum EditButtonType {
    case addToPlaylist
    case rename
    case delete
    case share
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

    func button(_ selector: Selector) -> UIButton {
        let generatedButton = UIButton(type: .system)
        generatedButton.setImage(UIImage(named: image), for: .normal)
        generatedButton.addTarget(self, action: selector, for: .touchUpInside)
        generatedButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        generatedButton.tintColor = .orange
        generatedButton.accessibilityLabel = accessibilityLabel
        generatedButton.accessibilityHint = accessibilityHint
        return generatedButton
    }

    @available(iOS 13.0, *)
    func action(_ handler: @escaping (UIAction) -> Void) -> UIAction {
        let generatedAction = UIAction(title: title,
                                       image: UIImage(named: image),
                                       identifier: UIAction.Identifier(rawValue: image),
                                       handler: handler)
        generatedAction.accessibilityLabel = accessibilityLabel
        generatedAction.accessibilityHint = accessibilityHint
        return generatedAction
    }
}

class EditButtonsFactory {
    static func buttonList(for file: VLCMLObject?) -> [EditButtonType] {
        var actionList = [EditButtonType]()

        if let file = file {
            actionList.append(.addToPlaylist)
            if !(file is VLCMLArtist) && !(file is VLCMLGenre) && !(file is VLCMLAlbum) && !(file is VLCMLVideoGroup) {
                actionList.append(.rename)
            }
            if !(file is VLCMLVideoGroup) {
                actionList.append(.delete)
            }
            actionList.append(.share)
        }
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
            }
        }
        return editButtons
    }
}
