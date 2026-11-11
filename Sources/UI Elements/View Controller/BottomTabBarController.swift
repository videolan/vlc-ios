/*****************************************************************************
 * BottomTabBarController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2025 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *          Neo Salmon <neos_dev@outlook.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import SwiftUI

extension Notification.Name {
    static let VLCMiniPlayerDisplayedNotification = Notification.Name(kVLCMiniPlayerDisplayedNotification)
    static let VLCMiniPlayerHiddenNotification = Notification.Name(kVLCMiniPlayerHiddenNotification)
}

@objc(VLCBottomTabBarController)
class BottomTabBarController: UITabBarController {
    // MARK: - Properties
    private var bottomEditToolbarConstraints: [NSLayoutConstraint] = []

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    private lazy var audioMiniPlayer: AudioMiniPlayer = {
        let miniPlayer = AudioMiniPlayer()
        if #unavailable(iOS 26) {
            miniPlayer.translatesAutoresizingMaskIntoConstraints = false
        }

        return miniPlayer
    }()

    private static let legacyContentInsetConstant: CGFloat = 8
    private var legacyMiniPlayerNeedsUpdatedConstraints: Bool = false
    private var legacyMiniPlayerConstraints: [NSLayoutConstraint] = []
    private var legacyMiniPlayerBottomConstraint: NSLayoutConstraint?

    @objc
    public private(set) var isMiniPlayerVisible: Bool = false

    @objc
    public var miniPlayerZoomEndpoint: ZoomTransitionEndpoint? {
        audioMiniPlayer
    }

    private var transferStatusBottomAnchorNeedsRefresh: Bool = false
    private var transferStatusBannerController: VLCTransferStatusBannerController!

    #if os(iOS)
    override var viewControllers: [UIViewController]? {
        didSet {
            updateLegacyMiniPlayerSafeAreaInsets()
        }
    }
    #endif

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()

        transferStatusBannerController = VLCTransferStatusBannerController(containerView: view, delegate: self)

        #if os(iOS)
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior = .onScrollDown
        }
        #endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if #unavailable(iOS 26.0) {
            tabBar.layer.shadowPath = UIBezierPath(rect: tabBar.bounds).cgPath
            if legacyMiniPlayerNeedsUpdatedConstraints {
                setupMiniPlayerLayout()
            }
            if transferStatusBottomAnchorNeedsRefresh {
                refreshTransferStatusBottomAnchor()
            }
        }
    }

    #if os(iOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #unavailable(iOS 26) else { return }

        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            transferStatusBottomAnchorNeedsRefresh = true
            legacyMiniPlayerNeedsUpdatedConstraints = isMiniPlayerVisible
        }
    }
    #endif

    // MARK: - Mini-player display

    @objc
    func displayMiniPlayer(_ display: Bool, animated: Bool) {
        #if os(iOS)
        if #available(iOS 26, *) {
            setBottomAccessory(display ? UITabAccessory(contentView: audioMiniPlayer) : nil, animated: animated)
            isMiniPlayerVisible = display
            if display {
                audioMiniPlayer.prepare(forMediaPlayback: PlaybackService.sharedInstance())
            }
        } else if display {
            view.addSubview(audioMiniPlayer)
            isMiniPlayerVisible = true
            setupMiniPlayerLayout()
            audioMiniPlayer.prepare(forMediaPlayback: PlaybackService.sharedInstance())
            guard let legacyMiniPlayerBottomConstraint else { return }
            legacyMiniPlayerBottomConstraint.constant = legacyMiniPlayerOffscreenConstant
            view.layoutIfNeeded()
            UIView.animate(withDuration: animated ? 0.2 : 0) {
                self.animateLegacyMiniPlayerShow()
            }
        } else {
            isMiniPlayerVisible = false
            view.layoutIfNeeded()
            UIView.animate(withDuration: animated ? 0.2 : 0, animations: {
                self.animateLegacyMiniPlayerHide()
            }, completion: { _ in
                if !self.isMiniPlayerVisible {
                    self.audioMiniPlayer.removeFromSuperview()
                }
            })
        }
        #else
        if display {
            self.ornaments = [UIHostingOrnament(sceneAnchor: .bottom, content: {
                AudioMiniPlayerOrnamentView()
                    .glassBackgroundEffect()
                    .scenePadding()
            })]
        } else {
            self.ornaments = []
        }
        isMiniPlayerVisible = display
        #endif

        NotificationCenter.default.post(name: display ? .VLCMiniPlayerDisplayedNotification : .VLCMiniPlayerHiddenNotification, object: self)
    }

    private var legacyMiniPlayerPinsToSafeArea: Bool {
        guard #available(iOS 18, *) else { return false }
        return traitCollection.horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad
    }

    private var legacyMiniPlayerOffscreenConstant: CGFloat {
        let height = CGFloat(audioMiniPlayer.contentHeight)
        return legacyMiniPlayerPinsToSafeArea ? view.safeAreaInsets.bottom + height : tabBar.bounds.height + height
    }

    private func updateLegacyMiniPlayerSafeAreaInsets() {
        guard #unavailable(iOS 26) else { return }
        let bottomInset = isMiniPlayerVisible ? CGFloat(audioMiniPlayer.contentHeight) + Self.legacyContentInsetConstant * 2 : 0
        viewControllers?.forEach {
            $0.additionalSafeAreaInsets.bottom = bottomInset
        }
    }

    private func animateLegacyMiniPlayerShow() {
        guard let legacyMiniPlayerBottomConstraint else { return }
        legacyMiniPlayerBottomConstraint.constant = -Self.legacyContentInsetConstant
        updateLegacyMiniPlayerSafeAreaInsets()
        refreshTransferStatusBottomAnchor()
        view.layoutIfNeeded()
    }

    private func animateLegacyMiniPlayerHide() {
        guard let legacyMiniPlayerBottomConstraint else { return }
        legacyMiniPlayerBottomConstraint.constant = legacyMiniPlayerOffscreenConstant
        updateLegacyMiniPlayerSafeAreaInsets()
        refreshTransferStatusBottomAnchor()
        view.layoutIfNeeded()
    }

    private func setupMiniPlayerLayout() {
        guard isMiniPlayerVisible else { return }

        NSLayoutConstraint.deactivate(legacyMiniPlayerConstraints)

        legacyMiniPlayerConstraints = [
            audioMiniPlayer.heightAnchor.constraint(equalToConstant: CGFloat(audioMiniPlayer.contentHeight))
        ]

        if traitCollection.horizontalSizeClass == .regular {
            if legacyMiniPlayerPinsToSafeArea {
                legacyMiniPlayerBottomConstraint = audioMiniPlayer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Self.legacyContentInsetConstant)
            } else {
                legacyMiniPlayerBottomConstraint = audioMiniPlayer.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: -Self.legacyContentInsetConstant)
            }

            legacyMiniPlayerConstraints.append(contentsOf: [
                audioMiniPlayer.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                audioMiniPlayer.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: AudioMiniPlayer.largeScreenWidthFactor),
                legacyMiniPlayerBottomConstraint!
            ])
        } else {
            legacyMiniPlayerBottomConstraint = audioMiniPlayer.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: -Self.legacyContentInsetConstant)
            legacyMiniPlayerConstraints.append(contentsOf: [
                audioMiniPlayer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Self.legacyContentInsetConstant),
                audioMiniPlayer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Self.legacyContentInsetConstant),
                legacyMiniPlayerBottomConstraint!
            ])
        }

        NSLayoutConstraint.activate(legacyMiniPlayerConstraints)
        legacyMiniPlayerNeedsUpdatedConstraints = false
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

// MARK: Transfer status

extension BottomTabBarController: VLCTransferStatusBannerControllerDelegate {
    func refreshTransferStatusBottomAnchor() {
        transferStatusBannerController.refreshBottomAnchor()
        transferStatusBottomAnchorNeedsRefresh = false
    }

    func bottomAnchor(forTransferStatusBanner controller: VLCTransferStatusBannerController!) -> NSLayoutYAxisAnchor! {
        #if os(visionOS)
        if #available(visionOS 26, *) {
            return contentLayoutGuide.bottomAnchor
        } else {
            return view.safeAreaLayoutGuide.bottomAnchor
        }
        #else
        if #available(iOS 26, *) {
            return contentLayoutGuide.bottomAnchor
        } else if isMiniPlayerVisible {
            return audioMiniPlayer.topAnchor
        } else if #available(iOS 18, *) {
            return traitCollection.horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad
            ? view.safeAreaLayoutGuide.bottomAnchor : tabBar.topAnchor
        } else {
            return tabBar.topAnchor
        }
        #endif
    }

    func safeAreaLayoutGuide(forTransferStatusBanner controller: VLCTransferStatusBannerController!) -> UILayoutGuide! {
        if #available(iOS 26, visionOS 26, *) {
            return contentLayoutGuide
        } else {
            return view.safeAreaLayoutGuide
        }
    }

    func transferStatusBannerWasTapped(_ controller: VLCTransferStatusBannerController!) {
        let transferVC = VLCTransferViewController()
        transferVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissTransfersViewController))
        present(UINavigationController(rootViewController: transferVC), animated: true)
    }

    @objc
    private func dismissTransfersViewController(_ sender: Any) {
        dismiss(animated: true)
    }
}
