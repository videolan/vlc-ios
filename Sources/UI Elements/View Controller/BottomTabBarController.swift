/*****************************************************************************
 * BottomTabBarController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2025 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc(VLCBottomTabBarController)
class BottomTabBarController: UITabBarController {
    // MARK: - Properties

    @objc lazy var bottomBar: UITabBar = {
        let bottomBar = UITabBar()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        return bottomBar
    }()

    lazy var isBottomBarActive: Bool = {
//        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad,
//           self.responds(to: Selector("setTabBarHidden:animated:")) {
//            self.perform(Selector("setTabBarHidden:animated:"), with: true, with: true)
//            return true
//        }

        return false
    }()

    var tabBarHeightConstraint: NSLayoutConstraint?

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()

        guard isBottomBarActive else {
            return
        }

        tabBar.isHidden = true
        bottomBar.items = tabBar.items
        bottomBar.selectedItem = tabBar.selectedItem

        view.addSubview(bottomBar)
        let heightConstraint = bottomBar.heightAnchor.constraint(equalToConstant: 1)
        tabBarHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            heightConstraint
        ])
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        guard isBottomBarActive else {
            return
        }

        bottomBar.items = tabBar.items
        bottomBar.selectedItem = tabBar.selectedItem
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard isBottomBarActive else {
            return
        }

        let height = bottomBar.intrinsicContentSize.height
        tabBarHeightConstraint?.constant = height
    }

    // MARK: - Helpers

    func editToolBar() -> EditToolbar? {
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            return bottomBar.subviews.filter() { $0 is EditToolbar }.first as? EditToolbar
        }

        return tabBar.subviews.filter() { $0 is EditToolbar }.first as? EditToolbar
    }

    func displayEditToolbar(with model: MediaLibraryBaseModel) {
        guard let editToolbar = editToolBar() else {
            return
        }

        bottomBar.bringSubviewToFront(editToolbar)
        editToolbar.updateEditToolbar(for: model)
        editToolbar.isHidden = false
    }

    func hideEditToolbar() {
        guard let editToolbar = editToolBar() else {
            return
        }

        editToolbar.isHidden = true
    }
}
