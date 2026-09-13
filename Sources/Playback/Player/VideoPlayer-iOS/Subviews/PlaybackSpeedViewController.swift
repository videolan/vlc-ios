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

    private let playbackService = PlaybackService.sharedInstance()
    private let speedManager = PlaybackSpeedCustomManager.shared
    private let isAudioPlayer: Bool
    private var displayedSpeed: Float = 1
    private var lastPreferredSheetHeight: CGFloat = 0
    private var titleLeadingToContent: NSLayoutConstraint?
    private var titleLeadingToCloseButton: NSLayoutConstraint?
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
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(textStyle: .body)
                .applying(UIImage.SymbolConfiguration(weight: .semibold))
            button.setImage(UIImage(systemName: "arrow.counterclockwise", withConfiguration: configuration), for: .normal)
        } else {
            button.setTitle(NSLocalizedString("BUTTON_RESET", comment: ""), for: .normal)
        }
        button.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        button.accessibilityLabel = NSLocalizedString("BUTTON_RESET", comment: "")
        button.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: 26)
            button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: configuration), for: .normal)
        } else {
            button.setImage(UIImage(named: "close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        button.tintColor = PresentationTheme.currentExcludingWhite.colors.overlaySecondaryTextColor
        button.accessibilityLabel = NSLocalizedString("BUTTON_CLOSE", comment: "")
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
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
        let stepperView = ValueStepperView(buttonSize: Self.stepperButtonSize, valuePointSize: 46)
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

    private lazy var minimumLabel = makeSliderLabel(speed: PlaybackSpeedScale.minimumSpeed)
    private lazy var neutralLabel = makeSliderLabel(speed: 1)
    private lazy var maximumLabel = makeSliderLabel(speed: PlaybackSpeedScale.maximumSpeed)

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

    init(isAudioPlayer: Bool, delegate: PlaybackSpeedViewControllerDelegate?) {
        self.isAudioPlayer = isAudioPlayer
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
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
        setupLayout()
        updatePresetAxis()
        displayedSpeed = PlaybackSpeedScale.rounded(playbackService.playbackRate)
        updateInterface(updatingSlider: true)
        updatePresetButtons(force: true)

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        storeDefaultSpeed()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateCloseButtonVisibility()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSheetDetents()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updatePresetAxis()
            view.setNeedsLayout()
        }
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

    private var preferredSheetHeight: CGFloat {
        let targetSize = CGSize(width: scrollView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let contentHeight = contentView.systemLayoutSizeFitting(targetSize,
                                                                withHorizontalFittingPriority: .required,
                                                                verticalFittingPriority: .fittingSizeLevel).height
        return Self.verticalInset + contentHeight + Self.verticalInset
    }

    private var estimatedSheetHeight: CGFloat {
        let rows = Self.minimumControlHeight * 4 + Self.stepperButtonSize
        let spacing = Self.scopeSpacing + Self.stepperSpacing + Self.sliderSpacing + Self.presetSpacing
        let sliderLabels = UIFont.preferredFont(forTextStyle: .caption1).lineHeight
        return Self.verticalInset * 2 + rows + spacing + sliderLabels
    }

    private func updateSheetDetents() {
#if !os(visionOS)
        guard #available(iOS 16.0, *), scrollView.bounds.width > 0 else {
            return
        }

        let height = preferredSheetHeight
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
            let height = self.lastPreferredSheetHeight > 0 ? self.lastPreferredSheetHeight : self.estimatedSheetHeight
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

    // MARK: - Layout

    private func setupLayout() {
        backgroundContainer.roundCorners(radius: 30)
        backgroundContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(backgroundContainer)
        installBackgroundEffect()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(closeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(resetButton)
        contentView.addSubview(scopeControl)
        contentView.addSubview(stepperView)
        contentView.addSubview(sliderTickView)
        contentView.addSubview(slider)
        contentView.addSubview(minimumLabel)
        contentView.addSubview(neutralLabel)
        contentView.addSubview(maximumLabel)
        contentView.addSubview(presetStackView)

        let guide = view.safeAreaLayoutGuide
        let inset = Self.horizontalInset

        var constraints: [NSLayoutConstraint] = [
            backgroundContainer.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: guide.topAnchor, constant: Self.verticalInset),
            scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -Self.verticalInset),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            resetButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            resetButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset + 8),
            resetButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),
            resetButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),

            closeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset - 8),
            closeButton.centerYAnchor.constraint(equalTo: resetButton.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: Self.minimumControlHeight),
            closeButton.heightAnchor.constraint(equalToConstant: Self.minimumControlHeight),

            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: resetButton.leadingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: resetButton.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),

            scopeControl.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: Self.scopeSpacing),
            scopeControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            scopeControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            scopeControl.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),

            stepperView.topAnchor.constraint(equalTo: scopeControl.bottomAnchor, constant: Self.stepperSpacing),
            stepperView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            stepperView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),

            slider.topAnchor.constraint(equalTo: stepperView.bottomAnchor, constant: Self.sliderSpacing),
            slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            slider.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),

            sliderTickView.centerXAnchor.constraint(equalTo: slider.centerXAnchor),
            sliderTickView.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            sliderTickView.widthAnchor.constraint(equalToConstant: 2),
            sliderTickView.heightAnchor.constraint(equalToConstant: 16),

            minimumLabel.topAnchor.constraint(equalTo: slider.bottomAnchor),
            minimumLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor),
            neutralLabel.topAnchor.constraint(equalTo: slider.bottomAnchor),
            neutralLabel.centerXAnchor.constraint(equalTo: slider.centerXAnchor),
            maximumLabel.topAnchor.constraint(equalTo: slider.bottomAnchor),
            maximumLabel.trailingAnchor.constraint(equalTo: slider.trailingAnchor),

            presetStackView.topAnchor.constraint(equalTo: neutralLabel.bottomAnchor, constant: Self.presetSpacing),
            presetStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            presetStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
        ]

        if #available(iOS 26.0, visionOS 26.0, *) {
            sliderTickView.isHidden = true
        }

        constraints.append(presetStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
        NSLayoutConstraint.activate(constraints)

        titleLeadingToContent = titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset)
        titleLeadingToCloseButton = titleLabel.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 4)
        closeButton.isHidden = true
        titleLeadingToContent?.isActive = true
        updateCloseButtonVisibility()
    }

    private func updateCloseButtonVisibility() {
        let shouldShow: Bool
        if #available(iOS 13.0, *) {
            shouldShow = (traitCollection.verticalSizeClass == .compact)
        } else {
            shouldShow = true
        }

        guard shouldShow == closeButton.isHidden else {
            return
        }

        closeButton.isHidden = !shouldShow
        if shouldShow {
            titleLeadingToContent?.isActive = false
            titleLeadingToCloseButton?.isActive = true
        } else {
            titleLeadingToCloseButton?.isActive = false
            titleLeadingToContent?.isActive = true
        }
    }

    private func makeSliderLabel(speed: Float) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlayTertiaryTextColor
        label.text = String(format: NSLocalizedString("PLAYBACK_SPEED_FORMAT", comment: ""), Self.presetTitle(for: speed))
        label.isAccessibilityElement = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        delegate?.playbackSpeedViewControllerDidChangeSpeed(self)
    }

    private func scheduleDefaultSpeedStore() {
        hasPendingDefaultSpeed = true
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(storeDefaultSpeed), object: nil)
        perform(#selector(storeDefaultSpeed), with: nil, afterDelay: Self.defaultSpeedStoreDelay)
    }

    @objc private func storeDefaultSpeed() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(storeDefaultSpeed), object: nil)
        guard hasPendingDefaultSpeed else {
            return
        }

        hasPendingDefaultSpeed = false
        if speedManager.appliesToAllMedia {
            speedManager.setDefaultSpeed(displayedSpeed)
        }
    }

    // MARK: - Actions

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func didTapReset() {
        apply(speed: resetSpeed)
    }

    @objc private func scopeChanged() {
        speedManager.appliesToAllMedia = scopeControl.selectedSegmentIndex == 1
        if speedManager.appliesToAllMedia {
            speedManager.setDefaultSpeed(displayedSpeed)
        }
        updateInterface(updatingSlider: false)
        delegate?.playbackSpeedViewControllerDidChangeSpeed(self)
    }

    @objc private func sliderValueChanged() {
        apply(speed: PlaybackSpeedScale.speed(forSliderValue: slider.value))
    }

    @objc private func didTapPreset(_ sender: UIButton) {
        apply(speed: Self.presetSpeeds[sender.tag])
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
    private static let horizontalInset: CGFloat = 16
    private static let verticalInset: CGFloat = 16
    private static let stepperButtonSize: CGFloat = 52
    private static let minimumControlHeight: CGFloat = 44
    private static let scopeSpacing: CGFloat = 8
    private static let stepperSpacing: CGFloat = 18
    private static let sliderSpacing: CGFloat = 16
    private static let presetSpacing: CGFloat = 18
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

extension PlaybackSpeedViewController: ValueStepperViewDelegate {
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
