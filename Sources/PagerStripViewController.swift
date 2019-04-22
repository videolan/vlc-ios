/*****************************************************************************
 * PagerTabStripViewController.Swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class PagerTabStripViewController: UIViewController, UIScrollViewDelegate {

    var containerView: UIScrollView!

    weak var delegate: PagerTabStripIsProgressiveDelegate?
    weak var datasource: PagerTabStripDataSource?

    private(set) var viewControllers = [UIViewController]()
    private(set) var currentIndex = 0
    private(set) var preCurrentIndex = 0 // used *only* to store the index to which move when the pager becomes visible

    private var pagerTabStripChildViewControllersForScrolling: [UIViewController]?
    private var lastPageNumber = 0
    private var lastContentOffset: CGFloat = 0.0
    private var pageBeforeRotate = 0
    private var lastSize = CGSize(width: 0, height: 0)
    var isViewRotating = false
    var isViewAppearing = false

    var pageWidth: CGFloat {
        return containerView.bounds.width
    }

    var scrollPercentage: CGFloat {
        if swipeDirection != .right {
            let module = fmod(containerView.contentOffset.x, pageWidth)
            return module == 0.0 ? 1.0 : module / pageWidth
        }
        return 1 - fmod(containerView.contentOffset.x >= 0 ? containerView.contentOffset.x : pageWidth + containerView.contentOffset.x, pageWidth) / pageWidth
    }

    var swipeDirection: SwipeDirection {
        if containerView.contentOffset.x > lastContentOffset {
            return .left
        } else if containerView.contentOffset.x < lastContentOffset {
            return .right
        }
        return .none
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        containerView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.scrollsToTop = false
        containerView.delegate = self
        containerView.showsVerticalScrollIndicator = false
        containerView.showsHorizontalScrollIndicator = false
        containerView.isPagingEnabled = true
        containerView.backgroundColor = PresentationTheme.current.colors.background
        if #available(iOS 11.0, *) {
            containerView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        view.addSubview(containerView)

        reloadViewControllers()

        let childController = viewControllers[currentIndex]
        addChild(childController)
        childController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        containerView.addSubview(childController.view)
        childController.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isViewAppearing = true
        children.forEach { $0.beginAppearanceTransition(true, animated: animated) }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lastSize = containerView.bounds.size
        updateIfNeeded()
        let needToUpdateCurrentChild = preCurrentIndex != currentIndex
        if needToUpdateCurrentChild {
            moveToViewController(at: preCurrentIndex)
        }
        isViewAppearing = false
        children.forEach { $0.endAppearanceTransition() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        children.forEach { $0.beginAppearanceTransition(false, animated: animated) }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        children.forEach { $0.endAppearanceTransition() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateIfNeeded()
    }

    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return false
    }

    func moveToViewController(at index: Int, animated: Bool = true) {
        guard isViewLoaded && view.window != nil && currentIndex != index else {
            preCurrentIndex = index
            return
        }

        if animated && abs(currentIndex - index) > 1 {
            var tmpViewControllers = viewControllers
            let currentChildVC = viewControllers[currentIndex]
            let fromIndex = currentIndex < index ? index - 1 : index + 1
            let fromChildVC = viewControllers[fromIndex]
            tmpViewControllers[currentIndex] = fromChildVC
            tmpViewControllers[fromIndex] = currentChildVC
            pagerTabStripChildViewControllersForScrolling = tmpViewControllers
            containerView.setContentOffset(CGPoint(x: pageOffsetForChild(at: fromIndex), y: 0), animated: false)
            (navigationController?.view ?? view).isUserInteractionEnabled = !animated
            containerView.setContentOffset(CGPoint(x: pageOffsetForChild(at: index), y: 0), animated: true)
        } else {
            (navigationController?.view ?? view).isUserInteractionEnabled = !animated
            containerView.setContentOffset(CGPoint(x: pageOffsetForChild(at: index), y: 0), animated: animated)
        }
    }

    func moveTo(viewController: UIViewController, animated: Bool = true) {
        moveToViewController(at: viewControllers.firstIndex(of: viewController)!, animated: animated)
    }

    // MARK: - PagerTabStripDataSource

    func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        assertionFailure("Sub-class must implement the PagerTabStripDataSource viewControllers(for:) method")
        return []
    }

    // MARK: - Helpers

    func updateIfNeeded() {
        if isViewLoaded && !lastSize.equalTo(containerView.bounds.size) {
            updateContent()
        }
    }

    func scrollingEnabled(_ enabled: Bool) {
        containerView.isScrollEnabled = enabled
    }

    func pageOffsetForChild(at index: Int) -> CGFloat {
        return CGFloat(index) * containerView.bounds.width
    }

    func offsetForChild(at index: Int) -> CGFloat {
        return (CGFloat(index) * containerView.bounds.width) + ((containerView.bounds.width - view.bounds.width) * 0.5)
    }

    enum PagerTabStripError: Error {
        case viewControllerOutOfBounds
    }

    func offsetForChild(viewController: UIViewController) throws -> CGFloat {
        guard let index = viewControllers.firstIndex(of: viewController) else {
            throw PagerTabStripError.viewControllerOutOfBounds
        }
        return offsetForChild(at: index)
    }

    func pageFor(contentOffset: CGFloat) -> Int {
        let result = virtualPageFor(contentOffset: contentOffset)
        return pageFor(virtualPage: result)
    }

    func virtualPageFor(contentOffset: CGFloat) -> Int {
        return Int((contentOffset + 1.5 * pageWidth) / pageWidth) - 1
    }

    func pageFor(virtualPage: Int) -> Int {
        if virtualPage < 0 {
            return 0
        }
        if virtualPage > viewControllers.count - 1 {
            return viewControllers.count - 1
        }
        return virtualPage
    }

    func updateContent() {
        if lastSize.width != containerView.bounds.size.width {
            lastSize = containerView.bounds.size
            containerView.contentOffset = CGPoint(x: pageOffsetForChild(at: currentIndex), y: 0)
        }
        lastSize = containerView.bounds.size

        let pagerViewControllers = pagerTabStripChildViewControllersForScrolling ?? viewControllers
        containerView.contentSize = CGSize(width: containerView.bounds.width * CGFloat(pagerViewControllers.count), height: containerView.contentSize.height)

        for (index, childController) in pagerViewControllers.enumerated() {
            let pageOffsetForChild = self.pageOffsetForChild(at: index)
            if abs(containerView.contentOffset.x - pageOffsetForChild) < containerView.bounds.width {
                if childController.parent != nil {
                    childController.view.frame = CGRect(x: offsetForChild(at: index), y: 0, width: view.bounds.width, height: containerView.bounds.height)
                    childController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                } else {
                    childController.beginAppearanceTransition(true, animated: false)
                    addChild(childController)
                    childController.view.frame = CGRect(x: offsetForChild(at: index), y: 0, width: view.bounds.width, height: containerView.bounds.height)
                    childController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                    containerView.addSubview(childController.view)
                    childController.didMove(toParent: self)
                    childController.endAppearanceTransition()
                }
            } else {
                if childController.parent != nil {
                    childController.beginAppearanceTransition(false, animated: false)
                    childController.willMove(toParent: nil)
                    childController.view.removeFromSuperview()
                    childController.removeFromParent()
                    childController.endAppearanceTransition()
                }
            }
        }

        let oldCurrentIndex = currentIndex
        let virtualPage = virtualPageFor(contentOffset: containerView.contentOffset.x)
        let newCurrentIndex = pageFor(virtualPage: virtualPage)
        currentIndex = newCurrentIndex
        preCurrentIndex = currentIndex
        let changeCurrentIndex = newCurrentIndex != oldCurrentIndex

        if let progressiveDelegate = self as? PagerTabStripIsProgressiveDelegate {

            let (fromIndex, toIndex, scrollPercentage) = progressiveIndicatorData(virtualPage)
            progressiveDelegate.updateIndicator(for: self, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: scrollPercentage, indexWasChanged: changeCurrentIndex)
        }
    }

    func reloadPagerTabStripView() {
        guard isViewLoaded else { return }
        for childController in viewControllers where childController.parent != nil {
            childController.beginAppearanceTransition(false, animated: false)
            childController.willMove(toParent: nil)
            childController.view.removeFromSuperview()
            childController.removeFromParent()
            childController.endAppearanceTransition()
        }
        reloadViewControllers()
        containerView.contentSize = CGSize(width: containerView.bounds.width * CGFloat(viewControllers.count), height: containerView.contentSize.height)
        if currentIndex >= viewControllers.count {
            currentIndex = viewControllers.count - 1
        }
        preCurrentIndex = currentIndex
        containerView.contentOffset = CGPoint(x: pageOffsetForChild(at: currentIndex), y: 0)
        updateContent()
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if containerView == scrollView {
            updateContent()
            lastContentOffset = scrollView.contentOffset.x
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if containerView == scrollView {
            lastPageNumber = pageFor(contentOffset: scrollView.contentOffset.x)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if containerView == scrollView {
            pagerTabStripChildViewControllersForScrolling = nil
            (navigationController?.view ?? view).isUserInteractionEnabled = true
            updateContent()
        }
    }

    // MARK: - Orientation

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        isViewRotating = true
        pageBeforeRotate = currentIndex
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let me = self else { return }
            me.isViewRotating = false
            me.currentIndex = me.pageBeforeRotate
            me.preCurrentIndex = me.currentIndex
            me.updateIfNeeded()
        }
    }

    // MARK: Private

    private func progressiveIndicatorData(_ virtualPage: Int) -> (Int, Int, CGFloat) {
        let count = viewControllers.count
        var fromIndex = currentIndex
        var toIndex = currentIndex
        let direction = swipeDirection

        if direction == .left {
            if virtualPage > count - 1 {
                fromIndex = count - 1
                toIndex = count
            } else {
                if self.scrollPercentage >= 0.5 {
                    fromIndex = max(toIndex - 1, 0)
                } else {
                    toIndex = fromIndex + 1
                }
            }
        } else if direction == .right {
            if virtualPage < 0 {
                fromIndex = 0
                toIndex = -1
            } else {
                if self.scrollPercentage > 0.5 {
                    fromIndex = min(toIndex + 1, count - 1)
                } else {
                    toIndex = fromIndex - 1
                }
            }
        }

        return (fromIndex, toIndex, self.scrollPercentage)
    }

    private func reloadViewControllers() {
        guard let dataSource = datasource else {
            fatalError("dataSource must not be nil")
        }
        viewControllers = dataSource.viewControllers(for: self)

        guard !viewControllers.isEmpty else {
            fatalError("viewControllers(for:) should provide at least one child view controller")
        }
        viewControllers.forEach { if !($0 is IndicatorInfoProvider) { fatalError("Every view controller provided by PagerTabStripDataSource's viewControllers(for:) method must conform to IndicatorInfoProvider") }}

    }
}
