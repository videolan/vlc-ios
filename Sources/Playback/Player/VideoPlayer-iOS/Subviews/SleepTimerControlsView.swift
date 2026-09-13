/*****************************************************************************
 * SleepTimerControlsView.swift
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

protocol SleepTimerControlsViewDelegate: AnyObject {
    func sleepTimerControlsViewDidRequestDismissal(_ controlsView: SleepTimerControlsView)
}

final class SleepTimerControlsView: UIView {
    private enum Metrics {
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 10
        static let valuePointSize: CGFloat = 28
        static let valueSpacing: CGFloat = 2
        static let presetHorizontalInset: CGFloat = 4
        static let presetSpacing: CGFloat = 6
        static let stopAfterSpacing: CGFloat = 8
    }

    weak var delegate: SleepTimerControlsViewDelegate?

    private let isAudioPlayer: Bool
    private let playbackService = PlaybackService.sharedInstance()
    private var activePresetIndex: Int?
    private var isStopAfterActive: Bool?
    private var refreshTimer: Timer?

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
        label.text = NSLocalizedString("BUTTON_SLEEP_TIMER", comment: "")
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

    private let valueLabel: UILabel = {
        let label = UILabel()
        let font = UIFont.monospacedDigitSystemFont(ofSize: Metrics.valuePointSize, weight: .semibold)
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center
        label.accessibilityLabel = NSLocalizedString("BUTTON_SLEEP_TIMER", comment: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var presetButtons: [UIButton] = Self.presetMinutes.enumerated().map { index, minutes in
        let button = UIButton(type: .custom)
        button.tag = index
        button.accessibilityLabel = Self.spokenFormatter.string(from: TimeInterval(minutes * 60))
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

    private lazy var stopAfterButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(didTapStopAfter), for: .touchUpInside)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    init(isAudioPlayer: Bool) {
        self.isAudioPlayer = isAudioPlayer
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        overrideUserInterfaceStyle = .dark

        setupLayout()
        updatePresetAxis()
        updateInterface()
        updatePresetButtons(force: true)

        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(requestDismissal))
        swipeDownRecognizer.direction = .down
        addGestureRecognizer(swipeDownRecognizer)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(sleepTimerChanged),
                                       name: Notification.Name(VLCPlaybackServiceSleepTimerDidChange),
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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        refreshTimer?.invalidate()
        refreshTimer = nil
        guard window != nil else {
            return
        }

        refreshTimer = Timer.scheduledTimer(timeInterval: 1,
                                            target: self,
                                            selector: #selector(refreshTimerFired),
                                            userInfo: nil,
                                            repeats: true)
        updateInterface()
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

    static func remainingTimeString(for interval: TimeInterval) -> String {
        let formatter = interval >= 3600 ? hourPositionalFormatter : minutePositionalFormatter
        return formatter.string(from: interval.rounded(.up)) ?? ""
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
        contentView.addSubview(valueLabel)
        contentView.addSubview(presetStackView)
        contentView.addSubview(stopAfterButton)

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

            valueLabel.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: Metrics.valueSpacing),
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),

            presetStackView.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: Metrics.presetSpacing),
            presetStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            presetStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            stopAfterButton.topAnchor.constraint(equalTo: presetStackView.bottomAnchor, constant: Metrics.stopAfterSpacing),
            stopAfterButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            stopAfterButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            stopAfterButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
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

    private var remainingSleepTime: TimeInterval? {
        guard let fireDate = playbackService.sleepTimer?.fireDate else {
            return nil
        }
        return max(fireDate.timeIntervalSinceNow, 0)
    }

    private var remainingItemTime: TimeInterval? {
        let rate = Double(playbackService.playbackRate)
        guard rate > 0, let milliseconds = playbackService.remainingTime().value?.doubleValue, milliseconds < 0 else {
            return nil
        }
        return -milliseconds / 1000 / rate
    }

    private var stopAfterTitle: String {
        if isAudioPlayer {
            return NSLocalizedString("SLEEP_TIMER_STOP_AFTER_THIS_TRACK", comment: "")
        }
        return NSLocalizedString("SLEEP_TIMER_STOP_AFTER_THIS_VIDEO", comment: "")
    }

    private func updateInterface() {
        let colors = PresentationTheme.currentExcludingWhite.colors
        let stopsAfterCurrentItem = playbackService.stopAfterCurrentItem
        if let remainingTime = remainingSleepTime ?? (stopsAfterCurrentItem ? remainingItemTime : nil) {
            valueLabel.text = Self.remainingTimeString(for: remainingTime)
            valueLabel.accessibilityValue = Self.spokenFormatter.string(from: remainingTime.rounded(.up))
            valueLabel.textColor = colors.orangeUI
        } else if stopsAfterCurrentItem {
            valueLabel.text = "–"
            valueLabel.accessibilityValue = stopAfterTitle
            valueLabel.textColor = colors.orangeUI
        } else {
            valueLabel.text = NSLocalizedString("OFF", comment: "")
            valueLabel.accessibilityValue = valueLabel.text
            valueLabel.textColor = colors.overlayPrimaryTextColor
        }
        resetButton.isEnabled = playbackService.sleepTimer != nil || stopsAfterCurrentItem
        updatePresetButtons(force: false)
        updateStopAfterButton(force: false)
    }

    private func updateStopAfterButton(force: Bool) {
        let isActive = playbackService.stopAfterCurrentItem
        guard force || isActive != isStopAfterActive else {
            return
        }

        isStopAfterActive = isActive
        stopAfterButton.applyOverlayControlStyle(title: stopAfterTitle,
                                                 image: nil,
                                                 isActive: isActive,
                                                 cornerRadius: Self.minimumControlHeight / 2)
    }

    private func updatePresetButtons(force: Bool) {
        var presetIndex: Int?
        if playbackService.sleepTimer != nil {
            presetIndex = Self.presetMinutes.firstIndex { TimeInterval($0 * 60) == playbackService.sleepTimerInterval }
        }
        guard force || presetIndex != activePresetIndex else {
            return
        }

        activePresetIndex = presetIndex
        for (index, button) in presetButtons.enumerated() {
            button.applyOverlayControlStyle(title: Self.presetFormatter.string(from: TimeInterval(Self.presetMinutes[index] * 60)),
                                            image: nil,
                                            isActive: index == presetIndex,
                                            cornerRadius: Self.minimumControlHeight / 2)
            button.configuration?.contentInsets.leading = Metrics.presetHorizontalInset
            button.configuration?.contentInsets.trailing = Metrics.presetHorizontalInset
        }
    }

    // MARK: - Actions

    @objc private func requestDismissal() {
        delegate?.sleepTimerControlsViewDidRequestDismissal(self)
    }

    @objc private func didTapReset() {
        playbackService.cancelSleepTimer()
        playbackService.stopAfterCurrentItem = false
        announceState()
    }

    @objc private func didTapPreset(_ sender: UIButton) {
        playbackService.scheduleSleepTimer(withInterval: TimeInterval(Self.presetMinutes[sender.tag] * 60))
        announceState()
    }

    @objc private func didTapStopAfter() {
        playbackService.stopAfterCurrentItem = !playbackService.stopAfterCurrentItem
        announceState()
    }

    private func announceState() {
        guard let title = titleLabel.text, let value = valueLabel.accessibilityValue else {
            return
        }
        UIAccessibility.post(notification: .announcement, argument: title + " " + value)
    }

    @objc private func sleepTimerChanged() {
        updateInterface()
    }

    @objc private func refreshTimerFired() {
        updateInterface()
    }

    @objc private func reduceTransparencyChanged() {
        installBackgroundEffect()
        updateInterface()
        updatePresetButtons(force: true)
        updateStopAfterButton(force: true)
    }

    @objc private func darkerSystemColorsChanged() {
        updateInterface()
        updatePresetButtons(force: true)
        updateStopAfterButton(force: true)
    }

    // MARK: - Helpers

    private static let presetMinutes: [Int] = [10, 15, 30, 45, 60]
    private static let minimumControlHeight: CGFloat = 44
    private static let cardCornerRadius: CGFloat = 30

    private static let presetFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private static let spokenFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter
    }()

    private static let minutePositionalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private static let hourPositionalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
}
