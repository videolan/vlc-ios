/*****************************************************************************
 * KeychainCoordinator.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors:Carola Nitz <caro # videolan.org>
 *          Swapnanil Dhol<swapnanildhol # gmail.com>
 *       İbrahim Çetin <mail # ibrahimcetin.dev>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import LocalAuthentication

@objc(VLCKeychainCoordinator)
class KeychainCoordinator: NSObject {
    // Shared instance of passcodeService
    @objc static let passcodeService = KeychainCoordinator(serviceIdentifier: "org.videolan.vlc-ios.passcode")

    let serviceIdentifier: String

    init(serviceIdentifier: String) {
        self.serviceIdentifier = serviceIdentifier
    }

    @objc var hasSecret: Bool {
        // If there is a passcode in keychain, passcode is enabled
        return secretFromKeychain != nil
    }

    private var secretFromKeychain: String? {
        let item = try? XKKeychainGenericPasswordItem(forService: serviceIdentifier, account: serviceIdentifier)
        return item?.secret.stringValue
    }

    func setSecret(_ secret: String) throws {
        let keychainItem = XKKeychainGenericPasswordItem()
        keychainItem.service = serviceIdentifier
        keychainItem.account = serviceIdentifier
        keychainItem.secret.stringValue = secret

        try? keychainItem.save()
    }

    func removeSecret() throws {
        try XKKeychainGenericPasswordItem.removeItems(forService: serviceIdentifier)
    }

    func isSecretValid(_ secret: String) -> Bool {
        secret == secretFromKeychain
    }

    var secretLength: Int {
        secretFromKeychain?.count ?? 0
    }
}

// - MARK: Helper methods

extension KeychainCoordinator {
    func setSecretView(completion: @escaping () -> Void) {
        showPasscodeController(action: .set) { [weak self] secret in
            guard let self else { return }

            if let secret {
                try? setSecret(secret)
            } else {
                // if cancelled remove secret
                try? removeSecret()
            }

            completion()
        }
    }

    @objc func validateSecret(completion: @escaping () -> Void) {
        guard hasSecret else { return }

        showPasscodeController(action: .enter) { _ in
            completion()
        }
    }

    /// The handler called on completion. On ``PasscodeAction/set`` action passcode provided. Otherwise nil.
    private func showPasscodeController(action: PasscodeAction, completion: @escaping (String?) -> Void) {
        // Check if a presentingViewController exists and passcode not already showing
        guard let presentingViewController, !isPasscodeControllerPresenting else { return }

        let passcodeController = PasscodeLockController(action: action, keychainService: self) { secret in
            completion(secret)
        }

        let passcodeNavigationController = UINavigationController(rootViewController: passcodeController)
        passcodeNavigationController.modalPresentationStyle = .fullScreen
        passcodeNavigationController.modalTransitionStyle = .crossDissolve

        presentingViewController.present(passcodeNavigationController, animated: true)
    }

    private var presentingViewController: UIViewController? {
        guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController else {
            return nil
        }

        // if we have no video displayed we should use the current rootViewController
        var presentingViewController = rootViewController
        // If playing a video, show the passcode view above the player.
        if let playerViewController = rootViewController.presentedViewController {
            presentingViewController = playerViewController
            // Check if the player is showing any modals.
            if let modal = playerViewController.presentedViewController {
                presentingViewController = modal
            }
        }

        return presentingViewController
    }

    private var isPasscodeControllerPresenting: Bool {
        guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController else {
            return false
        }

        // TODO: Find an array of the given view controller type instead of one
        if rootViewController.findViewController(ofType: PasscodeLockController.self) != nil {
            return true
        }

        return false
    }
}
