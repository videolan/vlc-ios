/*****************************************************************************
 * ActionSheet.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import UIKit

@objc(VLCActionSheetDataSource)
protocol ActionSheetDataSource {
    @objc func numberOfRows() -> Int
    @objc func actionSheet(collectionView: UICollectionView,
                           cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
}

@objc(VLCActionSheetDelegate)
protocol ActionSheetDelegate {
    @objc optional func headerViewTitle() -> String?
    @objc func itemAtIndexPath(_ indexPath: IndexPath) -> Any?
    @objc optional func actionSheet(collectionView: UICollectionView,
                                    didSelectItem item: Any, At indexPath: IndexPath)
    @objc optional func actionSheetDidFinishClosingAnimation(_ actionSheet: ActionSheet)
}

// MARK: ActionSheet

@objc(VLCActionSheet)
class ActionSheet: UIViewController {

    private let cellHeight: CGFloat = 50

    @objc weak var dataSource: ActionSheetDataSource?
    @objc weak var delegate: ActionSheetDelegate?

    var action: ((_ item: Any) -> Void)?

    lazy var backgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.alpha = 0
        backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                   action: #selector(self.removeActionSheet)))
        return backgroundView
    }()

    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumLineSpacing = 1
        collectionViewLayout.minimumInteritemSpacing = 0
        return collectionViewLayout
    }()

    @objc lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: UIScreen.main.bounds,
                                              collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = PresentationTheme.current.colors.background
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.register(ActionSheetCell.self,
                                forCellWithReuseIdentifier: ActionSheetCell.identifier)
        collectionView.register(DoubleActionSheetCell.self,
                                forCellWithReuseIdentifier: DoubleActionSheetCell.reusableIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    lazy var collectionWrapperView: UIView = {
        let collectionWrapperView: UIView = UIView(frame: UIScreen.main.bounds)
        collectionWrapperView.backgroundColor = PresentationTheme.current.colors.background
        return collectionWrapperView
    }()

    private(set) lazy var headerView: ActionSheetSectionHeader = {
        let headerView = ActionSheetSectionHeader()
        headerView.title.text = delegate?.headerViewTitle?() ?? "Default header title"
        headerView.title.textColor = PresentationTheme.current.colors.cellTextColor
        headerView.backgroundColor = PresentationTheme.current.colors.background
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()

    private lazy var downGesture: UIPanGestureRecognizer = {
        let downGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDismiss(sender:)))
        return downGesture
    }()

    private lazy var mainStackView: UIStackView = {
        let mainStackView = UIStackView()
        mainStackView.spacing = 0
        mainStackView.axis = .vertical
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.backgroundColor = .clear
        mainStackView.addGestureRecognizer(downGesture)
        return mainStackView
    }()

    private lazy var maxCollectionViewHeightConstraint: NSLayoutConstraint = {
        let maxCollectionViewHeightConstraint = collectionView.heightAnchor.constraint(
            lessThanOrEqualToConstant: maxCollectionViewHeight)
        maxCollectionViewHeightConstraint.priority = .defaultHigh
        return maxCollectionViewHeightConstraint
    }()

    private lazy var collectionViewHeightConstraint: NSLayoutConstraint = {
        let collectionViewHeightConstraint = collectionView.heightAnchor.constraint(
            equalToConstant: collectionViewHeight)
        collectionViewHeightConstraint.priority = .defaultLow
        return collectionViewHeightConstraint
    }()

    let collectionViewEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)

    var collectionViewHeight: CGFloat {
        let rowsCount: CGFloat = CGFloat(dataSource?.numberOfRows() ?? 0)
        let collectionViewHeight = rowsCount * (cellHeight + collectionViewEdgeInsets.top)
        return collectionViewHeight
    }

    var maxCollectionViewHeight: CGFloat {
        let maxMargin: CGFloat = 75
        let minCollectionViewHeight: CGFloat = cellHeight * 1.5 + collectionViewEdgeInsets.top * 2
        let maxCollectionViewHeight = max(view.bounds.height - headerView.bounds.height - maxMargin, minCollectionViewHeight)
        return maxCollectionViewHeight
    }

    var offScreenFrame: CGRect {
        let y = headerView.cellHeight
        let w = collectionView.frame.size.width
        let h = collectionView.frame.size.height
        return CGRect(x: w, y: y, width: w, height: h)
    }

    private var mainStackViewTranslation = CGPoint(x: 0, y: 0)

    override func updateViewConstraints() {
        super.updateViewConstraints()
        updateCollectionViewContraints()
    }

    private func updateCollectionViewContraints() {
        collectionViewHeightConstraint.constant = collectionViewHeight
        maxCollectionViewHeightConstraint.constant = maxCollectionViewHeight
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
    }

    private func updateCollectionViewScrollIndicatorVisibility() {
        if maxCollectionViewHeight > collectionViewHeight {
            collectionView.showsVerticalScrollIndicator = false
        } else {
            collectionView.showsVerticalScrollIndicator = true
            collectionView.flashScrollIndicatorsIfNeeded()
        }
    }

    // MARK: UIViewController

    init () {
        super.init(nibName: nil, bundle: nil)
    }

    init(header: ActionSheetSectionHeader) {
        super.init(nibName: nil, bundle: nil)
        headerView = header
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme),
                                               name: .VLCThemeDidChangeNotification, object: nil)

        view.addSubview(backgroundView)
        view.addSubview(mainStackView)

        mainStackView.addArrangedSubview(headerView)
        mainStackView.addArrangedSubview(collectionWrapperView)

        backgroundView.frame = UIScreen.main.bounds

        backgroundView.accessibilityLabel = NSLocalizedString("ACTIONSHEET_BACKGROUND_LABEL",
                                                              comment: "")
        backgroundView.accessibilityHint = NSLocalizedString("ACTIONSHEET_BACKGROUND_HINT",
                                                             comment: "")

        backgroundView.accessibilityTraits = .allowsDirectInteraction

        setupMainStackViewConstraints()
        setupHeaderViewConstraints()
        setupCollectionWrapperView()
        setupCollectionViewConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStackView.isHidden = true
        collectionView.reloadData()
        headerView.title.text = delegate?.headerViewTitle?()
        updateViewConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setHeaderRoundedCorners()

        // This is to avoid a horrible visual glitch!
        mainStackView.isHidden = false

        updateCollectionViewContraints()
        updateCollectionViewScrollIndicatorVisibility()

        let realMainStackView = mainStackView.frame

        mainStackView.frame.origin.y += mainStackView.frame.origin.y

        UIView.animate(withDuration: 0.65, delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: .curveEaseOut,
                       animations: {
                        [mainStackView, backgroundView] in
                        mainStackView.frame = realMainStackView
                        mainStackView.transform = .identity
                        backgroundView.alpha = 1
        })
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updateCollectionViewContraints()
            self?.setHeaderRoundedCorners()
        }) { [weak self] _ in
            self?.updateCollectionViewScrollIndicatorVisibility()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    @objc private func updateTheme() {
        collectionView.backgroundColor = PresentationTheme.current.colors.background
        collectionWrapperView.backgroundColor = PresentationTheme.current.colors.background
        headerView.backgroundColor = PresentationTheme.current.colors.background
        headerView.title.textColor = PresentationTheme.current.colors.cellTextColor
        headerView.title.backgroundColor = PresentationTheme.current.colors.background
        collectionView.layoutIfNeeded()
    }
    
    func addChildToStackView(_ child: UIView) {
        mainStackView.addSubview(child)
    }

    func updateDragDownGestureDelegate(to delegate: ActionSheet?) {
        downGesture.delegate = delegate
    }

    func shouldDisableDragDownGesture(_ disable: Bool) {
        downGesture.isEnabled = !disable
    }
}

// MARK: Private setup methods

private extension ActionSheet {
    private func setupCollectionWrapperView() {
        collectionWrapperView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionWrapperView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor),
        ])
    }

    private func setupHeaderViewConstraints() {
        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: headerView.cellHeight),
            headerView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor)
        ])
    }

    private func setupCollectionViewConstraints() {
        let bottomConstraint: NSLayoutConstraint
        if #available(iOS 11, *) {
            bottomConstraint = collectionView.bottomAnchor.constraint(equalTo: collectionWrapperView.safeAreaLayoutGuide.bottomAnchor)
        } else {
            bottomConstraint = collectionView.bottomAnchor.constraint(equalTo: collectionWrapperView.bottomAnchor)
        }

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: collectionWrapperView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: collectionWrapperView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: collectionWrapperView.trailingAnchor),
            bottomConstraint,
            collectionViewHeightConstraint,
            maxCollectionViewHeightConstraint,
            collectionView.widthAnchor.constraint(equalTo: collectionWrapperView.widthAnchor),
        ])
    }

    private func setupMainStackViewConstraints() {
        let leadingAnchor: NSLayoutXAxisAnchor
        let trailingAnchor: NSLayoutXAxisAnchor
        let widthAnchor: NSLayoutDimension

        if #available(iOS 11.0, *) {
            let safeArea: UILayoutGuide = view.safeAreaLayoutGuide
            leadingAnchor = safeArea.leadingAnchor
            trailingAnchor = safeArea.trailingAnchor
            widthAnchor = safeArea.widthAnchor
        } else {
            leadingAnchor = view.leadingAnchor
            trailingAnchor = view.trailingAnchor
            widthAnchor = view.widthAnchor
        }

        NSLayoutConstraint.activate([
            // Extra padding for spring animation
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.widthAnchor.constraint(equalTo: widthAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: Helpers

private extension ActionSheet {
    private func setHeaderRoundedCorners() {
        let roundedCornerPath = UIBezierPath(roundedRect: headerView.bounds,
                                             byRoundingCorners: [.topLeft, .topRight],
                                             cornerRadii: CGSize(width: 10, height: 10))
        let maskLayer = CAShapeLayer()
        maskLayer.path = roundedCornerPath.cgPath
        headerView.layer.mask = maskLayer
    }
}

// MARK: Actions

extension ActionSheet {
    @objc func setAction(closure action: @escaping (_ item: Any) -> Void) {
        self.action = action
    }


    @objc func removeActionSheet() {
        let realMainStackView = mainStackView.frame

        UIView.animate(withDuration: 0.55, delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 0,
                       options: .curveEaseIn,
                       animations: {
                        [mainStackView, backgroundView] in
                        // Dismiss the mainStackView to the bottom of the screen
                        mainStackView.frame.origin.y += mainStackView.frame.size.height
                        backgroundView.alpha = 0
            }, completion: {
                [mainStackView, presentingViewController, headerView] finished in
                // When everything is complete, reset the frame for the re-use
                mainStackView.isHidden = true
                mainStackView.frame = realMainStackView
                presentingViewController?.dismiss(animated: false)
                headerView.accessoryViewsDelegate = nil
                headerView.updateAccessoryViews()
                headerView.previousButton.isHidden = true
                self.delegate?.actionSheetDidFinishClosingAnimation?(self)
        })
    }

    @objc func handleDismiss(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .changed:
            mainStackViewTranslation = sender.translation(in: mainStackView)
            if mainStackViewTranslation.y < 0 {
                return
            }
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.mainStackView.transform = CGAffineTransform(translationX: 0, y: self.mainStackViewTranslation.y)
            })
        case .ended:
            let halfHeight = mainStackView.frame.height / 2
            if mainStackViewTranslation.y < halfHeight {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.mainStackView.transform = .identity
                })
            } else {
                removeActionSheet()
            }
        default:
            break
        }
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension ActionSheet: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return collectionViewEdgeInsets
    }
}

// MARK: UICollectionViewDelegate

extension ActionSheet: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        if let delegate = delegate, let item = delegate.itemAtIndexPath(indexPath) {
            delegate.actionSheet?(collectionView: collectionView, didSelectItem: item, At: indexPath)
            action?(item)
        }
        removeActionSheet()
    }
}

// MARK: UICollectionViewDataSource

extension ActionSheet: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if let dataSource = dataSource {
            return dataSource.numberOfRows()
        }
        preconditionFailure("VLCActionSheet: No data source")
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let dataSource = dataSource {
            return dataSource.actionSheet(collectionView: collectionView,
                                          cellForItemAt: indexPath)
        }
        preconditionFailure("VLCActionSheet: No data source")
    }
}

extension ActionSheet: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
