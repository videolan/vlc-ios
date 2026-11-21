/*****************************************************************************
 * FloatingActionButtonController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol FloatingActionButtonClient: UIViewController {
    var floatingAction: FloatingActionButtonController.Action? { get }
}

final class FloatingActionButtonController: NSObject {
    enum Action {
        case shuffleAudio
        case playAllVideo

        fileprivate var image: UIImage? {
            let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
            switch self {
            case .shuffleAudio:
                return UIImage(systemName: "shuffle", withConfiguration: configuration)
            case .playAllVideo:
                return UIImage(systemName: "play.fill", withConfiguration: configuration)
            }
        }

        fileprivate var accessibilityLabel: String {
            switch self {
            case .shuffleAudio:
                return NSLocalizedString("SHUFFLE", comment: "")
            case .playAllVideo:
                return NSLocalizedString("PLAY_ALL_BUTTON", comment: "")
            }
        }
    }

    private struct Registration {
        weak var client: FloatingActionButtonClient?
    }

    private static let size: CGFloat = 44
    private static let margin: CGFloat = 15

    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
#if !os(visionOS)
        if #available(iOS 26.0, *) {
            var config: UIButton.Configuration = .prominentGlass()
            config.baseBackgroundColor = PresentationTheme.current.colors.orangeUI
            config.baseForegroundColor = .white
            config.cornerStyle = .capsule
            button.configuration = config
            return button
        }
#endif
        button.backgroundColor = PresentationTheme.current.colors.orangeUI
        button.tintColor = PresentationTheme.current.colors.background
        button.layer.cornerRadius = FloatingActionButtonController.size / 2
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        button.layer.shadowRadius = 4.0
        button.layer.shadowOpacity = 0.3
        button.layer.shadowPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0,
                                                              width: FloatingActionButtonController.size,
                                                              height: FloatingActionButtonController.size)).cgPath
        return button
    }()

    private var registrations: [Registration] = []
    private var refreshScheduled = false
    private var action: Action?
    private var isShown = false
    private var bottomConstraint: NSLayoutConstraint?
    private weak var bottomConstraintClient: UIViewController?
    private var anchorsToContainerBottom: Bool?

    init(containerView: UIView) {
        super.init()

        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        containerView.addSubview(button)

        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor, constant: -Self.margin),
            button.widthAnchor.constraint(equalToConstant: Self.size),
            button.heightAnchor.constraint(equalToConstant: Self.size)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
    }

    func register(_ client: FloatingActionButtonClient) {
        registrations.removeAll { $0.client == nil || $0.client === client }
        registrations.append(Registration(client: client))
        setNeedsRefresh()
    }

    func unregister(_ client: FloatingActionButtonClient) {
        if bottomConstraintClient === client {
            pinBottomInPlace()
        }
        registrations.removeAll { $0.client == nil || $0.client === client }
        setNeedsRefresh()
    }

    func setNeedsRefresh() {
        guard !refreshScheduled else { return }
        refreshScheduled = true
        DispatchQueue.main.async {
            self.refreshScheduled = false
            self.refresh()
        }
    }

    // iPadOS 18+ keeps the tab bar at the top in regular width, but moves it back to
    // the bottom in compact width, so the anchor has to follow window resizes.
    func updateBottomConstraint() {
        guard let client = bottomConstraintClient else { return }
        pinBottom(to: client)
    }

    private func refresh() {
        registrations.removeAll { $0.client == nil }
        guard let client = registrations.last?.client,
              let action = client.floatingAction else {
            setShown(false)
            return
        }

        pinBottom(to: client)
        setAction(action)
        setShown(true)
    }

    private func setAction(_ action: Action) {
        guard action != self.action else { return }
        self.action = action
        button.accessibilityLabel = action.accessibilityLabel

#if !os(visionOS)
        if #available(iOS 26.0, *), var config = button.configuration {
            config.image = action.image
            config.symbolContentTransition = isShown ? UISymbolContentTransition(.replace) : nil
            button.configuration = config
            return
        }
#endif
        guard isShown else {
            button.setImage(action.image, for: .normal)
            return
        }
        UIView.transition(with: button, duration: 0.2, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.button.setImage(action.image, for: .normal)
        }
    }

    private func setShown(_ shown: Bool) {
        guard shown != isShown else { return }
        isShown = shown

        let hiddenTransform = UIAccessibility.isReduceMotionEnabled ? .identity : CGAffineTransform(scaleX: 0.6, y: 0.6)

        guard shown else {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn, .beginFromCurrentState]) {
                self.button.alpha = 0
                self.button.transform = hiddenTransform
            } completion: { _ in
                if !self.isShown {
                    self.button.isHidden = true
                }
            }
            return
        }

        if button.isHidden {
            UIView.performWithoutAnimation {
                button.alpha = 0
                button.transform = hiddenTransform
                button.isHidden = false
                button.superview?.layoutIfNeeded()
            }
        }
        button.superview?.bringSubviewToFront(button)

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.button.alpha = 1
            self.button.transform = .identity
        }
    }

    private func pinBottom(to client: UIViewController) {
        guard let containerView = button.superview,
              let tabBar = client.tabBarController?.tabBar,
              client.view.isDescendant(of: containerView) else { return }

        let anchorsToContainerBottom: Bool
#if os(iOS)
        anchorsToContainerBottom = (client.tabBarController?.isSidebarAvailable == true
            && client.traitCollection.horizontalSizeClass == .regular)
            || !tabBar.isDescendant(of: containerView)
#else
        anchorsToContainerBottom = false
#endif

        if bottomConstraintClient === client,
           self.anchorsToContainerBottom == anchorsToContainerBottom,
           bottomConstraint?.isActive == true { return }
        bottomConstraintClient = client
        self.anchorsToContainerBottom = anchorsToContainerBottom

        let anchor = anchorsToContainerBottom ? containerView.bottomAnchor : client.view.safeAreaLayoutGuide.bottomAnchor
        replaceBottomConstraint(with: button.bottomAnchor.constraint(equalTo: anchor, constant: -Self.margin))
    }

    private func pinBottomInPlace() {
        guard let containerView = button.superview else { return }
        let offset = button.center.y + button.bounds.height / 2 - containerView.bounds.height
        replaceBottomConstraint(with: button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: offset))
        bottomConstraintClient = nil
        anchorsToContainerBottom = nil
    }

    private func replaceBottomConstraint(with constraint: NSLayoutConstraint) {
        bottomConstraint?.isActive = false
        constraint.isActive = true
        bottomConstraint = constraint
    }

    @objc private func buttonPressed() {
        let medialib = VLCAppCoordinator.sharedInstance().mediaLibraryService.medialib
        let playbackService = PlaybackService.sharedInstance()
        switch action {
        case .shuffleAudio:
            guard let tracks = medialib.audioFiles(), !tracks.isEmpty else { return }
            playbackService.isShuffleMode = true
            playbackService.playCollection(tracks)
        case .playAllVideo:
            guard let videos = medialib.videoFiles(), !videos.isEmpty else { return }
            playbackService.isShuffleMode = false
            playbackService.playCollection(videos)
        case .none:
            break
        }
    }

    @objc private func themeDidChange() {
        if #unavailable(iOS 26.0) {
            button.tintColor = PresentationTheme.current.colors.background
        }
    }
}
