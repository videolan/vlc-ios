/*****************************************************************************
 * BaseButtonBarPageTabStripViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class VLCLabelCell: UICollectionViewCell {
    static let cellIdentifier = "VLCLabelCell"
    @IBOutlet weak var iconLabel: UILabel!

}
enum SwipeDirection {
    case left
    case right
    case none
}

struct IndicatorInfo {

    var title: String?
    var accessibilityLabel: String?
    var accessibilityIdentifier: String?

    init(title: String, accessibilityIdentifier: String? = nil) {
        self.title = title
        self.accessibilityLabel = title
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

enum PagerScroll {
    case no
    case yes
    case onlyIfOutOfScreen
}

class VLCPagingViewController<ButtonBarCellType: UICollectionViewCell>: PagerTabStripViewController, PagerTabStripDataSource, PagerTabStripIsProgressiveDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    var changeCurrentIndexProgressive: ((_ oldCell: ButtonBarCellType?, _ newCell: ButtonBarCellType?, _ progressPercentage: CGFloat, _ changeCurrentIndex: Bool, _ animated: Bool) -> Void)?

    var buttonBarView: ButtonBarView!
    var buttonbarViewHeight: CGFloat = 45.0
    lazy private var cachedCellWidths: [CGFloat]? = { [unowned self] in
        return self.calculateWidths()
        }()
    private var shouldUpdateButtonBarView = true

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        delegate = self
        datasource = self
    }

    @available(*, unavailable, message: "use init(nibName:)")
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonbarViewHeight = viewControllers.count == 1 ? 0 : 45
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        buttonBarView = ButtonBarView(frame: .zero, collectionViewLayout: flowLayout)

        buttonBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonBarView)
        NSLayoutConstraint.activate([
            buttonBarView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            buttonBarView.rightAnchor.constraint(equalTo: view.rightAnchor),
            buttonBarView.leftAnchor.constraint(equalTo: view.leftAnchor),
            buttonBarView.heightAnchor.constraint(equalToConstant: buttonbarViewHeight)
            ])
        //make sure that top and bottom are not covered by tabbar and navigationbar
        let bottomGuide: NSLayoutConstraint
        if #available(iOS 11.0, *) {
            bottomGuide = containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        } else {
            bottomGuide = containerView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor)
        }
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: buttonBarView.bottomAnchor),
            containerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            containerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            bottomGuide
            ]
        )

        buttonBarView.delegate = self
        buttonBarView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buttonBarView.layoutIfNeeded()
        isViewAppearing = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewAppearing = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard isViewAppearing || isViewRotating else { return }

        // Force the UICollectionViewFlowLayout to get laid out again with the new size if
        // a) The view is appearing.  This ensures that
        //    collectionView:layout:sizeForItemAtIndexPath: is called for a second time
        //    when the view is shown and when the view *frame(s)* are actually set
        //    (we need the view frame's to have been set to work out the size's and on the
        //    first call to collectionView:layout:sizeForItemAtIndexPath: the view frame(s)
        //    aren't set correctly)
        // b) The view is rotating.  This ensures that
        //    collectionView:layout:sizeForItemAtIndexPath: is called again and can use the views
        //    *new* frame so that the buttonBarView cell's actually get resized correctly
        cachedCellWidths = calculateWidths()
        buttonBarView.collectionViewLayout.invalidateLayout()
        // When the view first appears or is rotated we also need to ensure that the barButtonView's
        // selectedBar is resized and its contentOffset/scroll is set correctly (the selected
        // tab/cell may end up either skewed or off screen after a rotation otherwise)
        buttonBarView.moveTo(index: currentIndex, animated: false, swipeDirection: .none, pagerScroll: .onlyIfOutOfScreen)
        buttonBarView.selectItem(at: IndexPath(item: currentIndex, section: 0), animated: false, scrollPosition: [])
    }

    // MARK: - Methods

    override func reloadPagerTabStripView() {
        super.reloadPagerTabStripView()
        guard isViewLoaded else { return }
        buttonBarView.reloadData()
        cachedCellWidths = calculateWidths()
        buttonBarView.moveTo(index: currentIndex, animated: false, swipeDirection: .none, pagerScroll: .yes)
    }

    func calculateStretchedCellWidths(_ minimumCellWidths: [CGFloat], suggestedStretchedCellWidth: CGFloat, previousNumberOfLargeCells: Int) -> CGFloat {
        var numberOfLargeCells = 0
        var totalWidthOfLargeCells: CGFloat = 0

        for minimumCellWidthValue in minimumCellWidths where minimumCellWidthValue > suggestedStretchedCellWidth {
            totalWidthOfLargeCells += minimumCellWidthValue
            numberOfLargeCells += 1
        }

        guard numberOfLargeCells > previousNumberOfLargeCells else { return suggestedStretchedCellWidth }

        let flowLayout = buttonBarView.collectionViewLayout as! UICollectionViewFlowLayout // swiftlint:disable:this force_cast
        let collectionViewAvailiableWidth = buttonBarView.frame.size.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right
        let numberOfCells = minimumCellWidths.count
        let cellSpacingTotal = CGFloat(numberOfCells - 1) * flowLayout.minimumLineSpacing

        let numberOfSmallCells = numberOfCells - numberOfLargeCells
        let newSuggestedStretchedCellWidth = (collectionViewAvailiableWidth - totalWidthOfLargeCells - cellSpacingTotal) / CGFloat(numberOfSmallCells)

        return calculateStretchedCellWidths(minimumCellWidths, suggestedStretchedCellWidth: newSuggestedStretchedCellWidth, previousNumberOfLargeCells: numberOfLargeCells)
    }

    func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int) {
        guard shouldUpdateButtonBarView else { return }
        buttonBarView.moveTo(index: toIndex, animated: true, swipeDirection: toIndex < fromIndex ? .right : .left, pagerScroll: .yes)
    }

    func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        guard shouldUpdateButtonBarView else { return }
        buttonBarView.move(fromIndex: fromIndex, toIndex: toIndex, progressPercentage: progressPercentage, pagerScroll: .yes)
        if let changeCurrentIndexProgressive = changeCurrentIndexProgressive {
            let oldCell = buttonBarView.cellForItem(at: IndexPath(item: currentIndex != fromIndex ? fromIndex : toIndex, section: 0)) as? ButtonBarCellType
            let newCell = buttonBarView.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? ButtonBarCellType
            changeCurrentIndexProgressive(oldCell, newCell, progressPercentage, indexWasChanged, true)
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayut

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        guard let cellWidthValue = cachedCellWidths?[indexPath.row] else {
            fatalError("cachedCellWidths for \(indexPath.row) must not be nil")
        }
        return CGSize(width: cellWidthValue, height: collectionView.frame.size.height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item != currentIndex && containerView.isScrollEnabled else { return }

        buttonBarView.moveTo(index: indexPath.item, animated: true, swipeDirection: .none, pagerScroll: .yes)
        shouldUpdateButtonBarView = false

        let oldCell = buttonBarView.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? ButtonBarCellType
        let newCell = buttonBarView.cellForItem(at: IndexPath(item: indexPath.item, section: 0)) as? ButtonBarCellType

        if let changeCurrentIndexProgressive = changeCurrentIndexProgressive {
            changeCurrentIndexProgressive(oldCell, newCell, 1, true, true)
        }
        moveToViewController(at: indexPath.item)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewControllers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCLabelCell.cellIdentifier, for: indexPath) as? ButtonBarCellType else {
            fatalError("UICollectionViewCell should be or extend from ButtonBarViewCell")
        }
        let childController = viewControllers[indexPath.item] as! IndicatorInfoProvider // swiftlint:disable:this force_cast
        let indicatorInfo = childController.indicatorInfo(for: self)

        configure(cell: cell, for: indicatorInfo)

        if let changeCurrentIndexProgressive = changeCurrentIndexProgressive {
            changeCurrentIndexProgressive(currentIndex == indexPath.item ? nil : cell, currentIndex == indexPath.item ? cell : nil, 1, true, false)
        }

        return cell
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        super.scrollViewDidEndScrollingAnimation(scrollView)

        guard scrollView == containerView else { return }
        shouldUpdateButtonBarView = true
    }

    func configure(cell: ButtonBarCellType, for indicatorInfo: IndicatorInfo) {
        fatalError("You must override this method to set up ButtonBarView cell accordingly")
    }

    private func calculateWidths() -> [CGFloat] {
        let flowLayout = buttonBarView.collectionViewLayout as! UICollectionViewFlowLayout // swiftlint:disable:this force_cast
        let numberOfCells = viewControllers.count

        var minimumCellWidths = [CGFloat]()
        var collectionViewContentWidth: CGFloat = 0
        let indicatorWidth: CGFloat = 70.0

        viewControllers.forEach { _ in
            minimumCellWidths.append(indicatorWidth)
            collectionViewContentWidth += indicatorWidth
        }

        let cellSpacingTotal = CGFloat(numberOfCells - 1) * flowLayout.minimumLineSpacing
        collectionViewContentWidth += cellSpacingTotal

        let collectionViewAvailableVisibleWidth = buttonBarView.frame.size.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right

        if collectionViewAvailableVisibleWidth < collectionViewContentWidth {
            return minimumCellWidths
        } else {
            let stretchedCellWidthIfAllEqual = (collectionViewAvailableVisibleWidth - cellSpacingTotal) / CGFloat(numberOfCells)
            let generalMinimumCellWidth = calculateStretchedCellWidths(minimumCellWidths, suggestedStretchedCellWidth: stretchedCellWidthIfAllEqual, previousNumberOfLargeCells: 0)
            var stretchedCellWidths = [CGFloat]()

            for minimumCellWidthValue in minimumCellWidths {
                let cellWidth = (minimumCellWidthValue > generalMinimumCellWidth) ? minimumCellWidthValue : generalMinimumCellWidth
                stretchedCellWidths.append(cellWidth)
            }

            return stretchedCellWidths
        }
    }
}

// MARK: Protocols

protocol IndicatorInfoProvider {

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo

}

protocol PagerTabStripIsProgressiveDelegate: AnyObject {

    func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool)
}

protocol PagerTabStripDataSource: AnyObject {

    func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController]
}


