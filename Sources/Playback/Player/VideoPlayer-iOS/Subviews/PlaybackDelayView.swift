/*****************************************************************************
 * PlaybackDelayView.swift
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

protocol PlaybackDelayViewDelegate: AnyObject {
    func playbackDelayViewDidChangeDelay(_ delayView: PlaybackDelayView)
    func playbackDelayViewDidRequestDismissal(_ delayView: PlaybackDelayView)
}

final class PlaybackDelayView: UIView {
    enum Kind {
        case audio
        case subtitle
    }

    let kind: Kind
    weak var delegate: PlaybackDelayViewDelegate?

    private let playbackService = PlaybackService.sharedInstance()
    private var heardMarkTime: CFTimeInterval?
    private var seenMarkTime: CFTimeInterval?

    // MARK: - Views

    private let backgroundContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlayPrimaryTextColor
        label.accessibilityTraits = .header
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(textStyle: .body)
            .applying(UIImage.SymbolConfiguration(weight: .semibold))
        button.setImage(UIImage(systemName: "arrow.counterclockwise", withConfiguration: configuration), for: .normal)
        button.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        button.accessibilityLabel = NSLocalizedString("BUTTON_RESET", comment: "")
        button.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var stepperView: ValueStepperView = {
        let stepperView = ValueStepperView(buttonSize: Self.controlHeight, valuePointSize: 28)
        stepperView.delegate = self
        return stepperView
    }()

    private let heardMarkButton = UIButton(type: .custom)
    private let seenMarkButton = UIButton(type: .custom)

    private lazy var markStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [heardMarkButton, seenMarkButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Lifecycle

    init(kind: Kind) {
        self.kind = kind
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        overrideUserInterfaceStyle = .dark

        switch kind {
        case .audio:
            titleLabel.text = NSLocalizedString("AUDIO_DELAY", comment: "")
        case .subtitle:
            titleLabel.text = NSLocalizedString("SPU_DELAY", comment: "")
        }
        stepperView.accessibilityLabel = titleLabel.text

        for button in [heardMarkButton, seenMarkButton] {
            button.addTarget(self, action: #selector(didTapMark(_:)), for: .touchUpInside)
            button.accessibilityHint = NSLocalizedString("SYNC_MARK_HINT", comment: "")
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.controlHeight).isActive = true
        }

        setupLayout()
        updateMarkAxis()
        refresh()

        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(requestDismissal))
        swipeDownRecognizer.direction = .down
        addGestureRecognizer(swipeDownRecognizer)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(reduceTransparencyChanged),
                                       name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(accessibilityDisplayOptionsChanged),
                                       name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(accessibilityDisplayOptionsChanged),
                                       name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(requestDismissal),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidMoveOnToNextItem),
                                       object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateMarkAxis()
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        requestDismissal()
        return true
    }

    func refresh() {
        let delay = currentDelay
        stepperView.update(valueText: PlaybackDelayFormatter.string(forDelay: delay), isModified: delay != 0)
        resetButton.isEnabled = delay != 0
        updateMarks()
    }

    func focusForAccessibility() {
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    func nudgeDelay(increasing: Bool) {
        setDelay(steppedDelay(from: currentDelay, increasing: increasing))
    }

    // MARK: - Layout

    private func setupLayout() {
        backgroundContainer.roundCorners(radius: Self.cornerRadius)
        addSubview(backgroundContainer)
        installBackgroundEffect()

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(resetButton)
        contentView.addSubview(stepperView)
        contentView.addSubview(markStackView)

        let padding = Self.padding
        let scrollViewHeight = scrollView.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        scrollViewHeight.priority = .defaultHigh

        let constraints: [NSLayoutConstraint] = [
            backgroundContainer.topAnchor.constraint(equalTo: topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            scrollViewHeight,

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            resetButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            resetButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            resetButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.controlHeight),
            resetButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.controlHeight),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: resetButton.leadingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: resetButton.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),

            stepperView.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 6),
            stepperView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stepperView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            markStackView.topAnchor.constraint(equalTo: stepperView.bottomAnchor, constant: 10),
            markStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            markStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            markStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func installBackgroundEffect() {
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

    private func updateMarkAxis() {
        markStackView.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
    }

    // MARK: - Delay

    private var currentDelay: Float {
        switch kind {
        case .audio:
            return playbackService.audioDelay
        case .subtitle:
            return playbackService.subtitleDelay
        }
    }

    private func setDelay(_ delay: Float) {
        let clampedDelay = min(max(delay.rounded(), -Self.maximumDelay), Self.maximumDelay)
        switch kind {
        case .audio:
            playbackService.audioDelay = clampedDelay
        case .subtitle:
            playbackService.subtitleDelay = clampedDelay
        }
        refresh()
        delegate?.playbackDelayViewDidChangeDelay(self)
    }

    private func steppedDelay(from delay: Float, increasing: Bool) -> Float {
        let steps = Double(delay.rounded()) / Double(Self.delayStep)
        if increasing {
            return Float(steps.rounded(.down) + 1) * Self.delayStep
        }
        return Float(steps.rounded(.up) - 1) * Self.delayStep
    }

    // MARK: - Sync marks

    private var heardMarkTitle: String {
        switch kind {
        case .audio:
            return NSLocalizedString("SYNC_SOUND_HEARD", comment: "")
        case .subtitle:
            return NSLocalizedString("SYNC_VOICE_HEARD", comment: "")
        }
    }

    private var seenMarkTitle: String {
        switch kind {
        case .audio:
            return NSLocalizedString("SYNC_SCENE_SEEN", comment: "")
        case .subtitle:
            return NSLocalizedString("SYNC_TEXT_SEEN", comment: "")
        }
    }

    private func updateMarks() {
        let isHeardMarked = heardMarkTime != nil
        let isSeenMarked = seenMarkTime != nil
        style(markButton: heardMarkButton, title: heardMarkTitle, isMarked: isHeardMarked, isPending: isSeenMarked && !isHeardMarked)
        style(markButton: seenMarkButton, title: seenMarkTitle, isMarked: isSeenMarked, isPending: isHeardMarked && !isSeenMarked)
    }

    private func style(markButton button: UIButton, title: String, isMarked: Bool, isPending: Bool) {
        let colors = PresentationTheme.currentExcludingWhite.colors
        let image = UIImage(systemName: isMarked ? "checkmark.circle.fill" : "circle")
        button.applyOverlayControlStyle(title: title, image: image, isActive: isMarked, cornerRadius: Self.controlHeight / 2)

        button.layer.removeAnimation(forKey: Self.pendingAnimationKey)
        button.layer.borderWidth = 0
        guard isPending else {
            return
        }

        button.layer.cornerRadius = Self.controlHeight / 2
        button.layer.borderWidth = 2
        button.layer.borderColor = colors.orangeUI.cgColor
        guard !UIAccessibility.isReduceMotionEnabled else {
            return
        }

        let animation = CABasicAnimation(keyPath: "borderColor")
        animation.fromValue = colors.orangeUI.withAlphaComponent(0.25).cgColor
        animation.toValue = colors.orangeUI.cgColor
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        button.layer.add(animation, forKey: Self.pendingAnimationKey)
    }

    private func completeSyncIfPossible() {
        guard let heardMarkTime = heardMarkTime, let seenMarkTime = seenMarkTime else {
            updateMarks()
            return
        }

        self.heardMarkTime = nil
        self.seenMarkTime = nil

        let offset: CFTimeInterval
        switch kind {
        case .audio:
            offset = seenMarkTime - heardMarkTime
        case .subtitle:
            offset = heardMarkTime - seenMarkTime
        }
        let offsetInMilliseconds = Float(offset * 1000) * playbackService.playbackRate
        setDelay(currentDelay + offsetInMilliseconds)
        stepperView.pulseValue()

        if let title = titleLabel.text {
            let announcement = title + " " + PlaybackDelayFormatter.string(forDelay: currentDelay)
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    // MARK: - Actions

    @objc private func didTapReset() {
        heardMarkTime = nil
        seenMarkTime = nil
        setDelay(0)
    }

    @objc private func didTapMark(_ sender: UIButton) {
        let now = CACurrentMediaTime()
        if sender == heardMarkButton {
            heardMarkTime = heardMarkTime == nil ? now : nil
        } else {
            seenMarkTime = seenMarkTime == nil ? now : nil
        }
        completeSyncIfPossible()
    }

    @objc private func requestDismissal() {
        delegate?.playbackDelayViewDidRequestDismissal(self)
    }

    @objc private func reduceTransparencyChanged() {
        installBackgroundEffect()
        refresh()
    }

    @objc private func accessibilityDisplayOptionsChanged() {
        refresh()
    }

    // MARK: - Helpers

    private static let padding: CGFloat = 14
    private static let cornerRadius: CGFloat = 30
    private static let controlHeight: CGFloat = 44
    private static let delayStep: Float = 50
    private static let maximumDelay: Float = 30000
    private static let pendingAnimationKey = "pendingMark"
}

// MARK: - ValueStepperViewDelegate

extension PlaybackDelayView: ValueStepperViewDelegate {
    func valueStepperViewDidDecrement(_ stepperView: ValueStepperView) {
        nudgeDelay(increasing: false)
    }

    func valueStepperViewDidIncrement(_ stepperView: ValueStepperView) {
        nudgeDelay(increasing: true)
    }

    func valueStepperViewDidTapValue(_ stepperView: ValueStepperView) {
        didTapReset()
    }
}
