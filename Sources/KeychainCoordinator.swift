/*****************************************************************************
 * KeychainCoordinator.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors:Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import LocalAuthentication

@objc(VLCKeychainCoordinator)
class KeychainCoordinator:NSObject, PAPasscodeViewControllerDelegate {

    @objc class var passcodeLockEnabled:Bool {
        return UserDefaults.standard.bool(forKey:kVLCSettingPasscodeOnKey)
    }

    //Since FaceID and TouchID are both set to 1 when the defaults are registered
    //we have to double check for the biometry type to not return true even though the setting is not visible
    //and that type is not supported by the device
    private var touchIDEnabled:Bool {
        var touchIDEnabled = UserDefaults.standard.bool(forKey:kVLCSettingPasscodeAllowTouchID)
        let laContext = LAContext()

        if #available(iOS 11.0.1, *), laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            touchIDEnabled = touchIDEnabled && laContext.biometryType == .touchID
        }
        return touchIDEnabled
    }
    private var faceIDEnabled:Bool {
        var faceIDEnabled = UserDefaults.standard.bool(forKey:kVLCSettingPasscodeAllowFaceID)
        let laContext = LAContext()

        if #available(iOS 11.0.1, *), laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            faceIDEnabled = faceIDEnabled && laContext.biometryType == .faceID
        }
        return faceIDEnabled
    }

    static let passcodeService = "org.videolan.vlc-ios.passcode"

    var completion: (() -> ())? = nil

    private var avoidPromptingTouchOrFaceID = false

    private lazy var passcodeLockController:PAPasscodeViewController = {
        let passcodeController = PAPasscodeViewController(for: PasscodeActionEnter)
        passcodeController!.delegate = self
        return passcodeController!
    }()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(appInForeground), name: .UIApplicationDidBecomeActive, object: nil)
    }

    @objc class func setPasscode(passcode:String?) throws {
        guard let passcode = passcode else {
            do {
                try XKKeychainGenericPasswordItem.removeItems(forService: passcodeService)
            } catch let error {
                throw error
            }
            return
        }
        let keychainItem = XKKeychainGenericPasswordItem()
        keychainItem.service = passcodeService
        keychainItem.account = passcodeService
        keychainItem.secret.stringValue = passcode
        do {
            try keychainItem.save()
        } catch let error {
            throw error
        }
    }

    @objc func validatePasscode(completion:@escaping ()->()) {
        passcodeLockController.passcode = passcodeFromKeychain()
        self.completion = completion
        guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController, passcodeLockController.passcode != "" else {
            self.completion?()
            self.completion = nil
            return
        }
        if rootViewController.presentedViewController != nil {
            rootViewController.dismiss(animated: false, completion: nil)
        }

        let navigationController = UINavigationController(rootViewController: passcodeLockController)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .crossDissolve

        rootViewController.present(navigationController, animated: true) {
            [weak self] in
            if (self?.touchIDEnabled == true || self?.faceIDEnabled == true) {
                self?.touchOrFaceIDQuery()
            }
        }
    }

    @objc private func appInForeground(notification:Notification) {
        if let navigationController = UIApplication.shared.delegate?.window??.rootViewController?.presentedViewController as? UINavigationController, navigationController.topViewController is PAPasscodeViewController,
            touchIDEnabled || faceIDEnabled {
            touchOrFaceIDQuery()
        }
    }

    private func touchOrFaceIDQuery() {
        if (avoidPromptingTouchOrFaceID || UIApplication.shared.applicationState != .active) {
            return
        }

        let laContext = LAContext()

        if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil){
            avoidPromptingTouchOrFaceID = true
            laContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                     localizedReason: NSLocalizedString("BIOMETRIC_UNLOCK", comment: ""),
                                     reply: { [weak self ] success, _ in
                                        DispatchQueue.main.async {
                                            if success {
                                                UIApplication.shared.delegate?.window??.rootViewController?.dismiss(animated: true, completion: {
                                                    self?.completion?()
                                                    self?.completion = nil
                                                    self?.avoidPromptingTouchOrFaceID = false
                                                })
                                            } else {
                                                //user hit cancel and wants to enter the passcode
                                                self?.avoidPromptingTouchOrFaceID = true
                                            }
                                        }
            })
        }
    }

    private func passcodeFromKeychain() -> String {
        if let item = try? XKKeychainGenericPasswordItem(forService: KeychainCoordinator.passcodeService, account: KeychainCoordinator.passcodeService) {
            return item.secret.stringValue
        }
        assert(false, "Couldn't retrieve item from Keychain! If passcodeLockEnabled we should have an item and secret")
        return ""
    }

    //MARK: PAPassCodeDelegate
    func paPasscodeViewControllerDidEnterPasscode(_ controller: PAPasscodeViewController!) {
        avoidPromptingTouchOrFaceID = false
        UIApplication.shared.delegate?.window??.rootViewController?.dismiss(animated: true, completion: {
            self.completion?()
            self.completion = nil
        })
    }

}
