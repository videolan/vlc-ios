/*****************************************************************************
 * MenuButton.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol MenuButtonDelegate: AnyObject {
    func menuButtonWillShowMenu(_ menuButton: MenuButton)
    func menuButtonDidHideMenu(_ menuButton: MenuButton)
}

final class MenuButton: UIButton {
    weak var delegate: MenuButtonDelegate?

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         willDisplayMenuFor configuration: UIContextMenuConfiguration,
                                         animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willDisplayMenuFor: configuration, animator: animator)
        delegate?.menuButtonWillShowMenu(self)
    }

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         willEndFor configuration: UIContextMenuConfiguration,
                                         animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willEndFor: configuration, animator: animator)
        delegate?.menuButtonDidHideMenu(self)
    }
}
