/*****************************************************************************
 * VideoFiltersControlsView.swift
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

protocol VideoFiltersControlsViewDelegate: AnyObject {
    func videoFiltersControlsViewDidChangeFilters(_ controlsView: VideoFiltersControlsView)
    func videoFiltersControlsViewDidRequestDismissal(_ controlsView: VideoFiltersControlsView)
}

final class VideoFiltersControlsView: UIView {
    private enum Metrics {
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 10
        static let rowSpacing: CGFloat = 2
        static let labelSpacing: CGFloat = 12
        static let stackedLabelSpacing: CGFloat = 2
        static let maximumLabelColumnFraction: CGFloat = 0.4
    }

    private enum Filter: CaseIterable {
        case brightness
        case contrast
        case hue
        case saturation
        case gamma

        var title: String {
            switch self {
            case .brightness:
                return NSLocalizedString("VFILTER_BRIGHTNESS", comment: "")
            case .contrast:
                return NSLocalizedString("VFILTER_CONTRAST", comment: "")
            case .hue:
                return NSLocalizedString("VFILTER_HUE", comment: "")
            case .saturation:
                return NSLocalizedString("VFILTER_SATURATION", comment: "")
            case .gamma:
                return NSLocalizedString("VFILTER_GAMMA", comment: "")
            }
        }

        func parameter(of adjustFilter: PlaybackServiceAdjustFilter) -> PlaybackServiceAdjustFilter.Parameter {
            switch self {
            case .brightness:
                return adjustFilter.brightness
            case .contrast:
                return adjustFilter.contrast
            case .hue:
                return adjustFilter.hue
            case .saturation:
                return adjustFilter.saturation
            case .gamma:
                return adjustFilter.gamma
            }
        }
    }

    weak var delegate: VideoFiltersControlsViewDelegate?

    private let playbackService = PlaybackService.sharedInstance()
    private let labelColumnGuide = UILayoutGuide()
    private var horizontalRowConstraints: [NSLayoutConstraint] = []
    private var stackedRowConstraints: [NSLayoutConstraint] = []

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
        label.text = NSLocalizedString("VIDEO_FILTER", comment: "")
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
        button.accessibilityLabel = NSLocalizedString("VIDEO_FILTER_RESET_BUTTON", comment: "")
        button.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var labels: [UILabel] = Filter.allCases.map { filter in
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = filter.title
        label.isAccessibilityElement = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private lazy var sliders: [UISlider] = Filter.allCases.enumerated().map { index, filter in
        let slider = UISlider()
        slider.tag = index
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.minimumTrackTintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        slider.accessibilityLabel = filter.title
        if #available(iOS 26.0, visionOS 26.0, *) {
            slider.trackConfiguration = UISlider.TrackConfiguration(allowsTickValuesOnly: false,
                                                                    neutralValue: Self.neutralSliderValue,
                                                                    ticks: [.init(position: Self.neutralSliderValue)])
        }
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }

    private lazy var tickViews: [UIView] = Filter.allCases.map { _ in
        let view = UIView()
        view.backgroundColor = PresentationTheme.currentExcludingWhite.colors.overlayTertiaryTextColor
        view.layer.cornerRadius = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 26.0, visionOS 26.0, *) {
            view.isHidden = true
        }
        return view
    }

    // MARK: - Lifecycle

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        overrideUserInterfaceStyle = .dark

        setupLayout()
        updateRowAxis()
        updateInterface(updatingSliders: true)

        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(requestDismissal))
        swipeDownRecognizer.direction = .down
        addGestureRecognizer(swipeDownRecognizer)

        let notificationCenter = NotificationCenter.default
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
            updateRowAxis()
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

    // MARK: - Layout

    private func setupLayout() {
        backgroundContainer.roundCorners(radius: Self.cardCornerRadius)
        addSubview(backgroundContainer)
        installBackgroundEffect()

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(resetButton)
        contentView.addLayoutGuide(labelColumnGuide)

        let inset = Metrics.horizontalPadding
        let scrollViewHeight = scrollView.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        scrollViewHeight.priority = .defaultHigh
        let collapsedLabelColumn = labelColumnGuide.widthAnchor.constraint(equalToConstant: 0)
        collapsedLabelColumn.priority = .defaultLow

        var constraints: [NSLayoutConstraint] = [
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

            labelColumnGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            labelColumnGuide.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor,
                                                    multiplier: Metrics.maximumLabelColumnFraction),
            collapsedLabelColumn,
        ]

        var previousBottomAnchor = resetButton.bottomAnchor
        for (index, label) in labels.enumerated() {
            let slider = sliders[index]
            let tickView = tickViews[index]
            contentView.addSubview(label)
            contentView.addSubview(tickView)
            contentView.addSubview(slider)

            constraints += [
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
                slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
                slider.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),

                tickView.centerXAnchor.constraint(equalTo: slider.centerXAnchor),
                tickView.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
                tickView.widthAnchor.constraint(equalToConstant: 2),
                tickView.heightAnchor.constraint(equalToConstant: 16),
            ]

            horizontalRowConstraints += [
                slider.topAnchor.constraint(equalTo: previousBottomAnchor, constant: Metrics.rowSpacing),
                slider.leadingAnchor.constraint(equalTo: labelColumnGuide.trailingAnchor, constant: Metrics.labelSpacing),
                label.trailingAnchor.constraint(lessThanOrEqualTo: labelColumnGuide.trailingAnchor),
                label.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            ]

            stackedRowConstraints += [
                label.topAnchor.constraint(equalTo: previousBottomAnchor, constant: Metrics.rowSpacing),
                label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -inset),
                slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: Metrics.stackedLabelSpacing),
                slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            ]

            previousBottomAnchor = slider.bottomAnchor
        }
        constraints.append(contentView.bottomAnchor.constraint(equalTo: previousBottomAnchor))

        NSLayoutConstraint.activate(constraints)
    }

    private func updateRowAxis() {
        let isStacked = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        NSLayoutConstraint.deactivate(isStacked ? horizontalRowConstraints : stackedRowConstraints)
        NSLayoutConstraint.activate(isStacked ? stackedRowConstraints : horizontalRowConstraints)
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

    private func updateInterface(updatingSliders: Bool) {
        let colors = PresentationTheme.currentExcludingWhite.colors
        let adjustFilter = playbackService.adjustFilter
        var isModified = false
        for (index, filter) in Filter.allCases.enumerated() {
            let parameter = filter.parameter(of: adjustFilter)
            let value = parameter.value
            let isParameterModified = abs(value - parameter.defaultValue) > 0.001
            isModified = isModified || isParameterModified

            labels[index].textColor = isParameterModified ? colors.orangeUI : colors.overlayPrimaryTextColor
            let slider = sliders[index]
            if updatingSliders && !slider.isTracking {
                slider.value = Self.sliderValue(for: value, of: parameter)
            }
            slider.accessibilityValue = Self.valueFormatter.string(from: NSNumber(value: value))
        }
        resetButton.isEnabled = isModified || adjustFilter.isEnabled
    }

    // MARK: - Actions

    @objc private func requestDismissal() {
        delegate?.videoFiltersControlsViewDidRequestDismissal(self)
    }

    @objc private func didTapReset() {
        playbackService.adjustFilter.reset()
        updateInterface(updatingSliders: true)
        delegate?.videoFiltersControlsViewDidChangeFilters(self)
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        if abs(sender.value - Self.neutralSliderValue) < Self.neutralSnapDistance {
            sender.value = Self.neutralSliderValue
        }

        let parameter = Filter.allCases[sender.tag].parameter(of: playbackService.adjustFilter)
        parameter.value = Self.value(forSliderValue: sender.value, of: parameter)
        updateInterface(updatingSliders: false)
        delegate?.videoFiltersControlsViewDidChangeFilters(self)
    }

    @objc private func reduceTransparencyChanged() {
        installBackgroundEffect()
        updateInterface(updatingSliders: false)
    }

    @objc private func darkerSystemColorsChanged() {
        updateInterface(updatingSliders: false)
    }

    // MARK: - Helpers

    private static let minimumControlHeight: CGFloat = 44
    private static let cardCornerRadius: CGFloat = 30
    private static let neutralSliderValue: Float = 0.5
    private static let neutralSnapDistance: Float = 0.02

    private static let valueFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static func sliderValue(for value: Float, of parameter: PlaybackServiceAdjustFilter.Parameter) -> Float {
        let defaultValue = parameter.defaultValue
        if value < defaultValue {
            return neutralSliderValue * (value - parameter.minValue) / (defaultValue - parameter.minValue)
        }
        return neutralSliderValue + (1 - neutralSliderValue) * (value - defaultValue) / (parameter.maxValue - defaultValue)
    }

    private static func value(forSliderValue sliderValue: Float, of parameter: PlaybackServiceAdjustFilter.Parameter) -> Float {
        let defaultValue = parameter.defaultValue
        if sliderValue < neutralSliderValue {
            return parameter.minValue + (defaultValue - parameter.minValue) * sliderValue / neutralSliderValue
        }
        return defaultValue + (parameter.maxValue - defaultValue) * (sliderValue - neutralSliderValue) / (1 - neutralSliderValue)
    }
}
