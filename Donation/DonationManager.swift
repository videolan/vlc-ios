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
protocol DonationManagerDelegate: PKPaymentAuthorizationViewControllerDelegate {
    //Since we're not doing calculations CGFloat should be fine otherwise switch to NSDecimalNumber
    func donationManagerAmountForDonation(donationManager: DonationManager) -> Float
    func donationManagerShouldPresentViewController(donationManager: DonationManager, viewController: UIViewController)
    func donationManagerFinished(donationManager: DonationManager)
}

class DonationManager: NSObject {

    let passLibrary = PKPassLibrary()
    weak var delegate: DonationManagerDelegate?

    @objc func donateAmount() {
        guard let amount = delegate?.donationManagerAmountForDonation(donationManager: self) else {
            assertionFailure("no amount was defined")
            return
        }

        let request = PKPaymentRequest()
        guard let currencyCode = Locale.current.currencyCode, let countrycode = Locale.current.regionCode else {
            return assertionFailure("missng currencycode or reegioncode")
        }
        request.currencyCode = currencyCode
        request.countryCode = countrycode
        request.merchantIdentifier = "merchant.com.example.vlc-ios"
        request.merchantCapabilities = .capability3DS
        request.requiredBillingAddressFields = .email

        let decimalamount = NSDecimalNumber(mantissa: UInt64(amount*100), exponent: -2, isNegative: false)
        let item = PKPaymentSummaryItem(label: NSLocalizedString("DONATE", comment: ""), amount: decimalamount)
        request.paymentSummaryItems = [item]

    }

    func authorizepayment(request: PKPaymentRequest) {
        let authorizationVC = PKPaymentAuthorizationViewController(paymentRequest: request)
        authorizationVC?.delegate = delegate
    }

    func needsToSetupCard() -> Bool {
        var networks: [PKPaymentNetwork] = [.masterCard, .visa]

        if #available(iOS 10.3, *) {
            networks.append(.carteBancaire)
        }
        if #available(iOS 11.0, *) {
            networks.append(.carteBancaires)
        }
        if #available(iOS 11.2, *) {
            networks.append(.cartesBancaires)
        }
        if #available(iOS 12.0, *) {
            networks.append(.maestro)
        }

        return PKPaymentAuthorizationViewController.canMakePayments(usingNetworks:networks)
    }

    @objc func setupApplePay() {
        delegate?.donationManagerFinished(donationManager: self)
        return
        passLibrary.openPaymentSetup()
    }

    func donationButtonForDarkTheme(_ isDarkTheme: Bool) -> PKPaymentButton? {
        if !PKPaymentAuthorizationViewController.canMakePayments() {
            return nil
        }
        let style: PKPaymentButtonStyle = isDarkTheme ? .white : .black
        let button: PKPaymentButton
        if needsToSetupCard() {
            button = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: style)
            button.addTarget(self, action: #selector(setupApplePay), for: .touchUpInside)
            return button
        }

        if #available(iOS 10.2, *) {
            button = PKPaymentButton(paymentButtonType: .donate, paymentButtonStyle: style)
        } else {
            button = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: style)
        }
        button.addTarget(self, action: #selector(donateAmount), for: .touchUpInside)
        return button
    }
}
