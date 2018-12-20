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

import PassKit

class DonationAmountView: UIStackView {

    private let donationAmount = UITextField(frame: .zero)
    private let donationTitle = UILabel(frame: .zero)
    private let separator = UIView(frame: .zero)
    private let separator2 = UIView(frame: .zero)
    private var paymentButton: PKPaymentButton?
    private var buttons: [UIButton]?
    private let keyboard = UIButton(type: .custom)
    let closebutton = UIButton(type: .custom)
    private var donationManager: DonationManager?
    
    lazy var numberFormatter = { () -> NumberFormatter in
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()

    lazy var header: UIStackView = {

        closebutton.setImage( UIImage(named: "close"), for: .normal)

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


    func setupPayButton() {
        paymentButton?.removeFromSuperview()
        guard let newPaymentButton = donationManager?.donationButtonForDarkTheme(PresentationTheme.current == PresentationTheme.darkTheme) else {
            //Device doesn't support ApplePay
            return
        }
        addArrangedSubview(newPaymentButton)
        self.paymentButton = newPaymentButton
        NSLayoutConstraint.activate([newPaymentButton.heightAnchor.constraint(equalToConstant: 44)])
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

    init(donationManager: DonationManager) {
        self.donationManager = donationManager
        super.init(frame: .zero)
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
        updateTheme()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func updateTheme() {
        donationAmount.textColor = PresentationTheme.current.colors.cellTextColor
        donationTitle.textColor = PresentationTheme.current.colors.cellTextColor
        separator.backgroundColor = PresentationTheme.current.colors.mediaCategorySeparatorColor
        separator2.backgroundColor = PresentationTheme.current.colors.mediaCategorySeparatorColor
        buttons?.forEach() { $0.layer.borderColor = PresentationTheme.current.colors.mediaCategorySeparatorColor.cgColor }
        setupPayButton()
        updateKeyboardButton()
    }

    func setup() {
        addArrangedSubview(header)
        addArrangedSubview(separator)
        addArrangedSubview(donationAmountView)
        addArrangedSubview(separator2)
        addArrangedSubview(donationButtons)
        axis = .vertical
        translatesAutoresizingMaskIntoConstraints = false
        layoutIfNeeded()
        spacing = 10.0
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1.0),
            separator2.heightAnchor.constraint(equalToConstant: 1.0)
        ])

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

    @objc func setDonationAmount(sender: UIButton) {
        donationAmount.text = sender.titleLabel?.text
    }

    func currentAmount() -> Float {
        guard let amount = donationAmount.text else {
            return 0
        }
        var amountWithoutCurrency = amount
        let currencySymbol = Character(Locale.current.currencySymbol!)
        amountWithoutCurrency.removeAll { $0 == currencySymbol }
        return Float(amountWithoutCurrency)!
    }
}

extension DonationAmountView: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let currentText = textField.text ?? ""
        let replacementText = (currentText as NSString).replacingCharacters(in: range, with: string)

        return isValidAmount(amount: replacementText)
    }

    // make sure that the new string doesn't remove the currency symbol and is valid pay amount being not negative & max 2 digits
    private func isValidAmount(amount: String) -> Bool {

        guard self.numberFormatter.number(from: amount) != nil else {
            return false //don't enter letters
        }
        let currencySymbol = Character(Locale.current.currencySymbol!)
        guard amount.contains(currencySymbol) else {
            return false //don't delete the currencySymbol
        }

        var amountWithoutCurrency = amount
        amountWithoutCurrency.removeAll { $0 == currencySymbol }

        let split = amountWithoutCurrency.components(separatedBy: numberFormatter.decimalSeparator)

        let decimalDigits = split.count == 2 ? split.last ?? "" : ""

        let stringToInt = split.first != nil ? Int(split.first!) ?? 0 : 0
        let isAmountPositive = stringToInt >= 0

        return isAmountPositive && decimalDigits.count <= 2
    }

}
