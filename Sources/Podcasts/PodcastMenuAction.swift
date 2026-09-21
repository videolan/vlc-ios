/*****************************************************************************
 * PodcastMenuAction.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

struct PodcastMenuAction {
    let title: String
    let imageName: String
    var isEnabled = true
    var isDestructive = false
    var accessibilityIdentifier: String?
    let handler: () -> Void
}

extension Array where Element == PodcastMenuAction {
    func menu() -> UIMenu {
        let color = PresentationTheme.current.colors.cellTextColor
        let actions = map { action -> UIAction in
            var attributes: UIMenuElement.Attributes = action.isEnabled ? [] : .disabled
            if action.isDestructive {
                attributes.insert(.destructive)
            }
            let image = action.isDestructive ? UIImage(systemName: action.imageName)
                : UIImage(systemName: action.imageName)?.withTintColor(color, renderingMode: .alwaysOriginal)
            let menuAction = UIAction(title: action.title, image: image, attributes: attributes) { _ in
                action.handler()
            }
            menuAction.accessibilityIdentifier = action.accessibilityIdentifier
            return menuAction
        }
        return UIMenu(title: "", children: actions)
    }

}

extension UIViewController {
    func confirmPodcastDownloadDeletion(_ confirmed: @escaping () -> Void) {
        let delete = VLCAlertButton(title: NSLocalizedString("BUTTON_DELETE", comment: ""),
                                    style: .destructive) { _ in
            confirmed()
        }
        let cancel = VLCAlertButton(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)
        VLCAlertViewController.alertViewManager(title: NSLocalizedString("PODCAST_DELETE_DOWNLOAD_TITLE", comment: ""),
                                                errorMessage: NSLocalizedString("PODCAST_DELETE_DOWNLOAD_MESSAGE",
                                                                                comment: ""),
                                                viewController: self,
                                                buttonsAction: [cancel, delete])
    }
}
