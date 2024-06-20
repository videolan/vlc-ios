//
//  PasscodeView.swift
//  VLC-iOS
//
//  Created by İbrahim Çetin on 19.06.2024.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import UIKit

protocol PasscodeFieldDelegate: AnyObject {
    func passcodeFieldDidEnterPasscode(_ passcodeField: PasscodeField, _ passcode: String)
}

class PasscodeField: UIView {
    /// Passcode the user entered
    ///
    /// To clear passcode call ``clear()``
    private(set) var passcode: String = "" {
        didSet {
            updateUI()

            if passcode.count == maxLength {
                delegate?.passcodeFieldDidEnterPasscode(self, passcode)
            }
        }
    }

    var maxLength: Int = 4 {
        didSet {
            createPins()

            clear()
        }
    }

    weak var delegate: (any PasscodeFieldDelegate)?

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.spacing = 25
        stackView.axis = .horizontal

        return stackView
    }()

    private var pins = [PinView]()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        createPins()

        self.addSubview(stackView)

        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: stackView.topAnchor),
            self.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

    private func createPins() {
        // Clear stack view
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        // Create pins and add to stack view
        pins = (0..<maxLength).map { _ in
            let pin = PinView()

            stackView.addArrangedSubview(pin)

            return pin
        }
    }

    private func updateUI() {
        for index in 0..<maxLength {
            pins[index].isEmpty = !(passcode.count > index)
        }
    }

    func clear() {
        passcode = ""
    }

    override var canBecomeFirstResponder: Bool {
        true
    }
}

extension PasscodeField: UIKeyInput {
    var hasText: Bool {
        return !passcode.isEmpty
    }

    func insertText(_ text: String) {
        guard passcode.appending(text).count <= maxLength else { return }

        passcode.append(text)
    }

    func deleteBackward() {
        guard hasText else { return }

        passcode.removeLast()
    }

    var keyboardType: UIKeyboardType {
        get {
            .numberPad
        }
        set { /* Nothing */ }
    }

    var isSecureTextEntry: Bool {
        get {
            true
        }
        set { /* Nothing */ }
    }
}

class PinView: UIView {
    var isEmpty: Bool {
        get {
            self.backgroundColor == .clear
        }

        set {
            // Fill the pin if it is not empty
            self.backgroundColor = newValue ? .clear : color
        }
    }

    private var color: UIColor {
        PresentationTheme.current.colors.cellTextColor
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.layer.borderWidth = 1
        self.layer.borderColor = color.cgColor

        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: 20),
            self.widthAnchor.constraint(equalToConstant: 20),
        ])
    }

    override func layoutSubviews() {
        self.layer.cornerRadius = self.bounds.width / 2
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Update border color manually
        self.layer.borderColor = color.cgColor
    }
}
