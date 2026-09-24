/*****************************************************************************
* EqualizerView.swift
*
* Copyright © 2020 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*                       Diogo Simao Marques <dogo@videolabs.io>
*                       Felix Paul Kühne <fkuehne # videolan.org>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import UIKit

class EqualizerValueFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func string(forDecibels decibels: Float) -> String {
        return formatter.string(from: NSNumber(value: decibels)) ?? String(format: "%.2f", decibels)
    }

    static func stringWithUnit(forDecibels decibels: Float) -> String {
        return string(forDecibels: decibels) + "dB"
    }
}

class EqualizerView: UIView {

    // MARK: - EqualizerFrequency structure
    private struct EqualizerFrequency {
        let stack: UIStackView
        let currentValueLabel: UILabel
        let slider: VerticalSliderControl
        let frequencyLabel: UILabel

        init(frequency: Int, index: Int) {
            stack = UIStackView()
            currentValueLabel = UILabel()
            slider = VerticalSliderControl()
            frequencyLabel = UILabel()

            let name = frequency < 1000 ? "\(frequency)" : "\(frequency/1000)K"
            setupSlider(tag: index, frequency: frequency)
            setupFrequencyLabel(name: name)
            setupCurrentValueLabel()
            setupStack()
        }

        private func setupStack() {
            stack.axis = .vertical
            stack.alignment = .fill
            stack.distribution = .fill
            stack.spacing = EqualizerView.Metrics.bandLabelSpacing
            stack.addArrangedSubview(currentValueLabel)
            stack.addArrangedSubview(slider)
            stack.addArrangedSubview(frequencyLabel)
        }

        private func setupSlider(tag: Int, frequency: Int) {
            let colors = PresentationTheme.currentExcludingWhite.colors
            slider.tag = tag
            slider.range = -20...20
            slider.setValue(0, animated: false)
            slider.thumbImage = UIImage(named: "sliderKnob")
            slider.trackWidth = 4
            slider.minimumTrackLayerColor = colors.orangeUI.cgColor
            slider.maximumTrackLayerColor = colors.overlayHairlineColor.cgColor
            let frequencyMeasurement: Measurement<UnitFrequency> = Measurement(value: Double(frequency), unit: .hertz)
            slider.accessibilityLabel = EqualizerView.frequencyFormatter.string(from: frequencyMeasurement)
            slider.translatesAutoresizingMaskIntoConstraints = false
        }

        private func setupCurrentValueLabel() {
            currentValueLabel.text = EqualizerValueFormatter.string(forDecibels: 0)
            currentValueLabel.font = UIFontMetrics(forTextStyle: .caption2).scaledFont(for: .monospacedDigitSystemFont(ofSize: 11, weight: .bold))
            currentValueLabel.textColor = PresentationTheme.currentExcludingWhite.colors.overlayPrimaryTextColor
            currentValueLabel.setContentHuggingPriority(.required, for: .vertical)
            EqualizerView.setupBandLabel(currentValueLabel)
        }

        private func setupFrequencyLabel(name: String) {
            frequencyLabel.text = name
            frequencyLabel.font = UIFontMetrics(forTextStyle: .caption2).scaledFont(for: .systemFont(ofSize: 11))
            frequencyLabel.textColor = PresentationTheme.currentExcludingWhite.colors.overlaySecondaryTextColor
            frequencyLabel.setContentHuggingPriority(.required, for: .vertical)
            EqualizerView.setupBandLabel(frequencyLabel)
        }
    }

    fileprivate enum Metrics {
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 10
        static let rowSpacing: CGFloat = 8
        static let labelSpacing: CGFloat = 12
        static let axisSpacing: CGFloat = 4
        static let bandLabelSpacing: CGFloat = 4
        static let minimumBandWidthWithAxis: CGFloat = 36
        static let bandSliderHeight: CGFloat = 180
        static let compactBandSliderHeight: CGFloat = 120
    }

    // MARK: - Properties

    weak var delegate: EqualizerViewDelegate?

    private var eqFrequencies: [EqualizerFrequency] = []
    private var oldValues: [Float] = []
    private var bandSliderHeightConstraints: [NSLayoutConstraint] = []
    private var bandsLeadingToAxisConstraint: NSLayoutConstraint?
    private var bandsLeadingToContentConstraint: NSLayoutConstraint?

    private let playbackService = PlaybackService.sharedInstance()

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
        label.text = NSLocalizedString("EQUALIZER_CELL_TITLE", comment: "")
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
        button.addTarget(self, action: #selector(resetEqualizer), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let presetButton: UIButton = {
        let button = UIButton(type: .custom)
        button.showsMenuAsPrimaryAction = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let preampLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlayPrimaryTextColor
        label.text = NSLocalizedString("PREAMP", comment: "")
        label.isAccessibilityElement = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var preampSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = -20.0
        slider.maximumValue = 20.0
        slider.minimumTrackTintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        slider.accessibilityLabel = NSLocalizedString("PREAMP", comment: "")
        if #available(iOS 26.0, visionOS 26.0, *) {
            slider.trackConfiguration = UISlider.TrackConfiguration(allowsTickValuesOnly: false,
                                                                    neutralValue: 0.5,
                                                                    ticks: [.init(position: 0.5)])
        }
        slider.addTarget(self, action: #selector(preampSliderDidChangeValue), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private let preampTickView: UIView = {
        let view = UIView()
        view.backgroundColor = PresentationTheme.currentExcludingWhite.colors.overlayTertiaryTextColor
        view.layer.cornerRadius = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 26.0, visionOS 26.0, *) {
            view.isHidden = true
        }
        return view
    }()

    private let preampValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .monospacedDigitSystemFont(ofSize: 15, weight: .regular))
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlaySecondaryTextColor
        label.textAlignment = .right
        label.isAccessibilityElement = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let frequenciesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let zeroLineView: UIView = {
        let view = UIView()
        view.backgroundColor = PresentationTheme.currentExcludingWhite.colors.overlayHairlineColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let labelsView: UIView = {
        let view = UIView()
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var plus20Label = makeAxisLabel(text: "+20dB")
    private lazy var zeroLabel = makeAxisLabel(text: "+0dB")
    private lazy var minus20Label = makeAxisLabel(text: "-20dB")

    private let snapBandsLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlayPrimaryTextColor
        label.text = NSLocalizedString("SNAP_BANDS", comment: "")
        label.isAccessibilityElement = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var snapBandsSwitch: UISwitch = {
        let snapBandsSwitch = UISwitch()
        snapBandsSwitch.onTintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        snapBandsSwitch.isOn = UserDefaults.standard.bool(forKey: kVLCEqualizerSnapBands)
        snapBandsSwitch.accessibilityLabel = NSLocalizedString("SNAP_BANDS", comment: "")
        snapBandsSwitch.addTarget(self, action: #selector(snapBandsSwitchDidChangeValue), for: .valueChanged)
        snapBandsSwitch.translatesAutoresizingMaskIntoConstraints = false
        return snapBandsSwitch
    }()

    // MARK: - Init

    init(isModified: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        overrideUserInterfaceStyle = .dark

        createFrequencies()
        setupViews()
        updateBandSliderHeight()
        reloadData()
        resetButton.isEnabled = isModified

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
        if previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            updateBandSliderHeight()
        }
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            superview?.setNeedsLayout()
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        requestDismissal()
        return true
    }

    func focusForAccessibility() {
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    // MARK: - Setup
    private func createFrequencies() {
        let numberOfBands = playbackService.numberOfBands()
        for i in 0..<numberOfBands {
            let frequency = playbackService.frequencyOfBand(at: i)
            let eqFrequency = EqualizerFrequency(frequency: Int(frequency), index: Int(i))
            eqFrequency.slider.addTarget(self, action: #selector(sliderDidChangeValue), for: .valueChanged)
            eqFrequency.slider.addTarget(self, action: #selector(sliderWillChangeValue), for: .touchDown)
            eqFrequency.slider.addTarget(self, action: #selector(sliderDidDrag), for: .touchDragInside)
            eqFrequencies.append(eqFrequency)
        }
    }

    private func setupViews() {
        backgroundContainer.roundCorners(radius: Self.cardCornerRadius)
        addSubview(backgroundContainer)
        installBackgroundEffect()

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        [titleLabel, resetButton, presetButton, preampLabel, preampTickView, preampSlider, preampValueLabel,
         zeroLineView, labelsView, frequenciesStackView, snapBandsLabel, snapBandsSwitch].forEach { contentView.addSubview($0) }
        [plus20Label, zeroLabel, minus20Label].forEach { labelsView.addSubview($0) }

        let inset = Metrics.horizontalPadding
        let scrollViewHeight = scrollView.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        scrollViewHeight.priority = .defaultHigh

        var newConstraints: [NSLayoutConstraint] = [
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

            presetButton.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 2),
            presetButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            presetButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            presetButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),

            preampSlider.topAnchor.constraint(equalTo: presetButton.bottomAnchor, constant: Metrics.rowSpacing),
            preampSlider.leadingAnchor.constraint(equalTo: preampLabel.trailingAnchor, constant: Metrics.labelSpacing),
            preampSlider.trailingAnchor.constraint(equalTo: preampValueLabel.leadingAnchor, constant: -Metrics.labelSpacing),
            preampSlider.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),
            preampLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            preampLabel.centerYAnchor.constraint(equalTo: preampSlider.centerYAnchor),
            preampValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            preampValueLabel.centerYAnchor.constraint(equalTo: preampSlider.centerYAnchor),
            preampTickView.centerXAnchor.constraint(equalTo: preampSlider.centerXAnchor),
            preampTickView.centerYAnchor.constraint(equalTo: preampSlider.centerYAnchor),
            preampTickView.widthAnchor.constraint(equalToConstant: 2),
            preampTickView.heightAnchor.constraint(equalToConstant: 16),
        ]

        for eqFrequency in eqFrequencies {
            frequenciesStackView.addArrangedSubview(eqFrequency.stack)
            let heightConstraint = eqFrequency.slider.heightAnchor.constraint(equalToConstant: Metrics.bandSliderHeight)
            bandSliderHeightConstraints.append(heightConstraint)
        }
        newConstraints += bandSliderHeightConstraints

        let bandsLeadingToAxisConstraint = frequenciesStackView.leadingAnchor.constraint(equalTo: labelsView.trailingAnchor,
                                                                                          constant: Metrics.axisSpacing)
        let bandsLeadingToContentConstraint = frequenciesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                                                             constant: inset)
        self.bandsLeadingToAxisConstraint = bandsLeadingToAxisConstraint
        self.bandsLeadingToContentConstraint = bandsLeadingToContentConstraint
        labelsView.isHidden = true

        newConstraints += [
            frequenciesStackView.topAnchor.constraint(equalTo: preampSlider.bottomAnchor, constant: Metrics.rowSpacing),
            frequenciesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            bandsLeadingToContentConstraint,

            labelsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            labelsView.topAnchor.constraint(equalTo: frequenciesStackView.topAnchor),
            labelsView.bottomAnchor.constraint(equalTo: frequenciesStackView.bottomAnchor),

            snapBandsLabel.topAnchor.constraint(equalTo: frequenciesStackView.bottomAnchor, constant: Metrics.rowSpacing),
            snapBandsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            snapBandsLabel.trailingAnchor.constraint(lessThanOrEqualTo: snapBandsSwitch.leadingAnchor, constant: -Metrics.labelSpacing),
            snapBandsLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumControlHeight),
            snapBandsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            snapBandsSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            snapBandsSwitch.centerYAnchor.constraint(equalTo: snapBandsLabel.centerYAnchor),
        ]

        let collapsedLabelsWidth = labelsView.widthAnchor.constraint(equalToConstant: 0)
        collapsedLabelsWidth.priority = .defaultHigh
        newConstraints.append(collapsedLabelsWidth)
        for label in [plus20Label, zeroLabel, minus20Label] {
            newConstraints += [
                label.leadingAnchor.constraint(greaterThanOrEqualTo: labelsView.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: labelsView.trailingAnchor),
            ]
        }

        if let firstSlider = eqFrequencies.first?.slider {
            newConstraints += [
                plus20Label.topAnchor.constraint(equalTo: firstSlider.topAnchor),
                zeroLabel.centerYAnchor.constraint(equalTo: firstSlider.centerYAnchor),
                minus20Label.bottomAnchor.constraint(equalTo: firstSlider.bottomAnchor),

                zeroLineView.leadingAnchor.constraint(equalTo: frequenciesStackView.leadingAnchor),
                zeroLineView.trailingAnchor.constraint(equalTo: frequenciesStackView.trailingAnchor),
                zeroLineView.centerYAnchor.constraint(equalTo: firstSlider.centerYAnchor),
                zeroLineView.heightAnchor.constraint(equalToConstant: 1),
            ]
        }

        NSLayoutConstraint.activate(newConstraints)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLabelsVisibility()
    }

    private func updateLabelsVisibility() {
        let availableWidth = bounds.width - 2 * Metrics.horizontalPadding
        guard availableWidth > 0, !eqFrequencies.isEmpty,
              let bandsLeadingToAxisConstraint = bandsLeadingToAxisConstraint,
              let bandsLeadingToContentConstraint = bandsLeadingToContentConstraint else {
            return
        }

        let labelsWidth = [plus20Label, zeroLabel, minus20Label].map { $0.intrinsicContentSize.width }.max() ?? 0
        let bandWidthWithAxis = (availableWidth - labelsWidth - Metrics.axisSpacing) / CGFloat(eqFrequencies.count)
        let showsLabels = bandWidthWithAxis >= Metrics.minimumBandWidthWithAxis
        guard showsLabels == labelsView.isHidden else {
            return
        }

        labelsView.isHidden = !showsLabels
        if showsLabels {
            bandsLeadingToContentConstraint.isActive = false
            bandsLeadingToAxisConstraint.isActive = true
        } else {
            bandsLeadingToAxisConstraint.isActive = false
            bandsLeadingToContentConstraint.isActive = true
        }
    }

    private func updateBandSliderHeight() {
        let isCompact = traitCollection.verticalSizeClass == .compact
        let height = isCompact ? Metrics.compactBandSliderHeight : Metrics.bandSliderHeight
        bandSliderHeightConstraints.forEach { $0.constant = height }
    }

    private func makeAxisLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFontMetrics(forTextStyle: .caption2).scaledFont(for: .systemFont(ofSize: 11))
        label.adjustsFontForContentSizeCategory = true
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlaySecondaryTextColor
        label.textAlignment = .right
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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

    func reloadData() {
        preampSlider.value = Float(playbackService.preAmplification)
        updatePreampValueLabel()

        for (i, eqFrequency) in eqFrequencies.enumerated() {
            eqFrequency.slider.setValue(Float(playbackService.amplification(ofBand: UInt32(i))), animated: false)
            updateLabels(of: eqFrequency)
        }

        updatePresetButton()
    }

    private func updatePreampValueLabel() {
        let text = EqualizerValueFormatter.stringWithUnit(forDecibels: preampSlider.value)
        preampValueLabel.text = text
        preampSlider.accessibilityValue = text
    }

    private func updateLabels(of eqFrequency: EqualizerFrequency) {
        let value = eqFrequency.slider.value
        eqFrequency.currentValueLabel.text = EqualizerValueFormatter.string(forDecibels: value)
        eqFrequency.slider.accessibilityValue = EqualizerValueFormatter.stringWithUnit(forDecibels: value)
    }

    private func updatePresetButton() {
        let selectedProfile = playbackService.selectedEqualizerProfile()
        let presets = playbackService.equalizerProfiles()
        let customProfileNames = playbackService.customEqualizerProfileNames
        let secondaryTextColor = PresentationTheme.currentExcludingWhite.colors.overlaySecondaryTextColor
        presetButton.applyOverlayControlStyle(title: Self.presetName(for: selectedProfile, presets: presets, customProfileNames: customProfileNames),
                                              image: UIImage(systemName: "chevron.up.chevron.down"),
                                              isActive: false,
                                              cornerRadius: Self.minimumControlHeight / 2)
        presetButton.configuration?.imagePlacement = .trailing
        presetButton.configuration?.imageColorTransformer = UIConfigurationColorTransformer { _ in secondaryTextColor }
        presetButton.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .footnote)
        presetButton.menu = makePresetMenu(selectedProfile: selectedProfile, presets: presets, customProfileNames: customProfileNames)
    }

    private func setModified(_ modified: Bool) {
        resetButton.isEnabled = modified
        delegate?.equalizerView(self, didChangeModifiedState: modified)
    }

    private func announceSelectedPreset() {
        UIAccessibility.post(notification: .announcement, argument: presetButton.configuration?.title)
    }

    private static func presetName(for selectedProfile: IndexPath,
                                   presets: [VLCAudioEqualizer.Preset],
                                   customProfileNames: [String]) -> String {
        if selectedProfile.section == 1 {
            return selectedProfile.row < customProfileNames.count ? customProfileNames[selectedProfile.row] : NSLocalizedString("OFF", comment: "")
        }
        guard selectedProfile.row > 0, selectedProfile.row - 1 < presets.count else {
            return NSLocalizedString("OFF", comment: "")
        }
        return presets[selectedProfile.row - 1].name
    }

    // MARK: - Helpers

    private static let minimumControlHeight: CGFloat = 44
    private static let cardCornerRadius: CGFloat = 30
    private static let preampSnapDistance: Float = 0.5

    fileprivate static let frequencyFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    fileprivate static func setupBandLabel(_ label: UILabel) {
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.textAlignment = .center
        label.isAccessibilityElement = false
        label.translatesAutoresizingMaskIntoConstraints = false
    }
}

// MARK: - Presets menu

extension EqualizerView {
    private func makePresetMenu(selectedProfile: IndexPath,
                                presets: [VLCAudioEqualizer.Preset],
                                customProfileNames: [String]) -> UIMenu {
        var presetActions = [UIAction(title: NSLocalizedString("OFF", comment: ""),
                                      state: selectedProfile == IndexPath(row: 0, section: 0) ? .on : .off) { [unowned self] _ in
            self.selectPreset(0, isCustom: false)
        }]
        for (index, preset) in presets.enumerated() {
            let row = index + 1
            presetActions.append(UIAction(title: preset.name,
                                          state: selectedProfile == IndexPath(row: row, section: 0) ? .on : .off) { [unowned self] _ in
                self.selectPreset(row, isCustom: false)
            })
        }
        var children: [UIMenuElement] = [UIMenu(options: .displayInline, children: presetActions)]

        if !customProfileNames.isEmpty {
            let customProfileCount = customProfileNames.count
            let customProfileMenus = customProfileNames.enumerated().map { index, name in
                makeCustomProfileMenu(at: index,
                                      name: name,
                                      count: customProfileCount,
                                      isSelected: selectedProfile == IndexPath(row: index, section: 1))
            }
            children.append(UIMenu(title: NSLocalizedString("CUSTOM_EQUALIZER_PROFILES", comment: ""),
                                   options: .displayInline,
                                   children: customProfileMenus))
        }

        let saveAction = UIAction(title: NSLocalizedString("EQUALIZER_SAVE_PROFILE", comment: ""),
                                  image: UIImage(systemName: "square.and.arrow.down")) { [unowned self] _ in
            self.saveNewProfile()
        }
        children.append(UIMenu(options: .displayInline, children: [saveAction]))

        return UIMenu(children: children)
    }

    private func makeCustomProfileMenu(at index: Int, name: String, count: Int, isSelected: Bool) -> UIMenu {
        let applyAction = UIAction(title: NSLocalizedString("EQUALIZER_APPLY_PROFILE", comment: ""),
                                   image: UIImage(systemName: "checkmark.circle")) { [unowned self] _ in
            self.selectPreset(index, isCustom: true)
        }
        let renameAction = UIAction(title: NSLocalizedString("BUTTON_RENAME", comment: ""),
                                    image: UIImage(systemName: "pencil")) { [unowned self] _ in
            self.renameProfile(at: index, currentName: name)
        }
        let moveUpAction = UIAction(title: NSLocalizedString("EQUALIZER_MOVE_UP", comment: ""),
                                    image: UIImage(systemName: "arrow.up"),
                                    attributes: index == 0 ? .disabled : []) { [unowned self] _ in
            self.moveProfile(at: index, up: true)
        }
        let moveDownAction = UIAction(title: NSLocalizedString("EQUALIZER_MOVE_DOWN", comment: ""),
                                      image: UIImage(systemName: "arrow.down"),
                                      attributes: index == count - 1 ? .disabled : []) { [unowned self] _ in
            self.moveProfile(at: index, up: false)
        }
        let deleteAction = UIAction(title: NSLocalizedString("BUTTON_DELETE", comment: ""),
                                    image: UIImage(systemName: "trash"),
                                    attributes: .destructive) { [unowned self] _ in
            self.deleteProfile(at: index)
        }

        return UIMenu(title: name,
                      image: isSelected ? UIImage(systemName: "checkmark") : nil,
                      children: [applyAction,
                                 renameAction,
                                 UIMenu(options: .displayInline, children: [moveUpAction, moveDownAction]),
                                 UIMenu(options: .displayInline, children: [deleteAction])])
    }

    private func selectPreset(_ preset: Int, isCustom: Bool) {
        if !isCustom {
            playbackService.applyEqualizerPreset(UInt32(preset))
        } else {
            playbackService.applyCustomEqualizerProfile(at: UInt(preset))
        }

        setModified(false)
        reloadData()
        announceSelectedPreset()
    }

    private func moveProfile(at index: Int, up: Bool) {
        playbackService.moveCustomEqualizerProfile(at: UInt(index), up: up)
        updatePresetButton()
    }
}

// MARK: - Slider events

extension EqualizerView {
    @objc func preampSliderDidChangeValue(sender: UISlider) {
        if abs(sender.value) < Self.preampSnapDistance {
            sender.value = 0
        }
        playbackService.preAmplification = CGFloat(sender.value)
        updatePreampValueLabel()
        setModified(true)
    }

    @objc func sliderWillChangeValue(sender: VerticalSliderControl) {
        oldValues = eqFrequencies.map { $0.slider.value }
    }

    @objc func sliderDidChangeValue(sender: VerticalSliderControl) {
        playbackService.setAmplification(CGFloat(sender.value), forBand: UInt32(sender.tag))
        if let eqFrequency = eqFrequencies.objectAtIndex(index: sender.tag) {
            updateLabels(of: eqFrequency)
        }
        setModified(true)
    }

    @objc func sliderDidDrag(sender: VerticalSliderControl) {
        let index = sender.tag

        guard snapBandsSwitch.isOn, oldValues.count == eqFrequencies.count else {
            return
        }

        let delta = sender.value - oldValues[index]

        for (i, eqFrequency) in eqFrequencies.enumerated() where i != index {
            let slider = eqFrequency.slider
            let delta_index = Float(abs(i - index))
            let newValue = min(max(oldValues[i] + delta / (pow(delta_index, 3) + 1), slider.minimumValue), slider.maximumValue)
            guard newValue != slider.value else {
                continue
            }
            slider.setValue(newValue, animated: false)
            playbackService.setAmplification(CGFloat(newValue), forBand: UInt32(i))
            updateLabels(of: eqFrequency)
        }
    }
}

// MARK: - Snap Bands event

extension EqualizerView {
    @objc func snapBandsSwitchDidChangeValue(sender: UISwitch) {
        UserDefaults.standard.setValue(sender.isOn, forKey: kVLCEqualizerSnapBands)
    }
}

// MARK: - Buttons event

extension EqualizerView {
    private func saveNewProfile() {
        let alertController = UIAlertController(title: NSLocalizedString("CUSTOM_EQUALIZER_ALERT_TITLE", comment: ""),
                                                message: NSLocalizedString("CUSTOM_EQUALIZER_ALERT_MESSAGE", comment: ""),
                                                preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.text = NSLocalizedString("DEFAULT_PROFILE_NAME", comment: "")
            textField.placeholder = NSLocalizedString("CUSTOM_EQUALIZER_PROFILE_PLACEHOLDER", comment: "")
        }

        let saveAction = UIAlertAction(title: NSLocalizedString("BUTTON_SAVE", comment: ""), style: .default) { [weak alertController] _ in
            let name: String = alertController?.textFields?.first?.text ?? NSLocalizedString("DEFAULT_PROFILE_NAME", comment: "")
            self.playbackService.saveCustomEqualizerProfile(withName: name)

            self.setModified(false)
            self.updatePresetButton()
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        delegate?.equalizerView(self, present: alertController)
    }

    @objc func resetEqualizer() {
        playbackService.restoreSavedEqualizerProfile()
        setModified(false)
        reloadData()
        announceSelectedPreset()
    }

    @objc private func requestDismissal() {
        delegate?.equalizerViewDidRequestDismissal(self)
    }

    @objc private func reduceTransparencyChanged() {
        installBackgroundEffect()
        updatePresetButton()
    }

    @objc private func darkerSystemColorsChanged() {
        updatePresetButton()
    }

    private func renameProfile(at index: Int, currentName: String) {
        let alertController = UIAlertController(title: NSLocalizedString("RENAME_CUSTOM_PROFILE_TITLE", comment: ""),
                                                message: nil,
                                                preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.text = currentName
            textField.placeholder = NSLocalizedString("CUSTOM_EQUALIZER_PROFILE_PLACEHOLDER", comment: "")
        }

        let renameAction = UIAlertAction(title: NSLocalizedString("BUTTON_RENAME", comment: ""), style: .default) { [weak alertController] _ in
            guard let newName = alertController?.textFields?.first?.text else {
                return
            }

            self.playbackService.renameCustomEqualizerProfile(at: UInt(index), toName: newName)
            self.updatePresetButton()
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)

        alertController.addAction(renameAction)
        alertController.addAction(cancelAction)

        delegate?.equalizerView(self, present: alertController)
    }

    private func deleteProfile(at index: Int) {
        let alertController = UIAlertController(title: NSLocalizedString("DELETE_CUSTOM_PROFILE_TITLE", comment: ""),
                                                message: NSLocalizedString("DELETE_CUSTOM_PROFILE_MESSAGE", comment: ""),
                                                preferredStyle: .alert)

        let deleteAction = UIAlertAction(title: NSLocalizedString("BUTTON_DELETE", comment: ""), style: .destructive) { _ in
            let deletesSelectedProfile = self.playbackService.selectedEqualizerProfile() == IndexPath(row: index, section: 1)
            self.playbackService.deleteCustomEqualizerProfile(at: UInt(index))
            if deletesSelectedProfile {
                self.setModified(false)
            }
            self.reloadData()
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)

        delegate?.equalizerView(self, present: alertController)
    }
}

// MARK: - EqualizerViewDelegate

protocol EqualizerViewDelegate: AnyObject {
    func equalizerView(_ equalizerView: EqualizerView, didChangeModifiedState isModified: Bool)
    func equalizerView(_ equalizerView: EqualizerView, present alertController: UIAlertController)
    func equalizerViewDidRequestDismissal(_ equalizerView: EqualizerView)
}
