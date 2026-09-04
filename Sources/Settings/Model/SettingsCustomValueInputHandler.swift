/*****************************************************************************
 * SettingsCustomValueInputHandler.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2026 VLC authors and VideoLAN
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class SettingsCustomValueInputHandler {
    static let animationDelay: TimeInterval = 0.7
    static let dismissDelay: TimeInterval = 0.3

    private let title: String
    private let specifier: CustomValueSpecifier
    private weak var currentAlertController: UIAlertController?

    init(title: String, specifier: CustomValueSpecifier) {
        self.title = title
        self.specifier = specifier
    }

    func presentInput() {
        guard let topViewController = UIApplication.shared.topViewController else {
            return
        }

        let message = String(format: NSLocalizedString("SETTINGS_CUSTOM_VALUE_MESSAGE", comment: ""),
                             specifier.plainString(for: specifier.minimum),
                             specifier.plainString(for: specifier.maximum))
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        currentAlertController = alert

        let storedValue = specifier.storedValue
        let text = (storedValue >= specifier.minimum && storedValue <= specifier.maximum) ? specifier.plainString(for: storedValue) : nil
        let keyboardType: UIKeyboardType = specifier.fractionDigits == 0 ? .numberPad : .decimalPad

        alert.addTextField { textField in
            textField.keyboardType = keyboardType
            textField.text = text
#if !os(visionOS)
            textField.inputAccessoryView = UIUtils.createToolbar()
#endif
        }

        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                      style: .cancel,
                                      handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_SAVE", comment: ""),
                                      style: .default) { _ in
            self.save()
        })

        topViewController.present(alert, animated: true) {
            alert.textFields?.first?.becomeFirstResponder()
        }
    }

    private func save() {
        guard let text = currentAlertController?.textFields?.first?.text,
              let value = specifier.value(from: text),
              value >= specifier.minimum,
              value <= specifier.maximum else {
            presentInvalidValueAlert()
            return
        }

        specifier.store(value)

#if os(iOS)
        NotificationFeedbackGenerator().success()
#endif
    }

    private func presentInvalidValueAlert() {
        guard let topViewController = UIApplication.shared.topViewController else {
            return
        }

        let okButton = VLCAlertButton(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .default) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.dismissDelay) {
                self.presentInput()
            }
        }
        let message = String(format: NSLocalizedString("SETTINGS_CUSTOM_VALUE_ERROR", comment: ""),
                             specifier.plainString(for: specifier.minimum),
                             specifier.plainString(for: specifier.maximum))

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("ERROR", comment: ""),
                                                errorMessage: message,
                                                viewController: topViewController,
                                                buttonsAction: [okButton])
    }
}
