/*****************************************************************************
 * PasscodeLockController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2020 VideoLAN. All rights reserved.
 *
 * Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
 *          Carola Nitz <caro # videolan.org>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import LocalAuthentication

enum PasscodeAction {
    case set
    case enter
}

protocol PasscodeLockControllerDelegate: AnyObject {
    func passcodeViewControllerDidEnterPassword(controller: PasscodeLockController)
}

class PasscodeLockController: UIViewController {

    static let passcodeService = "org.videolan.vlc-ios.passcode"
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = NotificationCenter.default
    private var tempPasscode = ""
    private var action: PasscodeAction?
    weak var delegate: PasscodeLockControllerDelegate?
    var passcode = ""

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        var tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(handleTap))

        return tapGestureRecognizer
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Enter a passcode", comment: "")
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = PresentationTheme.current.colors.cellTextColor
        return label
    }()

    let passcodeTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 40, weight: .heavy)
        textField.isSecureTextEntry = true
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

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

        if #available(iOS 11.0.1, *), laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            touchIDEnabled = touchIDEnabled && laContext.biometryType == .touchID
        }
        return touchIDEnabled
    }

    private var faceIDEnabled: Bool {
        var faceIDEnabled = userDefaults.bool(forKey: kVLCSettingPasscodeAllowFaceID)
        let laContext = LAContext()

        if #available(iOS 11.0.1, *), laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            faceIDEnabled = faceIDEnabled && laContext.biometryType == .faceID
        }
        return faceIDEnabled
    }

    convenience init?(action: PasscodeAction) {
        self.init()
        self.action = action
        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if action == .enter && !isBiometricsEnabled {
            passcodeTextField.becomeFirstResponder()
        }
    }

    private func setup() {
        contentStackView.addGestureRecognizer(tapGestureRecognizer)
        setupView()
        setupTheme()
        setupObservers()
    }

    @objc private func handleTap() {
        if !passcodeTextField.isFirstResponder {
            passcodeTextField.becomeFirstResponder()
        }
    }

// MARK: - Setup
    private func setupView() {
        if action == .set {
            self.title = NSLocalizedString("Set Passcode", comment: "")
        } else {
            self.title = NSLocalizedString("Enter Passcode", comment: "")
        }
        var guide: LayoutAnchorContainer = view.layoutMarginsGuide
         if #available(iOS 11.0, *) {
            guide = view.safeAreaLayoutGuide
         }
        passcodeTextField.widthAnchor.constraint(equalToConstant: 100).isActive = true
        contentStackView.addArrangedSubview(messageLabel)
        contentStackView.addArrangedSubview(passcodeTextField)
        view.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.centerYAnchor.constraint(equalTo: guide.centerYAnchor, constant: -40),
            contentStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 10),
            contentStackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -10)
        ])
        if action == .set {
            setupBarButton()
        }
        if !(action == .enter && isBiometricsEnabled) {
            //Shows keyboard if the biometrics is disabled
            passcodeTextField.becomeFirstResponder()
        }
    }

    private func setupBarButton() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                           target: self,
                                           action: #selector(dismissView))
        cancelButton.tintColor = PresentationTheme.current.colors.orangeUI
        self.navigationItem.rightBarButtonItem = cancelButton
    }

    private func setupObservers() {
        notificationCenter.addObserver(self,
                                       selector: #selector(setupTheme),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
        passcodeTextField.addTarget(self,
                                    action: #selector(textFieldDidChange(_:)),
                                    for: .editingChanged)
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
        passcodeTextField.textColor = PresentationTheme.current.colors.cellTextColor
        setNavBarAppearance()
    }

    @objc private func dismissView() {
        //If user dismisses the passcode view by pressing cancel the passcode lock should be disabled
        if #available(iOS 10, *) {
            ImpactFeedbackGenerator().selectionChanged()
        }
        userDefaults.set(false, forKey: kVLCSettingPasscodeOnKey)
        dismiss(animated: true)
    }

// MARK: - Logic
    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let passcodeText = passcodeTextField.text else { return }

        if passcodeTextField.text?.count == 4 {
            if action == .set {
                if tempPasscode == "" {
                    //Once this check succeeds temporary passcode is stored and asks for re entry
                    if #available(iOS 10, *) {
                        ImpactFeedbackGenerator().selectionChanged()
                    }
                    messageLabel.text = NSLocalizedString("Re-enter your passcode",
                                                          comment: "")
                    passcodeTextField.text = ""
                    tempPasscode = passcodeText
                } else {
                    if passcodeText == tempPasscode {
                        //Two time entry has matched. Save the password to keychain
                        do {
                            try PasscodeLockController.setPasscode(passcode: passcodeText)
                        } catch {
                            assertionFailure(error.localizedDescription)
                        }
                        if #available(iOS 10, *) {
                            NotificationFeedbackGenerator().success()
                        }
                        userDefaults.set(true, forKey: kVLCSettingPasscodeOnKey)
                        dismiss(animated: true)
                    } else {
                        if #available(iOS 10, *) {
                            NotificationFeedbackGenerator().error()
                        }
                        messageLabel.text = NSLocalizedString("Passcodes did not match. Try again.",
                                                              comment: "")
                        passcodeTextField.text = ""
                        tempPasscode = ""
                    }
                }
            }
            if action == .enter {
                if isPasscodeValid(passedPasscode: passcodeText) {
                    delegate?.passcodeViewControllerDidEnterPassword(controller: self)
                    if #available(iOS 10, *) {
                        ImpactFeedbackGenerator().selectionChanged()
                    }
                    messageLabel.text = NSLocalizedString("Enter a passcode",
                                                          comment: "")
                    passcodeTextField.text = ""
                } else {
                    if #available(iOS 10, *) {
                        NotificationFeedbackGenerator().error()
                    }
                    messageLabel.text = NSLocalizedString("Passcodes did not match. Try again.", comment: "")
                    passcodeTextField.text = ""
                }
            }
        }
    }

// MARK: - Keychain Password Helper Functions
    @objc class func setPasscode(passcode: String?) throws {
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

    private func isPasscodeValid(passedPasscode: String) -> Bool {
        return (passedPasscode == passcodeFromKeychain())
    }

    private func passcodeFromKeychain() -> String {
      do {
        let item = try XKKeychainGenericPasswordItem(forService: KeychainCoordinator.passcodeService, account: KeychainCoordinator.passcodeService)
        return item.secret.stringValue
      } catch let error {
        assert(false, "Couldn't retrieve item from Keychain! If passcodeLockEnabled we should have an item and secret. Error was \(error)")
        return ""
      }
    }
}
