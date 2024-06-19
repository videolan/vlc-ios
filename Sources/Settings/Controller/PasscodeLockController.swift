/*****************************************************************************
 * PasscodeLockController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2020 VideoLAN. All rights reserved.
 *
 * Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
 *          Carola Nitz <caro # videolan.org>
 *        İbrahim Çetin <mail # ibrahimcetin.dev>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import LocalAuthentication
import UIKit

// MARK: - PasscodeAction

enum PasscodeAction {
    case set
    case enter
}

// MARK: - PasscodeLockControllerDelegate

protocol PasscodeLockControllerDelegate: AnyObject {
    func passcodeViewControllerDidEnterPassword(controller: PasscodeLockController)
}

// MARK: - PasscodeLockController

class PasscodeLockController: UIViewController {
    static let passcodeService = "org.videolan.vlc-ios.passcode"

    private let userDefaults = UserDefaults.standard
    private let notificationCenter = NotificationCenter.default

    let action: PasscodeAction
    weak var delegate: PasscodeLockControllerDelegate?

    private var tempPasscode = ""

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        return tapGestureRecognizer
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        label.text = NSLocalizedString("Enter a passcode", comment: "")
        label.textColor = PresentationTheme.current.colors.cellTextColor

        return label
    }()

    private let failedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        label.text = NSLocalizedString("Passcodes did not match. Try again.", comment: "")
        label.textColor = .systemRed

        label.isHidden = true

        return label
    }()

    let passcodeField: PasscodeField = {
        let field = PasscodeField()
        field.translatesAutoresizingMaskIntoConstraints = false

        return field
    }()

    /// This constraint will use to center the passcode stack view
    private var passcodeCenterYConstraint: NSLayoutConstraint!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    private var isBiometricsEnabled: Bool {
        return faceIDEnabled || touchIDEnabled
    }

    // Since FaceID and TouchID are both set to 1 when the defaults are registered
    // we have to double check for the biometry type to not return true even though the setting is not visible
    // and that type is not supported by the device
    private var touchIDEnabled: Bool {
        var touchIDEnabled = userDefaults.bool(forKey: kVLCSettingPasscodeAllowTouchID)
        let laContext = LAContext()

        if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            touchIDEnabled = touchIDEnabled && laContext.biometryType == .touchID
        }
        return touchIDEnabled
    }

    private var faceIDEnabled: Bool {
        var faceIDEnabled = userDefaults.bool(forKey: kVLCSettingPasscodeAllowFaceID)
        let laContext = LAContext()

        if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            faceIDEnabled = faceIDEnabled && laContext.biometryType == .faceID
        }
        return faceIDEnabled
    }

    init(action: PasscodeAction) {
        self.action = action
        super.init(nibName: nil, bundle: nil)

        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        passcodeField.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        passcodeField.becomeFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Clear passcode field
        passcodeField.clear()

        // Hide failedLabel to reset
        failedLabel.isHidden = true

        passcodeField.resignFirstResponder()
    }

    private func presentPasscodeLengthSelection() {
        present(passcodeLengthAlertController, animated: true, completion: nil)
    }

    // MARK: - Setup

    private func setup() {
        setupView()
        setupTheme()
        setupObservers()

        view.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func handleTap() {
        if !passcodeField.isFirstResponder {
            passcodeField.becomeFirstResponder()
        }
    }

    // MARK: - Setup

    private func setupView() {
        // Set the title
        switch action {
        case .set:
            title = NSLocalizedString("Set Passcode", comment: "")
        case .enter:
            title = NSLocalizedString("Enter Passcode", comment: "")
            messageLabel.text = NSLocalizedString("Enter your passcode", comment: "")
        }

        view.addSubview(messageLabel)
        view.addSubview(passcodeField)
        view.addSubview(failedLabel)

        // Create center y constraint
        passcodeCenterYConstraint = view.centerYAnchor.constraint(equalTo: passcodeField.centerYAnchor)

        NSLayoutConstraint.activate([
            // Put messageLabel top on passcodeField
            passcodeField.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 30),
            passcodeField.centerXAnchor.constraint(equalTo: messageLabel.centerXAnchor),
            // Put failedLabel bottom of passcodeField
            passcodeField.bottomAnchor.constraint(equalTo: failedLabel.topAnchor, constant: -30),
            passcodeField.centerXAnchor.constraint(equalTo: failedLabel.centerXAnchor),
            // Center passcodeField
            view.centerXAnchor.constraint(equalTo: passcodeField.centerXAnchor),
            passcodeCenterYConstraint,
        ])

        if action == .set {
            setupBarButton()
        }

        if #available(iOS 11, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }

    private func setupBarButton() {
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissView)
        )

        cancelButton.tintColor = PresentationTheme.current.colors.orangeUI
        navigationItem.rightBarButtonItem = cancelButton
    }

    private func setupObservers() {
        // Theme change observer
        notificationCenter.addObserver(
            self,
            selector: #selector(setupTheme),
            name: .VLCThemeDidChangeNotification,
            object: nil
        )

        // Keyboard observers
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setNavBarAppearance() {
        if #available(iOS 13.0, *) {
            let navigationBarAppearance = AppearanceManager.navigationbarAppearance
            self.navigationController?.navigationBar.standardAppearance = navigationBarAppearance()
            self.navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance()
        }
    }

    // MARK: - Observer & Bar Button Actions

    @objc private func setupTheme() {
        view.backgroundColor = PresentationTheme.current.colors.background
        messageLabel.textColor = PresentationTheme.current.colors.cellTextColor
        setNavBarAppearance()
    }

    @objc private func dismissView() {
        // If user dismisses the passcode view by pressing cancel the passcode lock should be disabled
        ImpactFeedbackGenerator().selectionChanged()
        userDefaults.set(false, forKey: kVLCSettingPasscodeOnKey)
        dismiss(animated: true)
    }
}

// MARK: - Logic

extension PasscodeLockController: PasscodeFieldDelegate {
    func passcodeFieldDidEnterPasscode(_ passcodeField: PasscodeField, _ passcode: String) {
        switch action {
        case .set:
            if tempPasscode.isEmpty {
                // The passcode will store in tempPasscode and will be used to confirm re-entered code
                tempPasscode = passcode

                // Clear passcode field
                passcodeField.clear()

                // Update label
                messageLabel.text = NSLocalizedString("Re-enter your passcode", comment: "")

                if #available(iOS 10, *) {
                    ImpactFeedbackGenerator().selectionChanged()
                }
            } else {
                if passcode == tempPasscode {
                    // Just for cosmetic
                    failedLabel.isHidden = true

                    // Two time entry has matched. Save the password to keychain
                    do {
                        try PasscodeLockController.setPasscode(passcode: passcode)
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }

                    // Set passcode on
                    userDefaults.set(true, forKey: kVLCSettingPasscodeOnKey)

                    if #available(iOS 10, *) {
                        NotificationFeedbackGenerator().success()
                    }

                    dismiss(animated: true)
                } else {
                    // Update label
                    failedLabel.isHidden = false

                    // Clear passcode field
                    passcodeField.clear()

                    if #available(iOS 10, *) {
                        NotificationFeedbackGenerator().error()
                    }
                }
            }
        case .enter:
            if isPasscodeValid(passedPasscode: passcode) {
                // Call the delegate method
                delegate?.passcodeViewControllerDidEnterPassword(controller: self)

                if #available(iOS 10, *) {
                    ImpactFeedbackGenerator().selectionChanged()
                }
            } else {
                // Update label
                failedLabel.isHidden = false

                // Clear passcode field
                passcodeField.clear()

                if #available(iOS 10, *) {
                    NotificationFeedbackGenerator().error()
                }
            }
        }
    }
}

// MARK: - Keychain Password Helper Functions

extension PasscodeLockController {
    @objc class func setPasscode(passcode: String?) throws {
        guard let passcode = passcode else {
            do {
                try XKKeychainGenericPasswordItem.removeItems(forService: passcodeService)
            } catch {
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
        } catch {
            throw error
        }
    }

    private func isPasscodeValid(passedPasscode: String) -> Bool {
        return passedPasscode == passcodeFromKeychain()
    }

    private func passcodeFromKeychain() -> String {
        do {
            let item = try XKKeychainGenericPasswordItem(forService: KeychainCoordinator.passcodeService, account: KeychainCoordinator.passcodeService)
            return item.secret.stringValue
        } catch {
            assertionFailure("Couldn't retrieve item from Keychain! If passcodeLockEnabled we should have an item and secret. Error was \(error)")
            return ""
        }
    }
}

// MARK: - Keyboard Observer Functions

extension PasscodeLockController {
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }

        let keyboardSize = keyboardValue.cgRectValue

        // The used area's bottom edge coordinate from top
        let coordinateFromTop: CGFloat = if let navigationController {
            navigationController.navigationBar.frame.maxY
        } else if #available(iOS 11, *) {
            view.safeAreaInsets.top
        } else {
            0
        }

        // The coordinate of keyboard's top edge
        let keyboardTopCoordinate = keyboardSize.minY

        // Find the center coordinate of visible area while keyboard is showing.
        let centerY = (view.bounds.height - keyboardTopCoordinate - coordinateFromTop) / 2
        passcodeCenterYConstraint.constant = max(centerY, 0)

        view.layoutIfNeeded()
    }

    @objc func keyboardWillHide(_: Notification) {
        passcodeCenterYConstraint.constant = 0
        view.layoutIfNeeded()
    }
}
