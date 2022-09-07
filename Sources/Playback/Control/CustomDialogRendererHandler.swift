/*****************************************************************************
 * CustomDialogRendererHandler.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc(VLCCustomDialogRendererHandlerCompletionType)
enum CustomDialogRendererHandlerCompletionType: Int {
    case cancel
    case stop
    case error
    case complete
}

typealias CustomDialogRendererHandlerClosure = (_ status: CustomDialogRendererHandlerCompletionType) -> Void

@objc(VLCCustomDialogRendererHandler)
class CustomDialogRendererHandler: NSObject {
    private var dialogProvider: VLCDialogProvider

    private var selectedSMBv1 = false

    @objc var completionHandler: CustomDialogRendererHandlerClosure?

    @objc init(dialogProvider: VLCDialogProvider) {
        self.dialogProvider = dialogProvider
        super.init()
    }
}

// MARK: - Private helpers

private extension CustomDialogRendererHandler {
    private func handleSMBv1(completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: NSLocalizedString("SMBV1_WARN_TITLE", comment: ""),
                                                message: NSLocalizedString("SMBV1_WARN_DESCRIPTION", comment: ""),
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: NSLocalizedString("SMBV1_CONTINUE", comment:""),
                                                style: .destructive, handler: {
                                                    action in
                                                    completionHandler(true)
        }))

        alertController.addAction(UIAlertAction(title: NSLocalizedString("SMBV1_NEXT_PROTOCOL", comment:""),
                                                style: .default, handler: {
                                                    action in
                                                    completionHandler(false)
        }))

        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            let presentingController = rootViewController.presentedViewController ?? rootViewController
            presentingController.present(alertController, animated: true, completion: nil)
        }
    }

    private func handleLoginAlert(with title: String, message: String,
                                  username: String?, askingForStorage: Bool,
                                  withReference reference: NSValue) {
        let alertController = UIAlertController(title: title, message: message,
                                                preferredStyle: .alert)

        var usernameField: UITextField?
        var passwordField: UITextField?

        alertController.addTextField {
            textField in
            usernameField = textField
            if #available(iOS 11.0, *) {
                textField.textContentType = .username
            }
            textField.placeholder = NSLocalizedString("USER_LABEL", comment:"")
            if username != "" {
                textField.text = username
            }
        }

        alertController.addTextField {
            textField in
            passwordField = textField
            if #available(iOS 11.0, *) {
                textField.textContentType = .password
            }
            textField.isSecureTextEntry = true
            textField.placeholder = NSLocalizedString("PASSWORD_LABEL", comment:"")
        }
        let loginAction = UIAlertAction(title: NSLocalizedString("LOGIN", comment:""),
                                        style: .default) {
                                            [weak self] action in
                                            let username = usernameField?.text ?? ""
                                            let password = passwordField?.text ?? ""
                                            self?.dialogProvider.postUsername(username,
                                                                              andPassword: password,
                                                                              forDialogReference: reference,
                                                                              store: false)
        }
        alertController.addAction(loginAction)
        alertController.preferredAction = loginAction

        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment:""),
                                                style: .cancel, handler: {
                                                    [weak self] action in
                                                    if self?.selectedSMBv1 ?? true {
                                                        self?.completionHandler?(.stop)
                                                    } else {
                                                        self?.completionHandler?(.cancel)
                                                        self?.dialogProvider.dismissDialog(withReference: reference)
                                                    }
        }))
        if askingForStorage {
            alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_SAVE", comment:""), style: .default,
                                                    handler: {
                                                        [weak self] action in
                                                        let username = usernameField?.text ?? ""
                                                        let password = passwordField?.text ?? ""
                                                        self?.dialogProvider.postUsername(username,
                                                                                          andPassword: password,
                                                                                          forDialogReference: reference,
                                                                                          store: true)
            }))
        }

        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            let presentingController = rootViewController.presentedViewController ?? rootViewController
            presentingController.present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: - VLCCustomDialogRendererProtocol

extension CustomDialogRendererHandler: VLCCustomDialogRendererProtocol {
    func showError(withTitle error: String, message: String) {
        completionHandler?(.error)
    }

    func showProgress(withTitle title: String, message: String,
                      isIndeterminate: Bool, position: Float, cancel cancelString: String?,
                      withReference reference: NSValue) {
        // noop
    }

    func updateProgress(withReference reference: NSValue, message: String?, position: Float) {
        // noop
    }

    func showLogin(withTitle title: String, message: String,
                   defaultUsername username: String?, askingForStorage: Bool,
                   withReference reference: NSValue) {

        // Due to a keystore issue, we disable the overall SMBv1 dialog logic and direcly show the login
        handleLoginAlert(with: title, message: message,
                         username: username,
                         askingForStorage: false,
                         withReference: reference)

        //  if !title.contains("SMBv1") || selectedSMBv1 {
        //      handleLoginAlert(with: title, message: message,
        //                       username: username,
        //                       askingForStorage: askingForStorage,
        //                       withReference: reference)
        //      return
        //  }

        //  handleSMBv1() {
        //      [weak self] isSMBv1 in
        //      if isSMBv1 {
        //          self?.selectedSMBv1 = true
        //          self?.handleLoginAlert(with: title, message: message,
        //                                 username: username,
        //                                 askingForStorage: askingForStorage,
        //                                 withReference: reference)
        //      } else {
        //          self?.dialogProvider.dismissDialog(withReference: reference)
        //      }
        //  }
}

    func showQuestion(withTitle title: String, message: String,
                      type questionType: VLCDialogQuestionType, cancel cancelString: String?,
                      action1String: String?, action2String: String?, withReference reference: NSValue) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if let cancelTitle = cancelString {
            alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel,
                                                    handler: {
                                                        [weak self] action in
                                                        self?.dialogProvider.postAction(3, forDialogReference: reference)
            }))
        }
        if let action1Ttile = action1String {
            let confirmAction = UIAlertAction(title: action1Ttile, style: .default, handler: {
                [weak self] action in
                self?.dialogProvider.postAction(1, forDialogReference: reference)
            })
            alertController.addAction(confirmAction)
            alertController.preferredAction = confirmAction
        }

        if let action2Title = action2String {
            alertController.addAction(UIAlertAction(title: action2Title, style: .default,
                                                    handler: {
                                                        [weak self] action in
                                                        self?.dialogProvider.postAction(2, forDialogReference: reference)
            }))
        }
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            let presentingController = rootViewController.presentedViewController ?? rootViewController
            presentingController.present(alertController, animated: true, completion: nil)
        }
    }

    func cancelDialog(withReference reference: NSValue) {
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            let presentingController = rootViewController.presentedViewController ?? rootViewController
            presentingController.dismiss(animated: true, completion: nil)
        }
    }
}
