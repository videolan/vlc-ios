/*****************************************************************************
 * VLCAlertViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Quentin Richard <Quentinr75@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

typealias AlertAction = (UIAlertAction) -> Void

@objcMembers class VLCAlertButton: NSObject {
    let title: String
    var action: AlertAction?
    init(title: String, action: AlertAction? = nil) {
        self.title = title
        self.action = action
    }
}

@objcMembers class VLCAlertViewController: UIAlertController {

    class func alertViewManager(title: String, errorMessage: String? = nil, viewController: UIViewController,
                                      buttonsAction: [VLCAlertButton]?) {
        let alert = UIAlertController(title: title, message: errorMessage, preferredStyle: .alert)
        if let buttonsAction = buttonsAction {
            for buttonAction in buttonsAction {
                let action = UIAlertAction(title: buttonAction.title, style: UIAlertActionStyle.default, handler: buttonAction.action)
                alert.addAction(action)
            }
        } else {
            let action = UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment:""), style: UIAlertActionStyle.default, handler: nil)
            alert.addAction(action)
        }
        alert.show(viewController, sender: Any?.self)
        viewController.present(alert, animated: true, completion: nil)
    }

    class func alertManagerWithTextField(title: String, errorMessage: String? = nil, viewController: UIViewController,
                                               buttonsAction: [VLCAlertButton],
                                               textFieldText: String? = nil,
                                               textFieldPlaceholder: String? = nil) {
        let alert = UIAlertController(title: title, message: errorMessage, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = textFieldPlaceholder
            textField.text = textFieldText
        })
        for buttonAction in buttonsAction {
            let action = UIAlertAction(title: buttonAction.title, style: UIAlertActionStyle.default, handler: buttonAction.action)
            alert.addAction(action)
        }
        alert.show(viewController, sender: Any?.self)
        viewController.present(alert, animated: true, completion: nil)
    }
}
