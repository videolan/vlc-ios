/*****************************************************************************
 * VLCPlaybackController+VLCDialogProvider.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

extension VLCPlaybackController: VLCCustomDialogRendererProtocol {
    public func showError(withTitle error: String, message: String) {
        //noop
    }

    public func showLogin(withTitle title: String, message: String, defaultUsername username: String?, askingForStorage: Bool, withReference reference: NSValue) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var usernameField: UITextField?
        var passwordField: UITextField?
        alertController.addTextField { textField in
            usernameField = textField
            textField.placeholder = NSLocalizedString("USER_LABEL", comment:"")
            if username != "" {
                textField.text = username
            }
        }
        alertController.addTextField { textField in
            passwordField = textField
            textField.isSecureTextEntry = true
            textField.placeholder = NSLocalizedString("PASSWORD_LABEL", comment:"")
        }
        let loginAction = UIAlertAction(title: NSLocalizedString("LOGIN", comment:""), style: .default) {[weak self] action in
            let username = usernameField?.text ?? ""
            let password = passwordField?.text ?? ""
            self?.dialogProvider.postUsername(username, andPassword: password, forDialogReference: reference, store: false)
        }
        alertController.addAction(loginAction)
        alertController.preferredAction = loginAction

        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment:""), style: .cancel, handler: { [weak self] action in
            self?.dialogProvider.dismissDialog(withReference: reference)
        }))
        if askingForStorage {
            alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_SAVE", comment:""), style: .default, handler: {[weak self] action in
                let username = usernameField?.text ?? ""
                let password = passwordField?.text ?? ""
                self?.dialogProvider.postUsername(username, andPassword: password, forDialogReference: reference, store: true)
            }))
        }
        
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            let presentingController = rootViewController.presentedViewController ?? rootViewController
            presentingController.present(alertController, animated: true, completion: nil)
        }

    }

    public func showQuestion(withTitle title: String, message: String, type questionType: VLCDialogQuestionType, cancel cancelString: String?, action1String: String?, action2String: String?, withReference reference: NSValue) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if let cancelTitle = cancelString {
            alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: { [weak self] action in
                self?.dialogProvider.postAction(3, forDialogReference: reference)
            }))
        }
        if let action1Ttile = action1String {
            let confirmAction = UIAlertAction(title: action1Ttile, style: .default, handler: { [weak self] action in
                self?.dialogProvider.postAction(1, forDialogReference: reference)
            })
            alertController.addAction(confirmAction)
            alertController.preferredAction = confirmAction
        }

        if let action2Title = action2String {
            alertController.addAction(UIAlertAction(title: action2Title, style: .default, handler: {[weak self] action in
                self?.dialogProvider.postAction(2, forDialogReference: reference)
            }))
        }
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            let presentingController = rootViewController.presentedViewController ?? rootViewController
            presentingController.present(alertController, animated: true, completion: nil)
        }
    }

    public func showProgress(withTitle title: String, message: String, isIndeterminate: Bool, position: Float, cancel cancelString: String?, withReference reference: NSValue) {
        print("title: \(title), message: \(message), isIndeterminate: \(isIndeterminate), position: \(position), cancel: \(cancelString ?? ""), reference: \(reference)")
    }

    public func updateProgress(withReference reference: NSValue, message: String?, position: Float) {
        print("reference: \(reference) message: \(message ?? "") position: \(position)")
    }

    public func cancelDialog(withReference reference: NSValue) {
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            let presentingController = rootViewController.presentedViewController ?? rootViewController
            presentingController.dismiss(animated: true, completion: nil)
        }
    }
}
