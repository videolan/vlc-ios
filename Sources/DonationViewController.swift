/*****************************************************************************
 * DonationViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import PassKit

@objc class DonationViewController: UIViewController {

    private var bottomConstraint: NSLayoutConstraint?
    private var minBottomConstraint: NSLayoutConstraint?
    private var mainstackView: UIStackView!
    private let donationAmount = UITextField(frame: .zero)
    private let keyboard = UIButton(type: .custom)
    private let backgroundView = UIView(frame: .zero)
    private let donationTitle = UILabel(frame: .zero)
    private let separator = UIView(frame: .zero)
    private let separator2 = UIView(frame: .zero)
    private var paymentButton: PKPaymentButton?
    private var buttons: [UIButton]?
    private var keyboardFrame = CGRect.zero

    lazy var header: UIStackView = {
        let closebutton = UIButton(type: .custom)
        closebutton.setImage( UIImage(named: "close"), for: .normal)
        closebutton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)

        donationTitle.font = .boldSystemFont(ofSize: 13)
        donationTitle.text = NSLocalizedString("DONATE", comment: "")

        let donationStackview = UIStackView(arrangedSubviews: [donationTitle, closebutton])
        return donationStackview
    }()

    lazy var donationAmountView: UIStackView = {
        let donation = UILabel(frame: .zero)
        donation.font = .boldSystemFont(ofSize: 13)
        donation.text = NSLocalizedString("DONATION_AMOUNT", comment: "")
        donation.textColor = PresentationTheme.current.colors.cellDetailTextColor
        donation.setContentHuggingPriority(.required, for: .horizontal)

        donationAmount.font = .boldSystemFont(ofSize: 28)
        donationAmount.text = numberFormatter.string(from: 5.0)
        donationAmount.keyboardType = .decimalPad
        donationAmount.delegate = self
        donationAmount.textAlignment = .right

        let donationStackview = UIStackView(arrangedSubviews: [donation, donationAmount])
        donationStackview.alignment = .bottom
        return donationStackview
    }()

    lazy var donationButtons: UIStackView = {
        let ten = amountButton(amount: NSNumber(value: 10.0))
        let twenty = amountButton(amount: NSNumber(value: 20.0))
        let fifty = amountButton(amount:NSNumber(value: 50.0))
        keyboard.addTarget(self, action: #selector(toggleKeyboard), for: .touchUpInside)
        keyboard.sizeToFit()
        keyboard.layer.cornerRadius = keyboard.frame.size.height / 2.0
        keyboard.layer.borderWidth = 1.0
        buttons = [ten, twenty, fifty, keyboard]
        let donationStackview = UIStackView(arrangedSubviews: buttons!)
        donationStackview.spacing = 16
        donationStackview.distribution = .fillEqually
        return donationStackview
    }()

    lazy var numberFormatter = { () -> NumberFormatter in
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupDarkOverlayView()
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
        createSubViews()
        updateTheme()

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupDarkOverlayView() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissVC))
        view.addGestureRecognizer(tapRecognizer)
        view.alpha = 0
    }

    func createSubViews() {

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(backgroundView)

        mainstackView = UIStackView(arrangedSubviews: [header, separator, donationAmountView, separator2, donationButtons] )
        mainstackView.axis = .vertical
        mainstackView.translatesAutoresizingMaskIntoConstraints = false

        backgroundView.addSubview(mainstackView)
        mainstackView.layoutIfNeeded()
        mainstackView.spacing = 10.0

        bottomConstraint = backgroundView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: mainstackView.frame.size.height)
        minBottomConstraint = mainstackView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        updateViewForPosition(to: .hidden)
        NSLayoutConstraint.activate([
            mainstackView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 10),
            mainstackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 20),
            mainstackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -20),
            minBottomConstraint!,
            backgroundView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0),
            separator2.heightAnchor.constraint(equalToConstant: 1.0),
            bottomConstraint!
            ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        roundTopCorners()
    }

    private func roundTopCorners() {
        if #available(iOS 11.0, *) {
            backgroundView.clipsToBounds = false
            backgroundView.layer.cornerRadius = 10
            backgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            let rectShape = CAShapeLayer()
            rectShape.bounds = backgroundView.frame
            rectShape.position = backgroundView.center
            rectShape.path = UIBezierPath(roundedRect: backgroundView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 20, height: 20)).cgPath
            backgroundView.layer.mask = rectShape
        }
    }

    private func amountButton(amount: NSNumber) -> UIButton {
        let button = UIButton(type: .roundedRect)
        button.addTarget(self, action: #selector(setDonationAmount), for: .touchUpInside)
        button.setTitle(numberFormatter.string(from: amount), for: .normal)
        button.setTitleColor(PresentationTheme.current.colors.orangeUI, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)

        button.sizeToFit()
        button.layer.cornerRadius = button.frame.size.height / 2.0
        button.layer.borderWidth = 1.0

        return button
    }

    func setupPayButton() {
        let style: PKPaymentButtonStyle = PresentationTheme.current == PresentationTheme.darkTheme ? .white : .black
        paymentButton?.removeFromSuperview()
        if #available(iOS 10.2, *) {
            paymentButton = PKPaymentButton(paymentButtonType: .donate, paymentButtonStyle: style)
        } else {
            paymentButton = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: style)
        }
        mainstackView.addArrangedSubview(paymentButton!)
        NSLayoutConstraint.activate([paymentButton!.heightAnchor.constraint(equalToConstant: 44)])
    }

    @objc func updateTheme() {
        backgroundView.backgroundColor = PresentationTheme.current.colors.background
        donationAmount.textColor = PresentationTheme.current.colors.cellTextColor
        donationTitle.textColor = PresentationTheme.current.colors.cellTextColor
        separator.backgroundColor = PresentationTheme.current.colors.mediaCategorySeparatorColor
        separator2.backgroundColor = PresentationTheme.current.colors.mediaCategorySeparatorColor
        buttons?.forEach() { $0.layer.borderColor = PresentationTheme.current.colors.mediaCategorySeparatorColor.cgColor }
        setupPayButton()
        updateKeyboardButton()
    }

    @objc func toggleKeyboard() {
        _ = donationAmount.isFirstResponder ? donationAmount.resignFirstResponder() : donationAmount.becomeFirstResponder()
        updateKeyboardButton()
    }

    func updateKeyboardButton() {
        let whiteImage = donationAmount.isFirstResponder ? UIImage(named: "keyboardDownWhite") : UIImage(named: "keyboardUpWhite")
        let darkImage = donationAmount.isFirstResponder ? UIImage(named: "keyboardDownDark") : UIImage(named: "keyboardUpDark")
        let isDarkTheme = PresentationTheme.current == PresentationTheme.darkTheme
        keyboard.setImage(isDarkTheme ? darkImage : whiteImage, for: .normal)
    }

    // MARK: view positioning

    enum viewPosition {
        case bottom, hidden, keyboardVisible
    }

    func updateViewForPosition(to positon: viewPosition) {
        minBottomConstraint?.constant = -20
        switch positon {
        case .bottom:
            bottomConstraint?.constant = 0
            if #available(iOS 11.0, *) {
                minBottomConstraint?.constant -= view.safeAreaInsets.bottom
            }
        case .hidden:
            bottomConstraint?.constant = mainstackView.frame.size.height
        case .keyboardVisible:
            bottomConstraint?.constant = -keyboardFrame.size.height
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
        updateKeyboardButton()
    }

    @objc func keyboardWillBeShown(notification: Notification) {
        let userInfo = notification.userInfo
        keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        updateViewForPosition(to: .keyboardVisible)
    }

    @objc func keyboardWillBeHidden(notification: Notification) {
        updateViewForPosition(to: .bottom)
    }

    @objc func setDonationAmount(sender: UIButton) {
        donationAmount.text = sender.titleLabel?.text
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if view.alpha == 1 {
            return
        }
        updateViewForPosition(to: .bottom)
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 1
        })
    }

    @objc func dismissVC() {
        updateViewForPosition(to: .hidden)
        UIView.animate(withDuration: 0.3,
                       animations: {
                        self.view.alpha = 0
        }) { _ in
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension DonationViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let currentText = textField.text ?? ""
        let replacementText = (currentText as NSString).replacingCharacters(in: range, with: string)

        return isValidAmount(amount: replacementText)
    }

    // make sure that the new string doesn't remove the currency symbol and is valid pay amount being not negative & max 2 digits
    private func isValidAmount(amount: String) -> Bool {
        var amountWithoutCurrency = amount

        guard self.numberFormatter.number(from: amountWithoutCurrency) != nil else {
            return false //don't enter letters
        }

        let currencySymbol = Character(Locale.current.currencySymbol!)
        guard amountWithoutCurrency.contains(currencySymbol) else {
            return false //don't delete the currencySymbol
        }
        amountWithoutCurrency.removeAll { $0 == currencySymbol }

        let split = amountWithoutCurrency.components(separatedBy: numberFormatter.decimalSeparator)

        let decimalDigits = split.count == 2 ? split.last ?? "" : ""

        let stringToInt = split.first != nil ? Int(split.first!) ?? 0 : 0
        let isAmountPositive = stringToInt >= 0

        return isAmountPositive && decimalDigits.count <= 2
    }

}
