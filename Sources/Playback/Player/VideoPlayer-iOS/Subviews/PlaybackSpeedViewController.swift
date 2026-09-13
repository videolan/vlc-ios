/*****************************************************************************
 * PlaybackSpeedViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol PlaybackSpeedViewControllerDelegate: AnyObject {
    func playbackSpeedViewControllerDidChangeSpeed(_ controller: PlaybackSpeedViewController)
}

final class PlaybackSpeedViewController: UIViewController {
    weak var delegate: PlaybackSpeedViewControllerDelegate?

    private let controlsView: PlaybackSpeedControlsView
    private var lastPreferredSheetHeight: CGFloat = 0

    private let backgroundContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    init(isAudioPlayer: Bool, delegate: PlaybackSpeedViewControllerDelegate?) {
        controlsView = PlaybackSpeedControlsView(style: .sheet, isAudioPlayer: isAudioPlayer)
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        controlsView.delegate = self
        configureSheetPresentation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }

        backgroundContainer.roundCorners(radius: 30)
        backgroundContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(backgroundContainer)
        installBackgroundEffect()
        view.addSubview(controlsView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            controlsView.topAnchor.constraint(equalTo: guide.topAnchor),
            controlsView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            controlsView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            controlsView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
        ])

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(installBackgroundEffect),
                                               name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                                               object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        controlsView.storeDefaultSpeed()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if #available(iOS 13.0, *) {
            controlsView.setCloseButtonVisible(traitCollection.verticalSizeClass == .compact)
        } else {
            controlsView.setCloseButtonVisible(true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSheetDetents()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(close))]
    }

    override func accessibilityPerformEscape() -> Bool {
        close()
        return true
    }

    // MARK: - Sheet

    private func updateSheetDetents() {
#if !os(visionOS)
        let width = controlsView.bounds.width
        guard #available(iOS 16.0, *), width > 0 else {
            return
        }

        let height = controlsView.fittingHeight(forWidth: width)
        guard abs(height - lastPreferredSheetHeight) > 0.5 else {
            return
        }

        lastPreferredSheetHeight = height
        sheetPresentationController?.animateChanges {
            self.sheetPresentationController?.invalidateDetents()
        }
#endif
    }

#if !os(visionOS)
    @available(iOS 16.0, *)
    private func contentDetent() -> UISheetPresentationController.Detent {
        return .custom { [weak self] context in
            guard let self = self else {
                return context.maximumDetentValue
            }
            let height = self.lastPreferredSheetHeight > 0 ? self.lastPreferredSheetHeight : self.controlsView.estimatedHeight
            return min(height, context.maximumDetentValue)
        }
    }
#endif

    private func configureSheetPresentation() {
#if !os(visionOS)
        if #available(iOS 15.0, *) {
            modalPresentationStyle = .pageSheet
            if let sheet = sheetPresentationController {
                if #available(iOS 16.0, *) {
                    sheet.detents = [contentDetent(), .large()]
                } else {
                    sheet.detents = [.medium(), .large()]
                }
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 30
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
        } else if #available(iOS 13.0, *) {
            modalPresentationStyle = .pageSheet
        } else {
            modalPresentationStyle = .formSheet
        }
#else
        modalPresentationStyle = .pageSheet
#endif
    }

    @objc private func installBackgroundEffect() {
        backgroundContainer.subviews.forEach { $0.removeFromSuperview() }
        let effectView = UIView.makeOverlayBackgroundView()
        effectView.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainer.addSubview(effectView)
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            effectView.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor),
        ])
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}

// MARK: - PlaybackSpeedControlsViewDelegate

extension PlaybackSpeedViewController: PlaybackSpeedControlsViewDelegate {
    func playbackSpeedControlsViewDidChangeSpeed(_ controlsView: PlaybackSpeedControlsView) {
        delegate?.playbackSpeedViewControllerDidChangeSpeed(self)
    }

    func playbackSpeedControlsViewDidRequestDismissal(_ controlsView: PlaybackSpeedControlsView) {
        close()
    }
}
