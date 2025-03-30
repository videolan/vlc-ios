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
        } else if let floatValue = Float(currentSpeedSetting) {
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
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.items = [flexSpace]
        return toolBar
    }
}

class CustomSpeedInputHandler {
    func presentCustomSpeedInput() {
        let alertController = UIAlertController(
            title: NSLocalizedString("SETTINGS_CUSTOM_PLAYBACK_SPEED", comment: ""),
            message: NSLocalizedString("SETTINGS_CUSTOM_PLAYBACK_SPEED_MESSAGE", comment: ""),
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.keyboardType = .decimalPad
            textField.placeholder = "1.0"
            
            #if !os(visionOS)
            textField.inputAccessoryView = UIUtils.createToolbar()
            #endif
            
            let currentCustomSpeed = PlaybackSpeedCustomManager.shared.customSpeedValue
            if currentCustomSpeed > 0 {
                textField.text = String(format: "%.2f", currentCustomSpeed)
            }
            
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)
        
        let saveAction = UIAlertAction(title: NSLocalizedString("BUTTON_SAVE", comment: ""), style: .default) { [weak alertController] _ in
            self.handleSaveAction(alertController: alertController)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        DispatchQueue.main.async {
            guard let topVC = UIUtils.findTopViewController() else {
                print("Failed to find top view controller for presenting alert")
                return
            }
            
            topVC.present(alertController, animated: true) {
                alertController.textFields?.first?.becomeFirstResponder()
            }
        }
    }
    
    private func handleSaveAction(alertController: UIAlertController?) {
        guard let textField = alertController?.textFields?.first,
              let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty,
              let speedValue = Float(text) else {
            showInvalidSpeedAlert()
            return
        }
        
        let clampedValue = PlaybackSpeedCustomManager.shared.validateAndClampSpeed(speedValue)
        
        PlaybackSpeedCustomManager.shared.customSpeedValue = clampedValue
        PlaybackSpeedCustomManager.shared.setSpeedSetting("custom")
        
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
        
#if os(iOS)
        NotificationFeedbackGenerator().success()
#endif
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else {
            textField.textColor = defaultTextColor()
            return
        }
        
        guard let speedValue = Float(text) else {
            textField.textColor = .systemRed
            return
        }
        
        let isValidRange = speedValue >= PlaybackSpeedConfig.minSpeed &&
                           speedValue <= PlaybackSpeedConfig.maxSpeed
        textField.textColor = isValidRange ? defaultTextColor() : .systemRed
    }
    
    private func defaultTextColor() -> UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }
    
    private func showInvalidSpeedAlert() {
        let errorAlert = UIAlertController(
            title: NSLocalizedString("ERROR", comment: ""),
            message: NSLocalizedString("SETTINGS_INVALID_SPEED_VALUE", comment: "Please enter a valid number between 0.25 and 8.0"),
            preferredStyle: .alert
        )
        
        errorAlert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .default) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + PlaybackSpeedConfig.dismissDelay) {
                self.presentCustomSpeedInput()
            }
        })
        
        DispatchQueue.main.async {
            UIUtils.findTopViewController()?.present(errorAlert, animated: true)
        }
    }
}


