/*****************************************************************************
 * VLCActionSheet.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import UIKit

// MARK: VLCRendererCollectionViewLayout
class VLCRendererCollectionViewLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    fileprivate func setupLayout() {
        minimumLineSpacing = 1
        minimumInteritemSpacing = 0
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

// MARK: VLCActionSheetSectionHeader
class VLCActionSheetSectionHeader: UIView {

    static let identifier = "VLCActionSheetSectionHeader"

    let title: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16)
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()

    let separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = .lightGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupSeparator()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
        setupSeparator()
    }

    fileprivate func setupSeparator() {
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.topAnchor.constraint(equalTo: bottomAnchor, constant: -1)
            ])
    }

    fileprivate func setupView() {
        addSubview(title)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
            title.centerXAnchor.constraint(equalTo: centerXAnchor),
            title.topAnchor.constraint(equalTo: topAnchor)
            ])
    }
}

@objc protocol VLCActionSheetDataSource: class {
    @objc func numberOfRows() -> Int
    @objc func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
}

@objc protocol VLCActionSheetDelegate: class {
    @objc optional func headerViewTitle() -> String?
    @objc func itemAtIndexPath(_ indexPath: IndexPath) -> Any?
    @objc func actionSheet(collectionView: UICollectionView, didSelectItem item: Any, At indexPath: IndexPath)
}

// MARK: VLCActionSheet
class VLCActionSheet: UIViewController {

    private let cellHeight: CGFloat = 50

    @objc weak var dataSource: VLCActionSheetDataSource?
    @objc weak var delegate: VLCActionSheetDelegate?

    var action: ((_ item: Any) -> Void)?

    lazy var backgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.isHidden = true
        backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.removeActionSheet)))
        return backgroundView
    }()

    lazy var collectionViewLayout: VLCRendererCollectionViewLayout = {
        let collectionViewLayout = VLCRendererCollectionViewLayout()
        return collectionViewLayout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(VLCActionSheetCell.self, forCellWithReuseIdentifier: VLCActionSheetCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.setTitle(NSLocalizedString("CANCEL", comment: ""), for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelButton.addTarget(self, action: #selector(self.removeActionSheet), for: .touchDown)
        cancelButton.backgroundColor = UIColor(red:1.00, green:0.59, blue:0.13, alpha:1.0)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        return cancelButton
    }()

    lazy var headerView: VLCActionSheetSectionHeader = {
        let headerView = VLCActionSheetSectionHeader()
        headerView.title.text = delegate?.headerViewTitle?() ?? "Default header title"
        headerView.title.textColor = .black
        headerView.backgroundColor = .white
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()

    lazy var bottomBackgroundView: UIView = {
        let bottomBackgroundView = UIView()
        bottomBackgroundView.backgroundColor = UIColor(red:1.00, green:0.59, blue:0.13, alpha:1.0)
        bottomBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        return bottomBackgroundView
    }()

    lazy var mainStackView: UIStackView = {
        let mainStackView = UIStackView()
        mainStackView.spacing = 0
        mainStackView.axis = .vertical
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        return mainStackView
    }()

    fileprivate lazy var maxCollectionViewHeightConstraint: NSLayoutConstraint = {
        let maxCollectionViewHeightConstraint = collectionView.heightAnchor.constraint(
            lessThanOrEqualToConstant: (view.bounds.height / 2) - cellHeight)
        return maxCollectionViewHeightConstraint
    }()

    fileprivate lazy var collectionViewHeightConstraint: NSLayoutConstraint = {
        guard let dataSource = dataSource else {
            preconditionFailure("VLCActionSheet: Data source not set correctly!")
        }

        let collectionViewHeightConstraint = collectionView.heightAnchor.constraint(
            equalToConstant: CGFloat(dataSource.numberOfRows()) * cellHeight)
        collectionViewHeightConstraint.priority = .required - 1
        return collectionViewHeightConstraint
    }()

    fileprivate lazy var bottomBackgroundViewHeightConstraint: NSLayoutConstraint = {
        let bottomBackgroundViewHeightConstraint = bottomBackgroundView.heightAnchor.constraint(equalToConstant: cellHeight)
        return bottomBackgroundViewHeightConstraint
    }()

    // MARK: Private methods
    @objc fileprivate func removeActionSheet() {
        UIView.transition(with: backgroundView, duration: 0.01, options: .transitionCrossDissolve, animations: {
            [weak self] in
            self?.backgroundView.isHidden = true
            }, completion: { finished in
                super.presentingViewController?.dismiss(animated: true, completion: nil)
        })
    }

    fileprivate func setupCancelButtonConstraints() {
        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalTo: view.widthAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: cellHeight)
            ])
    }

    fileprivate func setuplHeaderViewConstraints() {
        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: cellHeight),
            headerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            ])
    }

    fileprivate func setupCollectionViewConstraints() {
        NSLayoutConstraint.activate([
            collectionViewHeightConstraint,
            maxCollectionViewHeightConstraint,
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor),
            ])
    }

    fileprivate func setupBottomBackgroundView() {
        NSLayoutConstraint.activate([
            bottomBackgroundViewHeightConstraint,
            bottomBackgroundView.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])
    }

    fileprivate func setupMainStackViewConstraints() {
        NSLayoutConstraint.activate([
            mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStackView.widthAnchor.constraint(equalTo: view.widthAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        if let presentingViewController = presentingViewController, let dataSource = dataSource {
            collectionViewHeightConstraint.constant = CGFloat(dataSource.numberOfRows()) * cellHeight
            maxCollectionViewHeightConstraint.constant = presentingViewController.view.frame.size.height / 2
            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
        }
    }

    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        bottomBackgroundViewHeightConstraint.constant = view.safeAreaInsets.bottom
    }

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(backgroundView)
        view.addSubview(mainStackView)

        // wip: Currently adapting to new UI
        //       option to hide cancelbutton
        mainStackView.addArrangedSubview(headerView)
        mainStackView.addArrangedSubview(collectionView)
//        mainStackView.addArrangedSubview(cancelButton)
        mainStackView.addArrangedSubview(bottomBackgroundView)

        backgroundView.frame = UIScreen.main.bounds

        setupMainStackViewConstraints()
        setupCollectionViewConstraints()
//        setupCancelButtonConstraints()
        setuplHeaderViewConstraints()
        setupBottomBackgroundView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStackView.isHidden = true
        updateViewConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // This is to avoid a horrible visual glitch!
        mainStackView.isHidden = false

        UIView.transition(with: backgroundView, duration: 0.2, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.backgroundView.isHidden = false
            }, completion: nil)

        let realMainStackView = mainStackView.frame

        mainStackView.frame.origin.y += mainStackView.frame.origin.y

        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            [mainStackView] in
            mainStackView.frame = realMainStackView
            }, completion: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.maxCollectionViewHeightConstraint.constant = size.height / 2
            self?.collectionView.layoutIfNeeded()
        })
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    @objc func setAction(closure action: @escaping (_ item: Any) -> Void) {
        self.action = action
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension VLCActionSheet: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: cellHeight)
    }
}

// MARK: UICollectionViewDelegate
extension VLCActionSheet: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = delegate, let item = delegate.itemAtIndexPath(indexPath) {
            delegate.actionSheet(collectionView: collectionView, didSelectItem: item, At: indexPath)
            action?(item)
        }
        removeActionSheet()
    }
}

// MARK: UICollectionViewDataSource
extension VLCActionSheet: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let dataSource = dataSource {
            return dataSource.numberOfRows()
        }
        preconditionFailure("VLCActionSheet: No data source")
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let dataSource = dataSource {
            return dataSource.actionSheet(collectionView: collectionView, cellForItemAt: indexPath)
        }
        preconditionFailure("VLCActionSheet: No data source")
    }
}
