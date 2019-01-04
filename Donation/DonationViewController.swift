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
    lazy var donationAmountView: DonationAmountView = {
        let view = DonationAmountView(donationManager: donationManager)
        view.closebutton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        return view
    }()
    private let donationFinished = DonationFinishedView()
    private let confettiView = DonationVLCConfettiView()
    private let backgroundView = UIView(frame: .zero)
    private var donationManager = DonationManager()
    private var keyboardFrame = CGRect.zero

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(updateTheme), name: .VLCThemeDidChangeNotification, object: nil)
        donationManager.delegate = self
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
        setupDarkOverlayView()
        setupBackgroundView()
        displayView(donationAmountView)
    }

    private func displayView(_ view: UIView) {
        backgroundView.addSubview(view)

        bottomConstraint = backgroundView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: view.frame.size.height)
        minBottomConstraint = view.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        updateViewForPosition(to: .hidden)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 10),
            view.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -20),
            minBottomConstraint!,
            bottomConstraint!
            ])
    }

    private func setupBackgroundView() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
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

    @objc func updateTheme() {
        backgroundView.backgroundColor = PresentationTheme.current.colors.background
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
            bottomConstraint?.constant = donationAmountView.frame.size.height
        case .keyboardVisible:
            bottomConstraint?.constant = -keyboardFrame.size.height
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
        donationAmountView.updateKeyboardButton()
    }

    @objc func keyboardWillBeShown(notification: Notification) {
        let userInfo = notification.userInfo
        keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        updateViewForPosition(to: .keyboardVisible)
    }

    @objc func keyboardWillBeHidden(notification: Notification) {
        updateViewForPosition(to: .bottom)
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

    private func makeItRain() {
        confettiView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(confettiView, belowSubview: backgroundView)
        NSLayoutConstraint.activate([
            confettiView.topAnchor.constraint(equalTo: view.topAnchor),
            confettiView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            confettiView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            confettiView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        confettiView.layoutIfNeeded()
        confettiView.startConfetti()
    }
}

extension DonationViewController: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    @available(iOS 9.0, *) // this method is needed for < iOS11 please bump when dropping iOS9 and remove after dropping iOS10
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        controller.dismiss(animated: true, completion: nil)
        showDonationFinished()
    }

    @available(iOS 11.0, *)
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        controller.dismiss(animated: true, completion: nil)
        showDonationFinished()
    }

    private func showDonationFinished() {
        updateViewForPosition(to: .hidden)
        donationAmountView.removeFromSuperview()
        NSLayoutConstraint.deactivate([
            bottomConstraint!,
            minBottomConstraint!
            ])
        makeItRain()
        displayView(donationFinished)
        updateViewForPosition(to: .bottom)
    }
}

extension DonationViewController: DonationManagerDelegate {

    func donationManagerAmountForDonation(donationManager: DonationManager) -> NSNumber {
        return donationAmountView.currentAmount()
    }

    func donationManagerShouldPresentViewController(donationManager: DonationManager, viewController: UIViewController) {
        present(viewController, animated: true, completion: nil)
    }
}

