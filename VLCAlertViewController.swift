/*****************************************************************************
 * VLCAlertControllerExtension.swift
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


@objcMembers class ButtonAction: NSObject {
    let buttonTitle: String
    var buttonAction: AlertAction
    init(buttonTitle: String, buttonAction: @escaping AlertAction) {
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

}

@objc class VLCAlertViewController: UIAlertController {

   @objc class func alertViewManager(title: String, errorMessage: String? = nil, viewController: UIViewController,
                                       buttonsAction: [ButtonAction]) {
    print(buttonsAction[0].buttonTitle)
    print(buttonsAction[0].buttonAction)
        let alert = UIAlertController(title: title, message: errorMessage, preferredStyle: .alert)
        alert.show(viewController, sender: Any?.self)
        for buttonAction in buttonsAction {
            let action = UIAlertAction(title: buttonAction.buttonTitle, style: UIAlertActionStyle.default, handler: buttonAction.buttonAction)
            alert.addAction(action)
        }
        viewController.present(alert, animated: true, completion: nil)
    }

   @objc class func alertManagerWithTextField(title: String, errorMessage: String? = nil, viewController: UIViewController,
                                         buttonsAction: [ButtonAction], textFieldText: String? = nil,
                                         textFieldPlaceholder: String? = nil) {
        let alert = UIAlertController(title: title, message: errorMessage, preferredStyle: .alert)
        alert.show(viewController, sender: Any?.self)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = textFieldPlaceholder
            textField.text = textFieldText
            textField.isSecureTextEntry = false
            textField.textAlignment = .left
        })
        for buttonAction in buttonsAction {
            let action = UIAlertAction(title: buttonAction.buttonTitle, style: UIAlertActionStyle.default, handler: buttonAction.buttonAction)
            alert.addAction(action)
        }
        viewController.present(alert, animated: true, completion: nil)
    }
}
