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

class PasscodeLockController: UIViewController {
    // - MARK: Properties
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = NotificationCenter.default

    let action: PasscodeAction
    let keychainService: KeychainCoordinator

    var allowBiometricAuthentication: Bool = false
    var isCancellable: Bool = false

    /// The handler called on completion. On ``PasscodeAction/set`` action passcode provided if successfully set.
    /// Otherwise nil.
    var completionHandler: ((Bool, String?) -> Void)?

    private var tempPasscode = ""
    private var avoidPromptingBiometricAuth = false

    private var passcodeLength: Int {
        // If a passcode exists, return its length
        // Else return default length to set action.
        keychainService.hasSecret ? keychainService.secretLength : 4
    }

    // - MARK: Initiliazer
    init(
        action: PasscodeAction,
        keychainService: KeychainCoordinator,
        completionHandler: ((Bool, String?) -> Void)? = nil
    ) {
        self.action = action
        self.keychainService = keychainService
        self.completionHandler = completionHandler

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // - MARK: UI Elements
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

    /// This constraint will be used to center the passcode field
    private var passcodeFieldCenterYConstraint: NSLayoutConstraint!

    let passcodeField: PasscodeField = {
        let field = PasscodeField()
        field.translatesAutoresizingMaskIntoConstraints = false

        return field
    }()

    /// This constraint will be used to put options button top on keyboard
    private var passcodeOptionsButtonYConstraint: NSLayoutConstraint!

    private lazy var passcodeOptionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        button.setTitle(NSLocalizedString("Passcode Options", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(showPasscodeOptionsAlert), for: .touchUpInside)

        return button
    }()

    private lazy var passcodeOptionsAlert: UIAlertController = {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("4-Digit Numeric Code", comment: "Passcode 4 digit numeric code"),
                style: .default,
                handler: { _ in
                    self.passcodeField.maxLength = 4
                }
            )
        )

        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("6-Digit Numeric Code", comment: "Passcode 6 digit numeric code"),
                style: .default,
                handler: { _ in
                    self.passcodeField.maxLength = 6
                }
            )
        )

        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                style: .cancel,
                handler: nil
            )
        )

        return alert
    }()

    // - MARK: Gestures
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = .init(
        target: self,
        action: #selector(handleTap)
    )

    // - MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        passcodeField.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set passcode length
        passcodeField.maxLength = passcodeLength

        passcodeField.becomeFirstResponder()
    }

    override func viewDidAppear(_: Bool) {
        // The observer isn't triggering on launch
        // So we should also call here
        biometricAuthRequest()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Clear passcode field
        passcodeField.clear()

        // Hide failedLabel to reset
        failedLabel.isHidden = true

        // Reset
        avoidPromptingBiometricAuth = false

        passcodeField.resignFirstResponder()
    }

    // MARK: - Setup

    private func setup() {
        setupView()
        setupTheme()
        setupObservers()

        view.addGestureRecognizer(tapGestureRecognizer)
    }

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
        passcodeFieldCenterYConstraint = view.centerYAnchor.constraint(equalTo: passcodeField.centerYAnchor)

        NSLayoutConstraint.activate([
            // Put messageLabel top on passcodeField
            passcodeField.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 30),
            passcodeField.centerXAnchor.constraint(equalTo: messageLabel.centerXAnchor),
            // Put failedLabel bottom of passcodeField
            passcodeField.bottomAnchor.constraint(equalTo: failedLabel.topAnchor, constant: -30),
            passcodeField.centerXAnchor.constraint(equalTo: failedLabel.centerXAnchor),
            // Center passcodeField
            view.centerXAnchor.constraint(equalTo: passcodeField.centerXAnchor),
            passcodeFieldCenterYConstraint,
        ])

        if isCancellable {
            setupCancelButton()
        }

        if action == .set {
            setupPasscodeOptionsButton()
        }

        if #available(iOS 11, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }

    private func setupCancelButton() {
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(handleCancel)
        )

        cancelButton.tintColor = PresentationTheme.current.colors.orangeUI
        navigationItem.rightBarButtonItem = cancelButton
    }

    private func setupPasscodeOptionsButton() {
        view.addSubview(passcodeOptionsButton)

        let viewBottomAnchor: NSLayoutYAxisAnchor
        if #available(iOS 11, *) {
            viewBottomAnchor = self.view.safeAreaLayoutGuide.bottomAnchor
        } else {
            viewBottomAnchor = view.bottomAnchor
        }

        passcodeOptionsButtonYConstraint = viewBottomAnchor.constraint(
            equalTo: passcodeOptionsButton.bottomAnchor
        )

        NSLayoutConstraint.activate([
            // Center passcodeOptionsButton
            passcodeField.centerXAnchor.constraint(equalTo: passcodeOptionsButton.centerXAnchor),
            passcodeOptionsButtonYConstraint,
        ])
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    private func setNavBarAppearance() {
        if #available(iOS 13.0, *) {
            let navigationBarAppearance = AppearanceManager.navigationbarAppearance
            self.navigationController?.navigationBar.standardAppearance = navigationBarAppearance()
            self.navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance()
        }
    }

    // MARK: - Observers & Button Actions

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

        // Biometric auth observer
        notificationCenter.addObserver(
            self,
            selector: #selector(biometricAuthRequest),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // Application will terminate observer
        notificationCenter.addObserver(
            self,
            selector: #selector(handleApplicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc private func setupTheme() {
        view.backgroundColor = PresentationTheme.current.colors.background
        messageLabel.textColor = PresentationTheme.current.colors.cellTextColor
        setNavBarAppearance()
    }

    @objc private func handleTap() {
        if !passcodeField.isFirstResponder {
            passcodeField.becomeFirstResponder()
        }
    }

    @objc private func handleCancel() {
        completionHandler?(false, nil)

#if os(iOS)
        if #available(iOS 10, *) {
            ImpactFeedbackGenerator().selectionChanged()
        }
#endif

        dismiss(animated: true)
    }

    @objc private func showPasscodeOptionsAlert() {
        present(passcodeOptionsAlert, animated: true)
    }

    @objc private func handleApplicationWillTerminate() {
        completionHandler?(false, nil)
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

                // Hide passcode options
                passcodeOptionsButton.isHidden = true

#if os(iOS)
                if #available(iOS 10, *) {
                    ImpactFeedbackGenerator().selectionChanged()
                }
#endif
            } else {
                if passcode == tempPasscode {
                    // Just for cosmetic
                    failedLabel.isHidden = true

                    // Two time entry has matched. Call completionHandler with success and passcode.
                    completionHandler?(true, passcode)

#if os(iOS)
                    if #available(iOS 10, *) {
                        NotificationFeedbackGenerator().success()
                    }
#endif

                    dismiss(animated: true)
                } else {
                    // Update label
                    failedLabel.isHidden = false

                    // Clear passcode field
                    passcodeField.clear()

#if os(iOS)
                    if #available(iOS 10, *) {
                        NotificationFeedbackGenerator().error()
                    }
#endif
                }
            }
        case .enter:
            if keychainService.isSecretValid(passcode) {
                // Call completion handler with success but don't give passcode
                completionHandler?(true, nil)

#if os(iOS)
                if #available(iOS 10, *) {
                    ImpactFeedbackGenerator().selectionChanged()
                }
#endif

                dismiss(animated: true)
            } else {
                // Show failed label
                failedLabel.isHidden = false

                // Clear passcode field
                passcodeField.clear()

#if os(iOS)
                if #available(iOS 10, *) {
                    NotificationFeedbackGenerator().error()
                }
#endif
            }
        }
    }
}

// MARK: - Biometric Authentication Helpers

extension PasscodeLockController {
    var isBiometricAuthEnabled: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    @objc private func biometricAuthRequest() {
        guard action == .enter, // action is enter
              view.window != nil, // view controller is presented and visible
              isBiometricAuthEnabled, // biometric auth is enabled from system settings
              allowBiometricAuthentication, // biometric authentication allowed from user in app
              !avoidPromptingBiometricAuth, // there is no already showing auth view
              UIApplication.shared.applicationState == .active, // the app is active state
              keychainService.hasSecret
        else { return }

        avoidPromptingBiometricAuth = true

        let context = LAContext()

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: NSLocalizedString("BIOMETRIC_UNLOCK", comment: "")
        ) { [weak self] success, _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if success {
                    self.avoidPromptingBiometricAuth = false

                    // Dismiss and call completion handler
                    self.dismiss(animated: true) {
                        self.completionHandler?(true, nil)
                    }
                } else {
                    self.avoidPromptingBiometricAuth = true

                    // User hit cancel and wants to enter the passcode
                    self.passcodeField.becomeFirstResponder()
                }
            }
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
        let coordinateFromTop: CGFloat

        if let navigationController = navigationController {
            coordinateFromTop = navigationController.navigationBar.frame.maxY
        } else if #available(iOS 11, *) {
            coordinateFromTop = view.safeAreaInsets.top
        } else {
            coordinateFromTop = 0
        }

        // The coordinate of keyboard's top edge
        let keyboardTopCoordinate = keyboardSize.minY

        // Find the center coordinate of visible area while keyboard is showing.
        let centerY = (view.bounds.height - keyboardTopCoordinate - coordinateFromTop) / 2
        passcodeFieldCenterYConstraint.constant = max(centerY, 0)

        // Update passcode options y constraint
        if action == .set {
            passcodeOptionsButtonYConstraint.constant = keyboardSize.height
        }

        view.layoutIfNeeded()
    }

    @objc func keyboardWillHide(_: Notification) {
        // Update passcode options y constraint
        if action == .set {
            passcodeOptionsButtonYConstraint.constant = 0
        }

        view.layoutIfNeeded()
    }
}
