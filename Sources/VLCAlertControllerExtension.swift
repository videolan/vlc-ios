/*****************************************************************************
 * VLCAlertControllerExtension.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

typealias UIAlertCompletionBlock = (UIAlertController, Int) -> Void
typealias UIAlertTextFieldCompletionBlock = (UIAlertController, Int, String) -> Void

struct buttonKeys {
    static var blocksCancelButtonIndex: Int = 0
    static var blocksOtherButtonIndex: Int = 1
    static var blocksDestructiveButtonIndex: Int = 2
}

@objc extension UIAlertController {

    @objc static func showAlertInViewController( _ viewController: UIViewController,
                                                            title: String,
                                                          message: String? = nil,
                                                cancelButtonTitle: String,
                                                otherButtonTitles: String? = nil,
                                           destructiveButtonTitle: String? = nil,
                                                         tapBlock: @escaping UIAlertCompletionBlock) {

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelButton = UIAlertAction(title: cancelButtonTitle, style: .cancel,
                                         handler: { (action: UIAlertAction) in
                                            tapBlock(alertController, buttonKeys.blocksCancelButtonIndex)
        })
        alertController.addAction(cancelButton)

        if !(otherButtonTitles ?? "").isEmpty {
            let otherButton = UIAlertAction(title: otherButtonTitles, style: .default,
                                            handler: { (action: UIAlertAction) in
                                                tapBlock(alertController, buttonKeys.blocksOtherButtonIndex)
            })
            alertController.addAction(otherButton)
        }

        if !(destructiveButtonTitle ?? "").isEmpty {
            let destructiveAction = UIAlertAction(title: destructiveButtonTitle, style: .destructive,
                                                  handler: { (action: UIAlertAction) in
                                                    tapBlock(alertController, buttonKeys.blocksDestructiveButtonIndex)
            })
            alertController.addAction(destructiveAction)
        }

        viewController.present(alertController, animated: true, completion: nil)
    }

    @objc static func showAlertTextFieldInViewController( _ viewController: UIViewController,
                                                                     title: String,
                                                                   message: String? = nil,
                                                             textFieldText: String? = nil,
                                                      textFieldPlaceholder: String? = nil,
                                                         cancelButtonTitle: String,
                                                         otherButtonTitles: String,
                                                                  tapBlock: @escaping UIAlertTextFieldCompletionBlock) {

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = textFieldPlaceholder
            textField.text = textFieldText
            textField.isSecureTextEntry = false
            textField.textAlignment = .left
        }

        let cancelButton = UIAlertAction(title: cancelButtonTitle, style: .cancel,
                                         handler: { (action: UIAlertAction) in
                                            tapBlock(alertController, buttonKeys.blocksCancelButtonIndex, "")
        })
        alertController.addAction(cancelButton)

        let otherButton = UIAlertAction(title: otherButtonTitles, style: .destructive,
                                            handler: { (action: UIAlertAction) in
                                                tapBlock(alertController, buttonKeys.blocksOtherButtonIndex, (alertController.textFields?.first?.text)!)
            })
            alertController.addAction(otherButton)

        viewController.present(alertController, animated: true, completion: nil)
    }

    var cancelButtonIndex: Int {
        get {
            return buttonKeys.blocksCancelButtonIndex
        }
    }

    var otherButtonIndex: Int {
        get {
            return buttonKeys.blocksOtherButtonIndex
        }
    }

    var destructiveButtonIndex: Int {
        get {
            return buttonKeys.blocksDestructiveButtonIndex
        }
    }
}
