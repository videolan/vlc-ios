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
        let miniPlayer = AudioMiniPlayer(draggingDelegate: BlankMiniPlayerDraggingDelegate())
        if #unavailable(iOS 26) {
            miniPlayer.translatesAutoresizingMaskIntoConstraints = false
        }
        
        return miniPlayer
    }()
    
    private var legacyMiniPlayerNeedsUpdatedConstraints: Bool = false
    private var legacyMiniPlayerConstraints: [NSLayoutConstraint] = []
    private var legacyMiniPlayerBottomConstraint: NSLayoutConstraint?
    
    @objc
    public private(set) var isMiniPlayerVisible: Bool = false
    
    @objc
    public var miniPlayerZoomEndpoint: ZoomTransitionEndpoint? {
        audioMiniPlayer
    }
    
    private static let legacyContentInsetConstant: CGFloat = 8

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        }
    }
    
    #if os(iOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard #unavailable(iOS 26) else { return }
        
        if isMiniPlayerVisible && traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            legacyMiniPlayerNeedsUpdatedConstraints = true
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
            if #available(iOS 18, *), traitCollection.horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad {
                legacyMiniPlayerBottomConstraint.constant = CGFloat(audioMiniPlayer.contentHeight)
            } else {
                legacyMiniPlayerBottomConstraint.constant = tabBar.bounds.height + CGFloat(audioMiniPlayer.contentHeight)
            }
            view.layoutIfNeeded()
            UIView.animate(withDuration: animated ? 0.2 : 0) {
                self.animateLegacyMiniPlayerShow()
            }
        } else {
            view.layoutIfNeeded()
            UIView.animate(withDuration: animated ? 0.2 : 0) {
                self.animateLegacyMiniPlayerHide()
            }
        }
        #else
        if !display {
            self.ornaments = []
        } else {
            self.ornaments = [UIHostingOrnament(sceneAnchor: .bottom, content: {
                AudioMiniPlayerOrnamentBridge()
                    .glassBackgroundEffect()
                    .scenePadding()
            })]
        }
        isMiniPlayerVisible = display
        #endif
        
        NotificationCenter.default.post(name: display ? .VLCMiniPlayerDisplayedNotification : .VLCMiniPlayerHiddenNotification, object: self)
    }
    
    private func animateLegacyMiniPlayerShow() {
        guard let legacyMiniPlayerBottomConstraint else { return }
        var edgeInsets = UIEdgeInsets()
        edgeInsets.bottom = CGFloat(audioMiniPlayer.contentHeight) + Self.legacyContentInsetConstant * 2
        legacyMiniPlayerBottomConstraint.constant = -Self.legacyContentInsetConstant
        viewControllers?.forEach {
            $0.additionalSafeAreaInsets = edgeInsets
        }
        view.layoutIfNeeded()
    }
    
    private func animateLegacyMiniPlayerHide() {
        guard let legacyMiniPlayerBottomConstraint else { return }
        let miniPlayerOffscreenConstant: CGFloat
        if #available(iOS 18, *), traitCollection.horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad {
            miniPlayerOffscreenConstant = CGFloat(audioMiniPlayer.contentHeight)
        } else {
            miniPlayerOffscreenConstant = tabBar.bounds.height + CGFloat(audioMiniPlayer.contentHeight)
        }
        legacyMiniPlayerBottomConstraint.constant = miniPlayerOffscreenConstant
        viewControllers?.forEach {
            $0.additionalSafeAreaInsets = .zero
        }
        self.isMiniPlayerVisible = false
        self.audioMiniPlayer.removeFromSuperview()
        view.layoutIfNeeded()
    }
    
    private func setupMiniPlayerLayout() {
        guard isMiniPlayerVisible else { return }
        
        NSLayoutConstraint.deactivate(legacyMiniPlayerConstraints)
        
        legacyMiniPlayerConstraints = [
            audioMiniPlayer.heightAnchor.constraint(equalToConstant: CGFloat(audioMiniPlayer.contentHeight))
        ]
        
        if traitCollection.horizontalSizeClass == .regular {
            if #available(iOS 18, *), UIDevice.current.userInterfaceIdiom == .pad {
                legacyMiniPlayerBottomConstraint = audioMiniPlayer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Self.legacyContentInsetConstant)
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

class BlankMiniPlayerDraggingDelegate: MiniPlayerDraggingDelegate {
    func miniPlayerDragStateDidChange(_ miniPlayer: AudioMiniPlayer, sender: UIPanGestureRecognizer, panDirection: PanDirection) {
        
    }
    
    func miniPlayerDragDidEnd(_ miniPlayer: AudioMiniPlayer, sender: UIPanGestureRecognizer, panDirection: PanDirection) {
        
    }
    
    func miniPlayerPositionToTop(_ miniPlayer: AudioMiniPlayer) {
        
    }
    
    func miniPlayerPositionToBottom(_ miniPlayer: AudioMiniPlayer, completion: ((Bool) -> Void)?) {
        
    }
    
    func miniPlayerCenterHorizontaly(_ miniPlayer: AudioMiniPlayer) {
        
    }
    
    func miniPlayerNeedsLayout(_ miniPlayer: AudioMiniPlayer) {
        
    }
}

struct AudioMiniPlayerOrnamentBridge: UIViewRepresentable {
    func makeUIView(context: Context) -> AudioMiniPlayer {
        let miniPlayer = AudioMiniPlayer(draggingDelegate: BlankMiniPlayerDraggingDelegate())
        miniPlayer.prepare(forMediaPlayback: PlaybackService.sharedInstance())
        return miniPlayer
    }
    
    func updateUIView(_ uiView: AudioMiniPlayer, context: Context) {}
}
