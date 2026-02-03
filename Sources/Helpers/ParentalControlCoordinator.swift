//
//  ParentalControlCoordinator.swift
//  VLC
//
//  Created by Arthur Norat on 10/06/25.
//  Copyright © 2025 VideoLAN. All rights reserved.
//
import UIKit
import LocalAuthentication

class ParentalControlCoordinator: NSObject {

    @objc static let parentalControlService = KeychainCoordinator(serviceIdentifier: "org.videolan.vlc-ios.parentalControl")

    // MARK: - Singleton
    static let shared = ParentalControlCoordinator()

    @objc class func sharedInstance() -> ParentalControlCoordinator {
        return shared
    }

    // MARK: - Properties
    let keychain = parentalControlService
    var isEnabled: Bool {
        keychain.hasSecret
    }

    private let sessionDuration: TimeInterval = 30.0
    private let timestampKey = "ParentalControlLastUnlockTimestamp"

    // MARK: - Initializer
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods
    func authenticate(completion: @escaping (Bool) -> Void) {
        guard isEnabled else {
            completion(true)
            return
        }

        if isParentalControlUnlocked {
            updateTimestamp()
            completion(true)
            return
        }

        let shouldUseBiometricAuth = isBiometricAuthEnabled() && isBiometricAuthenticationEnabledByUser()

        keychain.validateSecret(allowBiometricAuthentication: shouldUseBiometricAuth,
                                isCancellable: true) { [weak self] success in
            if success {
                self?.updateTimestamp()
            }
            completion(success)
            print("Parental Control authentication \(success ? "succeeded" : "failed")")
        }

    }

    @objc public func authorizeIfParentalControlIsEnabled(action: @escaping @convention(block) () -> Void, fail: (@convention(block) () -> Void)? = nil) {
        if isEnabled {
            authenticate { success in
                if success {
                    print("Parental Control authentication succeeded, executing action")
                    action()
                } else {
                    fail?()
                }
            }
        } else {
            action()
        }
    }

    func enableParentalControl(completion: @escaping (Bool) -> Void) {
        keychain.setSecret(isCancellable: true) { [weak self] success in
            if success {
                self?.updateTimestamp()
            }
            completion(success)
        }
    }

    func disableParentalControl(completion: (() -> Void)? = nil) {
        guard isEnabled else {
            completion?()
            return
        }

        try? self.keychain.removeSecret()
        clearTimestamp()
        completion?()
    }

    var isParentalControlUnlocked: Bool {
        guard let lastUnlock = UserDefaults.standard.object(forKey: timestampKey) as? Date else {
            return false
        }
        let interval = Date().timeIntervalSince(lastUnlock)
        return interval < sessionDuration
    }

    func updateTimestamp() {
        UserDefaults.standard.set(Date(), forKey: timestampKey)
    }

    func clearTimestamp() {
        UserDefaults.standard.removeObject(forKey: timestampKey)
    }

    @objc func applicationWillEnterForeground() {
        if isEnabled && !isParentalControlUnlocked {
            clearTimestamp()
        }
    }

    private func isBiometricAuthEnabled() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    private func isBiometricAuthenticationEnabledByUser() -> Bool {
        return UserDefaults.standard.bool(forKey: kVLCSettingPasscodeEnableBiometricAuth)
    }
}
