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
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            return false
        }

        return false
    }()

    var tabBarHeightConstraint: NSLayoutConstraint?

    private var bottomEditToolbarConstraints: [NSLayoutConstraint] = []

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()

        guard isBottomBarActive else {
            return
        }

        bottomBar.isHidden = true
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

        if #unavailable(iOS 26.0) {
            tabBar.layer.shadowPath = UIBezierPath(rect: tabBar.bounds).cgPath
        }

        guard isBottomBarActive else {
            return
        }

        let height = bottomBar.intrinsicContentSize.height
        tabBarHeightConstraint?.constant = height

        if #unavailable(iOS 26.0) {
            bottomBar.layer.shadowPath = UIBezierPath(rect: bottomBar.bounds).cgPath
        }
    }

    // MARK: - Helpers

    var editToolbarSetupHandler: (() -> Void)?

    func ensureEditToolbarSetup() {
        guard let handler = editToolbarSetupHandler else {
            return
        }
        editToolbarSetupHandler = nil
        handler()
    }

    var bottomEditToolbar: EditToolbar? {
        return view.subviews.first { $0 is EditToolbar } as? EditToolbar
    }

    func editToolBar() -> EditToolbar? {
#if os(iOS)
        if isSidebarShown || usesVerticalBar {
            return nil
        }
#endif

        guard let toolbar = bottomEditToolbar, tabBar.isDescendant(of: view) else {
            return nil
        }

        pinBottomEditToolbarToTabBar(toolbar)
        return toolbar
    }

    private func pinBottomEditToolbarToTabBar(_ toolbar: EditToolbar) {
        if !bottomEditToolbarConstraints.isEmpty,
           bottomEditToolbarConstraints.allSatisfy({ $0.isActive }) {
            return
        }

        NSLayoutConstraint.deactivate(bottomEditToolbarConstraints)
        bottomEditToolbarConstraints = [
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolbar.topAnchor.constraint(equalTo: tabBar.topAnchor),
        ]
        NSLayoutConstraint.activate(bottomEditToolbarConstraints)
    }

    func displayEditToolbar(with model: MediaLibraryBaseModel) {
        guard let editToolbar = editToolBar() else {
            return
        }

        view.bringSubviewToFront(editToolbar)
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

#if os(iOS)
// MARK: - Sidebar availability

extension UITabBarController {
    var isSidebarAvailable: Bool {
        if #available(iOS 27.0, *),
           sidebar.responds(to: NSSelectorFromString("isAvailable")) {
            return sidebar.value(forKey: "isAvailable") as? Bool ?? false
        }

        if #available(iOS 18.0, *) {
            return UIDevice.current.userInterfaceIdiom == .pad
        }

        return false
    }

    var isSidebarShown: Bool {
        guard #available(iOS 18.0, *) else {
            return false
        }

        return isSidebarAvailable && !sidebar.isHidden
    }

    var canShowSidebar: Bool {
        guard #available(iOS 18.0, *) else {
            return false
        }

        if #available(iOS 27.0, *) {
            return true
        }

        return UIDevice.current.userInterfaceIdiom == .pad
    }

    var usesVerticalBar: Bool {
        if #available(iOS 27.1, *),
           traitCollection.responds(to: NSSelectorFromString("verticalBarEdge")) {
            return (traitCollection.value(forKey: "verticalBarEdge") as? Int ?? 0) != 0
        }

        return false
    }
}
#endif
