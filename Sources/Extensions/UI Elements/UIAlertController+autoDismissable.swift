/*****************************************************************************
 * UIAlertController+autoDismissable.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

extension UIAlertController {
    @objc static func autoDismissable(title: String, message: String, dismissDelay: Double = 3.0) {
        guard let presentingViewController = UIApplication.shared.topViewController else {
            return
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment:""),
                                      style: .default,
                                      handler: nil))

        presentingViewController.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
}
