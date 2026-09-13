/*****************************************************************************
 * PlaybackSpeedControlsView.swift
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

protocol PlaybackSpeedControlsViewDelegate: AnyObject {
    func playbackSpeedControlsViewDidChangeSpeed(_ controlsView: PlaybackSpeedControlsView)
    func playbackSpeedControlsViewDidRequestDismissal(_ controlsView: PlaybackSpeedControlsView)
}

final class PlaybackSpeedControlsView: UIView {
    private enum Metrics {
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 10
        static let stepperButtonSize: CGFloat = 44
        static let valuePointSize: CGFloat = 28
        static let scopeSpacing: CGFloat = 2
        static let stepperSpacing: CGFloat = 8
        static let sliderSpacing: CGFloat = 2
        static let presetSpacing: CGFloat = 6
    }

    weak var delegate: PlaybackSpeedControlsViewDelegate?

    private let isAudioPlayer: Bool
    private let playbackService = PlaybackService.sharedInstance()
    private let speedManager = PlaybackSpeedCustomManager.shared
    private var displayedSpeed: Float = 1
    private var activePresetIndex: Int?
    private var hasPendingDefaultSpeed = false

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
        label.text = NSLocalizedString("PLAYBACK_SPEED", comment: "")
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

    private lazy var scopeControl: UISegmentedControl = {
        let items: [String]
        if isAudioPlayer {
            items = [NSLocalizedString("PLAYBACK_SPEED_THIS_TRACK", comment: ""),
                     NSLocalizedString("PLAYBACK_SPEED_ALL_TRACKS", comment: "")]
        } else {
            items = [NSLocalizedString("PLAYBACK_SPEED_THIS_VIDEO", comment: ""),
                     NSLocalizedString("PLAYBACK_SPEED_ALL_VIDEOS", comment: "")]
        }
        let control = UISegmentedControl(items: items)
        let font = UIFont.preferredFont(forTextStyle: .headline)
        control.setTitleTextAttributes([.font: font], for: .normal)
        control.setTitleTextAttributes([.font: font], for: .selected)
        control.selectedSegmentIndex = speedManager.appliesToAllMedia ? 1 : 0
        control.addTarget(self, action: #selector(scopeChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var stepperView: ValueStepperView = {
        let stepperView = ValueStepperView(buttonSize: Metrics.stepperButtonSize, valuePointSize: Metrics.valuePointSize)
        stepperView.accessibilityLabel = NSLocalizedString("PLAYBACK_SPEED", comment: "")
        stepperView.delegate = self
        return stepperView
    }()

    private lazy var slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.minimumTrackTintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        slider.accessibilityLabel = NSLocalizedString("PLAYBACK_SPEED", comment: "")
        if #available(iOS 26.0, visionOS 26.0, *) {
            let neutralValue = PlaybackSpeedScale.sliderNeutralValue
            slider.trackConfiguration = UISlider.TrackConfiguration(allowsTickValuesOnly: false,
                                                                    neutralValue: neutralValue,
                                                                    ticks: [.init(position: neutralValue)])
        }
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private let sliderTickView: UIView = {
        let view = UIView()
        view.backgroundColor = PresentationTheme.currentExcludingWhite.colors.overlayTertiaryTextColor
        view.layer.cornerRadius = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var presetButtons: [UIButton] = Self.presetSpeeds.enumerated().map { index, _ in
        let button = UIButton(type: .custom)
        button.tag = index
        button.addTarget(self, action: #selector(didTapPreset(_:)), for: .touchUpInside)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight).isActive = true
        return button
    }

    private lazy var presetStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: presetButtons)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Lifecycle

    init(isAudioPlayer: Bool) {
        self.isAudioPlayer = isAudioPlayer
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        overrideUserInterfaceStyle = .dark

        setupLayout()
        updatePresetAxis()
        displayedSpeed = PlaybackSpeedScale.rounded(playbackService.playbackRate)
        updateInterface(updatingSlider: true)
        updatePresetButtons(force: true)

        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(requestDismissal))
        swipeDownRecognizer.direction = .down
        addGestureRecognizer(swipeDownRecognizer)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(playbackRateChanged),
                                       name: Notification.Name(VLCPlaybackServicePlaybackRateDidChange),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(reduceTransparencyChanged),
                                       name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(darkerSystemColorsChanged),
                                       name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
                                       object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updatePresetAxis()
            superview?.setNeedsLayout()
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        requestDismissal()
        return true
    }

    // MARK: - Public

    func focusForAccessibility() {
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    @objc func storeDefaultSpeed() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(storeDefaultSpeed), object: nil)
        guard hasPendingDefaultSpeed else {
            return
        }

        hasPendingDefaultSpeed = false
        if speedManager.appliesToAllMedia {
            speedManager.setDefaultSpeed(displayedSpeed)
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        backgroundContainer.roundCorners(radius: Self.cardCornerRadius)
        addSubview(backgroundContainer)
        installBackgroundEffect()

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(resetButton)
        contentView.addSubview(scopeControl)
        contentView.addSubview(stepperView)
        contentView.addSubview(sliderTickView)
        contentView.addSubview(slider)
        contentView.addSubview(presetStackView)

        let inset = Metrics.horizontalPadding
        let scrollViewHeight = scrollView.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        scrollViewHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.verticalPadding),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Metrics.verticalPadding),
            scrollViewHeight,

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            resetButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            resetButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset + 8),
            resetButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),
            resetButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: resetButton.leadingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: resetButton.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),

            scopeControl.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: Metrics.scopeSpacing),
            scopeControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            scopeControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            scopeControl.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),

            stepperView.topAnchor.constraint(equalTo: scopeControl.bottomAnchor, constant: Metrics.stepperSpacing),
            stepperView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            stepperView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            slider.topAnchor.constraint(equalTo: stepperView.bottomAnchor, constant: Metrics.sliderSpacing),
            slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            slider.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),

            sliderTickView.centerXAnchor.constraint(equalTo: slider.centerXAnchor),
            sliderTickView.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            sliderTickView.widthAnchor.constraint(equalToConstant: 2),
            sliderTickView.heightAnchor.constraint(equalToConstant: 16),

            presetStackView.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: Metrics.presetSpacing),
            presetStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            presetStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            presetStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        if #available(iOS 26.0, visionOS 26.0, *) {
            sliderTickView.isHidden = true
        }
    }

    private func updatePresetAxis() {
        presetStackView.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
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

    // MARK: - State

    private var resetSpeed: Float {
        return PlaybackSpeedScale.rounded(speedManager.resetSpeed)
    }

    private func updateInterface(updatingSlider: Bool) {
        let speedText = PlaybackSpeedFormatter.string(forSpeed: displayedSpeed)
        let isModified = abs(displayedSpeed - resetSpeed) > 0.001

        stepperView.update(valueText: speedText, isModified: isModified)
        resetButton.isEnabled = isModified

        if updatingSlider && !slider.isTracking {
            slider.value = PlaybackSpeedScale.sliderValue(forSpeed: displayedSpeed)
        }
        slider.accessibilityValue = speedText
        updatePresetButtons(force: false)
    }

    private func updatePresetButtons(force: Bool) {
        let presetIndex = Self.presetSpeeds.firstIndex { abs($0 - displayedSpeed) < 0.001 }
        guard force || presetIndex != activePresetIndex else {
            return
        }

        activePresetIndex = presetIndex
        for (index, button) in presetButtons.enumerated() {
            button.applyOverlayControlStyle(title: Self.presetTitle(for: Self.presetSpeeds[index]),
                                            image: nil,
                                            isActive: index == presetIndex,
                                            cornerRadius: Self.minimumControlHeight / 2)
        }
    }

    private func apply(speed: Float) {
        displayedSpeed = PlaybackSpeedScale.rounded(speed)
        playbackService.playbackRate = displayedSpeed
        if speedManager.appliesToAllMedia {
            scheduleDefaultSpeedStore()
        }
        updateInterface(updatingSlider: true)
        delegate?.playbackSpeedControlsViewDidChangeSpeed(self)
    }

    private func scheduleDefaultSpeedStore() {
        hasPendingDefaultSpeed = true
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(storeDefaultSpeed), object: nil)
        perform(#selector(storeDefaultSpeed), with: nil, afterDelay: Self.defaultSpeedStoreDelay)
    }

    // MARK: - Actions

    @objc private func requestDismissal() {
        delegate?.playbackSpeedControlsViewDidRequestDismissal(self)
    }

    @objc private func didTapReset() {
        apply(speed: resetSpeed)
        announceSpeed()
    }

    @objc private func scopeChanged() {
        storeDefaultSpeed()
        speedManager.appliesToAllMedia = scopeControl.selectedSegmentIndex == 1
        if speedManager.appliesToAllMedia {
            displayedSpeed = PlaybackSpeedScale.rounded(speedManager.defaultSpeed)
            playbackService.playbackRate = displayedSpeed
        }
        updateInterface(updatingSlider: true)
        delegate?.playbackSpeedControlsViewDidChangeSpeed(self)
    }

    @objc private func sliderValueChanged() {
        apply(speed: PlaybackSpeedScale.speed(forSliderValue: slider.value))
    }

    @objc private func didTapPreset(_ sender: UIButton) {
        apply(speed: Self.presetSpeeds[sender.tag])
        announceSpeed()
    }

    private func announceSpeed() {
        let announcement = NSLocalizedString("PLAYBACK_SPEED", comment: "") + " " + PlaybackSpeedFormatter.string(forSpeed: displayedSpeed)
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    @objc private func playbackRateChanged() {
        let speed = PlaybackSpeedScale.rounded(playbackService.playbackRate)
        guard abs(speed - displayedSpeed) > 0.001, !slider.isTracking else {
            return
        }
        displayedSpeed = speed
        updateInterface(updatingSlider: true)
    }

    @objc private func reduceTransparencyChanged() {
        installBackgroundEffect()
        updateInterface(updatingSlider: false)
        updatePresetButtons(force: true)
    }

    @objc private func darkerSystemColorsChanged() {
        updateInterface(updatingSlider: false)
        updatePresetButtons(force: true)
    }

    // MARK: - Helpers

    private static let presetSpeeds: [Float] = [0.8, 1, 1.25, 1.5, 2]
    private static let minimumControlHeight: CGFloat = 44
    private static let cardCornerRadius: CGFloat = 30
    private static let defaultSpeedStoreDelay: TimeInterval = 0.3

    private static let presetFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static func presetTitle(for speed: Float) -> String {
        return presetFormatter.string(from: NSNumber(value: speed)) ?? String(speed)
    }
}

// MARK: - ValueStepperViewDelegate

extension PlaybackSpeedControlsView: ValueStepperViewDelegate {
    func valueStepperViewDidDecrement(_ stepperView: ValueStepperView) {
        apply(speed: PlaybackSpeedScale.steppedSpeed(from: displayedSpeed, increasing: false))
    }

    func valueStepperViewDidIncrement(_ stepperView: ValueStepperView) {
        apply(speed: PlaybackSpeedScale.steppedSpeed(from: displayedSpeed, increasing: true))
    }

    func valueStepperViewDidTapValue(_ stepperView: ValueStepperView) {
        apply(speed: resetSpeed)
    }
}
