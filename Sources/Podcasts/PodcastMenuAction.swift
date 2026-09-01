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
    let handler: () -> Void
}

extension Array where Element == PodcastMenuAction {
    @available(iOS 14.0, *)
    func menu() -> UIMenu {
        let color = PresentationTheme.current.colors.cellTextColor
        let actions = map { action -> UIAction in
            var attributes: UIMenuElement.Attributes = action.isEnabled ? [] : .disabled
            if action.isDestructive {
                attributes.insert(.destructive)
            }
            let image = action.isDestructive ? UIImage(systemName: action.imageName)
                : UIImage(systemName: action.imageName)?.withTintColor(color, renderingMode: .alwaysOriginal)
            return UIAction(title: action.title, image: image, attributes: attributes) { _ in
                action.handler()
            }
        }
        return UIMenu(title: "", children: actions)
    }

    func presentActionSheet(title: String?, from barButtonItem: UIBarButtonItem, in viewController: UIViewController) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for action in self {
            let alertAction = UIAlertAction(title: action.title,
                                            style: action.isDestructive ? .destructive : .default) { _ in
                action.handler()
            }
            alertAction.isEnabled = action.isEnabled
            alertController.addAction(alertAction)
        }
        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel))
        alertController.popoverPresentationController?.barButtonItem = barButtonItem
        viewController.present(alertController, animated: true)
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
