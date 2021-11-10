/*****************************************************************************
 * StoreViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2021 VideoLAN. All rights reserved.
 *
 * Authors:  Soomin Lee < bubu@mikan.io >
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import StoreKit

class StoreViewController: UIViewController {
    @IBOutlet weak private var confettiView: VLCConfettiView!
    @IBOutlet weak private var tippingExplainedLabel: UILabel!
    @IBOutlet weak private var cannotMakePaymentsLabel: UILabel!
    @IBOutlet weak private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak private var performPurchaseButton: UIButton!
    @IBOutlet weak var priceCollectionView: UICollectionView!

    @IBOutlet weak var priceCollectionViewHeightConstraint: NSLayoutConstraint!
    private var storeController: VLCStoreController
    private var availableProducts: [SKProduct] = []
    // Use iOS 9 friendly emojis
    private var productEmojis: [String] = ["👍", "👏", "🙌", "❤️", "😍"]

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        storeController = VLCStoreController()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStoreCoordination()
        setupDoneNavigationButton()
        setupViews()
        activityIndicator.startAnimating()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11, *) {}
        else {
            // For iOS 10 and below, remove edge value to avoid the system
            // displaying the content underneath the navigation bar.
            self.edgesForExtendedLayout = []
        }
        themeDidChange()
        storeController.validateAvailableProducts()
    }

    @IBAction func performPurchase(_ sender: Any) {
        guard let selectedProductIndex = priceCollectionView.indexPathsForSelectedItems?.first?.row else {
            return
        }
        if let selectedProduct = availableProducts.objectAtIndex(index: selectedProductIndex) {
            storeController.purchaseProduct(selectedProduct)
        }
    }

    func hidePurchaseInterface() {
        performPurchaseButton.isHidden = true
        priceCollectionView.isHidden = true
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _  in
            self?.updateCollectionViewSize()
            self?.priceCollectionView.layoutIfNeeded()
            self?.priceCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

// MARK: - Private setups

private extension StoreViewController {
    private func setupViews() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        title = NSLocalizedString("MAKE_DONATION_TITLE",
                                  comment: "")
        tippingExplainedLabel.text = NSLocalizedString("DONATION_DESCRIPTION",
                                                       comment: "")
        cannotMakePaymentsLabel.text = NSLocalizedString("CANNOT_MAKE_PAYMENTS",
                                                         comment: "")
        performPurchaseButton.setTitle(NSLocalizedString("SEND_DONATION",
                                                         comment: ""), for: .normal)
        performPurchaseButton.isEnabled = false

        let cellNib = UINib(nibName: "StoreProductCollectionViewCell", bundle: nil)

        priceCollectionView.register(cellNib,
                                     forCellWithReuseIdentifier: StoreProductCollectionViewCell.identifier)
        priceCollectionView.delegate = self
        priceCollectionView.dataSource = self
        themeDidChange()
    }

    private func setupDoneNavigationButton() {
        let doneButton = UIBarButtonItem(title: NSLocalizedString("BUTTON_DONE",
                                                                  comment: ""),
                                         style: .done,
                                         target: self,
                                         action: #selector(dismissViewController))
        doneButton.accessibilityIdentifier = VLCAccessibilityIdentifier.done
        navigationItem.rightBarButtonItem = doneButton

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification,
                                               object: nil)
    }

    private func setupStoreCoordination() {
        activityIndicator.startAnimating()

        guard storeController.canMakePayments else {
            activityIndicator.stopAnimating()
            cannotMakePaymentsLabel.isHidden = false
            hidePurchaseInterface()
            return
        }

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self,
                                       selector: #selector(availableProductsUpdated(_:)),
                                       name: NSNotification.Name(rawValue: VLCStoreControllerAvailableProductsUpdated),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(purchasedProductsRestored(_:)),
                                       name: NSNotification.Name(rawValue: VLCStoreControllerPurchasedProductsRestored),
                                       object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(purchaseFailed(_:)),
                                       name: NSNotification.Name(rawValue: VLCStoreControllerInteractionFailed),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(purchaseSucceeded(_:)),
                                       name: NSNotification.Name(rawValue: VLCStoreControllerTipReceived),
                                       object: nil)

        storeController.validateAvailableProducts()
    }
}

// MARK: - Store Selector

extension StoreViewController {
    func updateCollectionViewSize() {
        let flowLayout = priceCollectionView.collectionViewLayout as? UICollectionViewFlowLayout

        flowLayout?.itemSize = CGSize(width: priceCollectionView.frame.size.width - CGFloat(2 * availableProducts.count), height: 84.0)
        flowLayout?.minimumLineSpacing = 0.0
        flowLayout?.minimumInteritemSpacing = 0.2
    }

    func updatePriceViews(with products: [SKProduct]) {

        priceCollectionView.isHidden = false
        priceCollectionView.reloadData()
        updateCollectionViewSize()
        availableProducts = products
        cannotMakePaymentsLabel.isHidden = true
        activityIndicator.stopAnimating()
    }

    @objc func availableProductsUpdated(_ notification: Notification) {
        DispatchQueue.main.async {
            [weak self] in
            guard let products = self?.storeController.availableProducts as? [SKProduct] else {
                assertionFailure("StoreViewController: Products not [SKProduct] type.")
                return
            }

            self?.updatePriceViews(with: products)

            if products.isEmpty {
                // alert failed to retreive products
                return
            }
        }
    }

    @objc func purchasedProductsRestored(_ notification: Notification) {
    }

    @objc func purchaseFailed(_ notification: Notification) {
        guard let error = notification.userInfo?[VLCStoreControllerInteractionFailed] as? NSError else {
            return
        }

        // User cancelled purchase
        if error.code == 2 {
            return
        }

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("PURCHASE_FAILED", comment: ""),
                                                errorMessage: error.localizedDescription,
                                                viewController: self)

    }

    @objc func purchaseSucceeded(_ notification: Notification) {
        hidePurchaseInterface()
        confettiView.startConfetti()

        let alert = UIAlertController(title: NSLocalizedString("PURCHASE_SUCESS_TITLE",
                                                               comment: ""),
                                      message: NSLocalizedString("PURCHASE_SUCESS_DESCRIPTION",
                                                                 comment: ""),
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment:""),
                                   style: .default,
                                   handler: {
            [weak self] _ in
            self?.dismissViewController()
        })
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    @objc func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    @objc func themeDidChange() {
        let currentColors = PresentationTheme.current.colors

        navigationItem.titleView?.tintColor = currentColors.navigationbarTextColor
        view.backgroundColor = currentColors.background
        confettiView.backgroundColor = currentColors.background
        priceCollectionView.backgroundColor = currentColors.background
        tippingExplainedLabel.textColor = currentColors.cellTextColor
        cannotMakePaymentsLabel.textColor =
        currentColors.cellTextColor
        performPurchaseButton.setTitleColor(currentColors.orangeUI,
                                            for: .normal)
        performPurchaseButton.setTitleColor(.darkGray,
                                            for: .disabled)
    }
}
//
extension StoreViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        performPurchaseButton.isEnabled = true
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard !availableProducts.isEmpty else {
            return .zero
        }

        let numberOfSets = CGFloat(availableProducts.count)
        return CGSize(width: view.frame.size.width / numberOfSets,
                      height: collectionView.frame.size.height)
    }
}

extension StoreViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return availableProducts.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StoreProductCollectionViewCell.identifier,
                                                            for: indexPath) as? StoreProductCollectionViewCell else {
            assertionFailure("StoreViewController: Wrong cell type.")
            return UICollectionViewCell()
        }

        guard let product = availableProducts.objectAtIndex(index: indexPath.row) else {
            return cell
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale

        if indexPath.row < productEmojis.count {
            cell.emojiLabel.text = productEmojis[indexPath.row]
        }
        cell.priceLabel.text = formatter.string(from: product.price)
        cell.accessibilityLabel = product.localizedTitle
        cell.accessibilityHint = product.localizedDescription
        return cell
    }
}
