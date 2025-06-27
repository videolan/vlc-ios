/*****************************************************************************
 * PlaybackSpeedCustomHelpers.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2025 VLC authors and VideoLAN
 *
 * Authors: Yue(Zelda) Zhang <lichtseeker@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

enum PlaybackSpeedConfig {
    static let minSpeed: Float = 0.25
    static let maxSpeed: Float = 8.0
    static let customSpeedKey = "playback-speed-custom"
    static let animationDelay: TimeInterval = 0.7
    static let dismissDelay: TimeInterval = 0.3
}

class PlaybackSpeedCustomManager {
    static let shared = PlaybackSpeedCustomManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    var currentSpeedSetting: String {
        return userDefaults.object(forKey: kVLCSettingPlaybackSpeedDefaultValue) as? String ?? "1.0"
    }
    
    var customSpeedValue: Float {
        get {
            return userDefaults.float(forKey: PlaybackSpeedConfig.customSpeedKey)
        }
        set {
            userDefaults.set(newValue, forKey: PlaybackSpeedConfig.customSpeedKey)
        }
    }
    
    var effectiveSpeedValue: Float {
        if currentSpeedSetting == "custom" {
            return customSpeedValue
        }
        
        let presetSpeedValue = userDefaults.float(forKey: kVLCSettingPlaybackSpeedDefaultValue)
        if presetSpeedValue > 0 {
            return presetSpeedValue
        }
        
        if let floatValue = Float(currentSpeedSetting) {
            return floatValue
        }
        return 1.0
    }
    
    func setSpeedSetting(_ value: String) {
        userDefaults.set(value, forKey: kVLCSettingPlaybackSpeedDefaultValue)
    }
    
    func validateAndClampSpeed(_ speed: Float) -> Float {
        return min(max(speed, PlaybackSpeedConfig.minSpeed), PlaybackSpeedConfig.maxSpeed)
    }
}

enum UIUtils {
    static func findTopViewController() -> UIViewController? {
        var keyWindow: UIWindow?
        
        #if os(visionOS)
        keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        #else
        if #available(iOS 13.0, *) {
            keyWindow = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            keyWindow = UIApplication.shared.keyWindow
        }
        #endif
        
        guard let window = keyWindow,
              let rootVC = window.rootViewController else {
            return nil
        }
        
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        
        return topVC
    }
    
    static func createToolbar() -> UIToolbar {
        let width: CGFloat
        #if os(visionOS)
        width = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.coordinateSpace.bounds.width ?? 1280
        #else
        width = UIScreen.main.bounds.width
        #endif
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: width, height: 44))
        toolBar.barStyle = PresentationTheme.current.colors.toolBarStyle
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.items = [flexSpace]
        return toolBar
    }
}

class CustomSpeedInputHandler {
    private weak var currentAlertController: UIAlertController?
    
    func presentCustomSpeedInput() {
        guard let topVC = UIUtils.findTopViewController() else {
            print("Failed to find top view controller for presenting alert")
            return
        }
        
        let cancelButton = VLCAlertButton(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)
        let saveButton = VLCAlertButton(title: NSLocalizedString("BUTTON_SAVE", comment: ""), style: .default) { [weak self] action in
            self?.handleSaveAction()
        }
        
        let currentCustomSpeed = PlaybackSpeedCustomManager.shared.customSpeedValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        let textFieldText = currentCustomSpeed > 0 ? formatter.string(from: NSNumber(value: currentCustomSpeed)) : nil
        
        let alert = UIAlertController(
            title: NSLocalizedString("SETTINGS_CUSTOM_PLAYBACK_SPEED", comment: ""),
            message: NSLocalizedString("SETTINGS_CUSTOM_PLAYBACK_SPEED_MESSAGE", comment: ""),
            preferredStyle: .alert
        )
        
        self.currentAlertController = alert
        
        alert.addTextField { textField in
            textField.keyboardType = .decimalPad
            
            let placeholderFormatter = NumberFormatter()
            placeholderFormatter.numberStyle = .decimal
            placeholderFormatter.locale = Locale.current
            let placeholder = placeholderFormatter.string(from: NSNumber(value: 1.0)) ?? "1.0"
            textField.placeholder = placeholder
            textField.text = textFieldText
            
            #if !os(visionOS)
            textField.inputAccessoryView = UIUtils.createToolbar()
            #endif
        }
        
        let cancelAction = UIAlertAction(title: cancelButton.title, style: cancelButton.style, handler: cancelButton.action)
        let saveAction = UIAlertAction(title: saveButton.title, style: saveButton.style, handler: saveButton.action)
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        DispatchQueue.main.async {
            topVC.present(alert, animated: true) {
                alert.textFields?.first?.becomeFirstResponder()
            }
        }
    }
    
    private func parseLocalizedFloat(from text: String) -> Float? {
        let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        
        if let number = formatter.number(from: trimmedText) {
            return number.floatValue
        }
        
        let normalizedText = trimmedText.replacingOccurrences(of: ",", with: ".")
        if let floatValue = Float(normalizedText) {
            return floatValue
        }
        
        formatter.locale = Locale(identifier: "en_GB")
        if let number = formatter.number(from: normalizedText) {
            return number.floatValue
        }
        
        return nil
    }
    
    private func handleSaveAction() {
        guard let alertController = currentAlertController,
              let textField = alertController.textFields?.first,
              let text = textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
              !text.isEmpty else {
            showInvalidSpeedAlert()
            return
        }
        
        guard let speedValue = parseLocalizedFloat(from: text),
              speedValue >= PlaybackSpeedConfig.minSpeed,
              speedValue <= PlaybackSpeedConfig.maxSpeed else {
            showInvalidSpeedAlert()
            return
        }
        
        let speedManager = PlaybackSpeedCustomManager.shared
        speedManager.customSpeedValue = speedValue
        speedManager.setSpeedSetting("custom")
        
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
        
#if os(iOS)
        NotificationFeedbackGenerator().success()
#endif
    }
    
    private func showInvalidSpeedAlert() {
        guard let topVC = UIUtils.findTopViewController() else {
            return
        }
        
        let okButton = VLCAlertButton(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .default) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + PlaybackSpeedConfig.dismissDelay) {
                self?.presentCustomSpeedInput()
            }
        }
        
        VLCAlertViewController.alertViewManager(
            title: NSLocalizedString("ERROR", comment: ""),
            errorMessage: NSLocalizedString("SETTINGS_INVALID_SPEED_VALUE", comment: "Please enter a valid number between 0.25 and 8.0"),
            viewController: topVC,
            buttonsAction: [okButton]
        )
    }
}
