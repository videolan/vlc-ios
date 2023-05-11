/*****************************************************************************
* EqualizerView.swift
*
* Copyright © 2020 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*                       Diogo Simao Marques <dogo@videolabs.io>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import UIKit

@objc class EqualizerView: UIView {

    // MARK: - EqualizerFrequency structure
    private struct EqualizerFrequency {
        let stack: UIStackView
        let currentValueLabel: UILabel
        let slider: VerticalSlider
        let frequencyLabel: UILabel

        init(frequency: Int, index: Int) {
            stack = UIStackView()
            currentValueLabel = UILabel()
            slider = VerticalSlider()
            frequencyLabel = UILabel()

            setupSlider(tag: index)
            let name = frequency < 1000 ? "\(frequency)" : "\(frequency/1000)K"
            setupFrequencyLabel(name: name)
            setupCurrentValueLabel()
            setupStack()
            setupStackConstraints()
        }

        private func setupStack() {
            stack.axis = .vertical
            stack.alignment = .top
            stack.distribution = .fillProportionally
            stack.spacing = 10
            stack.addArrangedSubview(currentValueLabel)
            stack.addArrangedSubview(slider)
            stack.addArrangedSubview(frequencyLabel)
        }

        private func setupSlider(tag: Int) {
            slider.tag = tag
            slider.maximumValue = 20.0
            slider.value = 0.0
            slider.minimumValue = -20.0
            slider.setThumbImage(image: UIImage(named: "sliderKnob"), for: .normal)
        }

        private func setupCurrentValueLabel() {
            currentValueLabel.text = "0dB"
            currentValueLabel.textAlignment = .center
            currentValueLabel.font = .systemFont(ofSize: 11, weight: .bold)
            currentValueLabel.setContentHuggingPriority(.required, for: .vertical)
        }

        private func setupFrequencyLabel(name: String) {
            frequencyLabel.text = name
            frequencyLabel.textAlignment = .center
            frequencyLabel.font = .systemFont(ofSize: 11)
            frequencyLabel.setContentHuggingPriority(.required, for: .vertical)
        }

        private func setupStackConstraints() {
            var frequenciesConstraints: [NSLayoutConstraint] = []
            frequenciesConstraints.append(currentValueLabel.centerXAnchor.constraint(equalTo: stack.centerXAnchor))
            frequenciesConstraints.append(slider.heightAnchor.constraint(greaterThanOrEqualToConstant: 100))
            frequenciesConstraints.append(slider.centerXAnchor.constraint(equalTo: stack.centerXAnchor))
            frequenciesConstraints.append(frequencyLabel.centerXAnchor.constraint(equalTo: stack.centerXAnchor))
            NSLayoutConstraint.activate(frequenciesConstraints)
        }
    }

    // MARK: - Properties

    @objc var delegate: EqualizerViewDelegate? {
        didSet {
            createFrequencyStacks()
            if var profiles = delegate?.equalizerProfiles() as? [VLCAudioEqualizer.Preset] {
                presetSelectorView = EqualizerPresetSelector(profiles: profiles)
            }
            setupViews()
        }
    }

    weak var UIDelegate: EqualizerViewUIDelegate?

    // Container views
    private let stackView = UIStackView()
    private var presetSelectorView: EqualizerPresetSelector?
    private let labelsAndFrequenciesStackView = UIStackView()
    private let labelsStackView = UIStackView()
    private let frequenciesScrollView = UIScrollView()
    private let frequenciesStackView = UIStackView()
    private let snapBandsStackView = UIStackView()

    private let plus20Label = UILabel()
    private let zeroLabel = UILabel()
    private let minus20Label = UILabel()
    private let snapBandsLabel = UILabel()
    private let snapBandsSwitch = UISwitch()
    private let cancelButton = UIButton()
    private let resetButton = UIButton()

    private var eqFrequencies: [EqualizerFrequency] = []
    private var valuesOnShow: [Float] = []
    private var oldValues: [Float] = []

    private var parentPopup: PopupView?
    private var showCancel = false

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let superview = superview {
            presetSelectorView?.setHeightConstraint(equalTo: superview.heightAnchor, multiplier: 0.75)
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func willShow() {
        showCancel = false
        parentPopup?.updateAccessoryViews()
        reloadData()
        resetValuesOnShow()
    }

    // MARK: - Setup
    private func createFrequencyStacks() {
        if let numberOfBands = delegate?.numberOfBands() {
            for i in 0..<numberOfBands {
                if let frequency = delegate?.frequencyOfBand(atIndex: i) {
                    eqFrequencies.append(EqualizerFrequency(frequency: Int(frequency), index: Int(i)))
                }
            }
        }
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 20

        let contentStackViews: [UIStackView] = [
            labelsAndFrequenciesStackView,
            snapBandsStackView
        ]

        if let presetSelectorView = presetSelectorView {
            stackView.addArrangedSubview(presetSelectorView)
            presetSelectorView.translatesAutoresizingMaskIntoConstraints = false
        }

        for contentStackView in contentStackViews {
            contentStackView.translatesAutoresizingMaskIntoConstraints = false
            contentStackView.axis = .horizontal
            contentStackView.alignment = .leading
            contentStackView.distribution = .fill
            contentStackView.spacing = 10
            stackView.addArrangedSubview(contentStackView)
        }

        frequenciesStackView.distribution = .fillEqually
        snapBandsStackView.alignment = .trailing

        //Init presets views
        presetSelectorView?.delegate = self
        presetSelectorView?.parent = self

        //Init frequencies zone
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .fill
        labelsStackView.distribution = .equalSpacing
        labelsStackView.spacing = 10
        labelsStackView.isLayoutMarginsRelativeArrangement = true
        labelsStackView.layoutMargins.top = 25
        labelsStackView.layoutMargins.bottom = 35
        plus20Label.text = "+20dB"
        plus20Label.font = .systemFont(ofSize: 11)
        plus20Label.textAlignment = .right
        plus20Label.setContentHuggingPriority(.required, for: .vertical)
        plus20Label.setContentHuggingPriority(.required, for: .horizontal)
        plus20Label.setContentCompressionResistancePriority(.required, for: .horizontal)
        zeroLabel.text = "+0dB"
        zeroLabel.font = .systemFont(ofSize: 11)
        zeroLabel.textAlignment = .right
        minus20Label.text = "-20dB"
        minus20Label.font = .systemFont(ofSize: 11)
        minus20Label.textAlignment = .right
        minus20Label.setContentHuggingPriority(.required, for: .vertical)
        labelsStackView.addArrangedSubview(plus20Label)
        labelsStackView.addArrangedSubview(zeroLabel)
        labelsStackView.addArrangedSubview(minus20Label)

        //Init snapBand views
        snapBandsLabel.text = NSLocalizedString("SNAP_BANDS", comment: "")
        snapBandsLabel.textAlignment = .right
        snapBandsLabel.setContentHuggingPriority(.required, for: .vertical)
        snapBandsSwitch.isOn = UserDefaults.standard.bool(forKey: kVLCEqualizerSnapBands)
        snapBandsSwitch.addTarget(self, action: #selector(snapBandsSwitchDidChangeValue), for: .valueChanged)
        snapBandsSwitch.setContentHuggingPriority(.required, for: .vertical)
        snapBandsStackView.addArrangedSubview(snapBandsLabel)
        snapBandsStackView.addArrangedSubview(snapBandsSwitch)
        snapBandsStackView.alignment = .center

        //Init buttons views
        cancelButton.setImage(UIImage(named: "iconUndo"), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelEqualizer), for: .touchUpInside)
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        resetButton.setTitle(NSLocalizedString("BUTTON_RESET", comment: ""), for: .normal)
        resetButton.addTarget(self, action: #selector(resetEqualizer), for: .touchUpInside)
        resetButton.setContentHuggingPriority(.required, for: .vertical)
        resetButton.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(stackView)
        setupFrequenciesStackView()
        setupConstraints()
        setupTheme()
    }

    private func setupConstraints() {
        var newConstraints: [NSLayoutConstraint] = []

        newConstraints.append(stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8))
        newConstraints.append(stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8))
        newConstraints.append(stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8))
        newConstraints.append(stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8))

        let contentStackViews: [UIStackView] = [
            labelsAndFrequenciesStackView,
            snapBandsStackView
        ]

        for contentStackView in contentStackViews {
            newConstraints.append(contentStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor))
            newConstraints.append(contentStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor))
        }

        //Presets constraints
        if let presetSelectorView = presetSelectorView {
            newConstraints.append(presetSelectorView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor))
            newConstraints.append(presetSelectorView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor))
        }

        //Frequencies constraints
        newConstraints.append(labelsAndFrequenciesStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100))

        newConstraints.append(labelsStackView.topAnchor.constraint(equalTo: labelsAndFrequenciesStackView.topAnchor))
        newConstraints.append(labelsStackView.bottomAnchor.constraint(equalTo: labelsAndFrequenciesStackView.bottomAnchor))
        newConstraints.append(labelsStackView.heightAnchor.constraint(equalTo: labelsAndFrequenciesStackView.heightAnchor))

        newConstraints.append(frequenciesScrollView.topAnchor.constraint(equalTo: labelsAndFrequenciesStackView.topAnchor))
        newConstraints.append(frequenciesScrollView.bottomAnchor.constraint(equalTo: labelsAndFrequenciesStackView.bottomAnchor))
        newConstraints.append(frequenciesScrollView.heightAnchor.constraint(equalTo: labelsAndFrequenciesStackView.heightAnchor))

        newConstraints.append(frequenciesStackView.topAnchor.constraint(equalTo: frequenciesScrollView.topAnchor))
        newConstraints.append(frequenciesStackView.bottomAnchor.constraint(equalTo: frequenciesScrollView.bottomAnchor, constant: -10))
        newConstraints.append(frequenciesStackView.heightAnchor.constraint(equalTo: frequenciesScrollView.heightAnchor, constant: -10))
        newConstraints.append(frequenciesStackView.leadingAnchor.constraint(equalTo: frequenciesScrollView.leadingAnchor))
        newConstraints.append(frequenciesStackView.trailingAnchor.constraint(equalTo: frequenciesScrollView.trailingAnchor))

        for eqFrequency in eqFrequencies {
            newConstraints.append(eqFrequency.stack.topAnchor.constraint(equalTo: frequenciesStackView.topAnchor))
            newConstraints.append(eqFrequency.stack.bottomAnchor.constraint(equalTo: frequenciesStackView.bottomAnchor))
            newConstraints.append(eqFrequency.stack.heightAnchor.constraint(equalTo: frequenciesStackView.heightAnchor))

            let minWidthConstraint = eqFrequency.stack.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
            let widthConstraint = eqFrequency.stack.widthAnchor.constraint(equalTo: frequenciesScrollView.widthAnchor,
                                                                           multiplier: 1.0 / CGFloat(eqFrequencies.count))
            minWidthConstraint.priority = .required
            widthConstraint.priority = .defaultHigh
            newConstraints.append(minWidthConstraint)
            newConstraints.append(widthConstraint)
        }

        //SnapBands constraints
        newConstraints.append(snapBandsStackView.heightAnchor.constraint(equalTo: snapBandsSwitch.heightAnchor))

        NSLayoutConstraint.activate(newConstraints)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        frequenciesScrollView.flashScrollIndicatorsIfNeeded()
    }

    private func resetValuesOnShow() {
        valuesOnShow.removeAll()
        for eqFrequency in eqFrequencies {
            valuesOnShow.append(eqFrequency.slider.value)
        }
    }

    private func setupFrequenciesStackView() {
        labelsAndFrequenciesStackView.alignment = .fill
        labelsAndFrequenciesStackView.distribution = .fill
        labelsAndFrequenciesStackView.spacing = 5
        labelsAndFrequenciesStackView.addArrangedSubview(labelsStackView)
        frequenciesStackView.translatesAutoresizingMaskIntoConstraints = false
        frequenciesStackView.axis = .horizontal
        frequenciesStackView.alignment = .leading
        frequenciesStackView.distribution = .fill
        frequenciesStackView.spacing = 0

        for eqFrequency in eqFrequencies {
            eqFrequency.slider.addTarget(self, action: #selector(sliderDidChangeValue), for: .valueChanged)
            eqFrequency.slider.addTarget(self, action: #selector(sliderWillChangeValue), for: .touchDown)
            eqFrequency.slider.addTarget(self, action: #selector(sliderDidDrag), for: .touchDragInside)
            frequenciesStackView.addArrangedSubview(eqFrequency.stack)
        }

        frequenciesScrollView.indicatorStyle = .white
        frequenciesScrollView.addSubview(frequenciesStackView)

        labelsAndFrequenciesStackView.addArrangedSubview(frequenciesScrollView)
    }

    @objc func setupTheme() {
        let colors = PresentationTheme.currentExcludingWhite.colors
        backgroundColor = colors.background
        plus20Label.textColor = colors.cellTextColor
        zeroLabel.textColor = colors.cellTextColor
        minus20Label.textColor = colors.cellTextColor
        snapBandsLabel.textColor = colors.cellTextColor
        cancelButton.tintColor = colors.orangeUI
        resetButton.setTitleColor(colors.orangeUI, for: .normal)

        for eqFrequency in eqFrequencies {
            eqFrequency.currentValueLabel.textColor = colors.cellTextColor
            eqFrequency.slider.tintColor = colors.orangeUI
            eqFrequency.frequencyLabel.textColor = colors.cellTextColor
        }
    }

    @objc func reloadData() {
        if let delegate = delegate {
            presetSelectorView?.setPreampSliderValue(Float(delegate.preAmplification))
            presetSelectorView?.setSelectedProfileValue(delegate.selectedEqualizerProfile())

            for (i, eqFrequency) in eqFrequencies.enumerated() {
                eqFrequency.slider.value = Float(delegate.amplification(ofBand: UInt32(i)))
                eqFrequency.currentValueLabel.text = "\(Double(Int(eqFrequency.slider.value * 100)) / 100)"
            }
        }
    }
}

// MARK: - Slider events

extension EqualizerView {
    @objc func sliderWillChangeValue(sender: UISlider) {
        oldValues.removeAll()
        for eqFrequency in eqFrequencies {
            oldValues.append(eqFrequency.slider.value)
        }
    }

    @objc func sliderDidChangeValue(sender: UISlider) {
        delegate?.setAmplification(CGFloat(sender.value), forBand: UInt32(sender.tag))
        showCancel = true
        parentPopup?.updateAccessoryViews()
        UIDelegate?.equalizerViewShowIcon()
        hideEqualizerIconIfNeeded()
    }

    @objc func sliderDidDrag(sender: UISlider) {
        let index = sender.tag

        if snapBandsSwitch.isOn {
            let delta = sender.value - oldValues[index]

            for i in 0..<eqFrequencies.count {
                if i != index {
                    if let currentSlider = eqFrequencies.objectAtIndex(index: i),
                       let oldValue = oldValues.objectAtIndex(index: i) {
                        let delta_index = Float(abs(i - index))
                        currentSlider.slider.value = oldValue + delta / Float(pow(delta_index, 3) + 1)
                    }
                }
            }
        }

        if snapBandsSwitch.isOn {
            for eqFrequency in eqFrequencies {
                eqFrequency.currentValueLabel.text = "\(Double(Int(eqFrequency.slider.value * 100)) / 100)"
            }
        } else {
            if let currentValueLabel = eqFrequencies.objectAtIndex(index: index)?.currentValueLabel {
                currentValueLabel.text = "\(Double(Int(sender.value * 100)) / 100)"
            }
        }
    }
}

// MARK: - Snap Bands event

extension EqualizerView {
    @objc func snapBandsSwitchDidChangeValue(sender: UISwitch) {
        UserDefaults.standard.setValue(sender.isOn, forKey: kVLCEqualizerSnapBands)
    }
}

// MARK: - Reset button event

extension EqualizerView {
    @objc func cancelEqualizer() {
        for (i, eqFrequency) in eqFrequencies.enumerated() {
            let value = valuesOnShow.objectAtIndex(index: i) ?? 0
            eqFrequency.slider.value = value
            sliderDidChangeValue(sender: eqFrequency.slider.slider)
            eqFrequency.currentValueLabel.text = "\(Double(Int(value * 100)) / 100)"
        }
        showCancel = false
        parentPopup?.updateAccessoryViews()
    }

    @objc func resetEqualizer() {
        for eqFrequency in eqFrequencies {
            eqFrequency.slider.value = 0
            sliderDidChangeValue(sender: eqFrequency.slider.slider)
            eqFrequency.currentValueLabel.text = "0.0"
        }

        let preampValue = UserDefaults.standard.float(forKey: kVLCSettingDefaultPreampLevel)
        delegate?.preAmplification = CGFloat(preampValue)
        presetSelectorView?.setPreampSliderValue(preampValue)

        UIDelegate?.equalizerViewHideIcon()
    }

    private func hideEqualizerIconIfNeeded() {
        for eqFrequency in eqFrequencies {
            if eqFrequency.slider.value != 0 {
                return
            }
        }

        UIDelegate?.equalizerViewHideIcon()
    }
}

// MARK: - EqualizerPresetSelectorDelegate

extension EqualizerView: EqualizerPresetSelectorDelegate {
    func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, didSetPreamp preamp: Float) {
        delegate?.preAmplification = CGFloat(preamp)
    }

    func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, didSelectPreset preset: Int) {
        delegate?.resetEqualizer(fromProfile: UInt32(preset))
        reloadData()
    }
}

// MARK: - PopupViewAccessoryViewDelegate

extension EqualizerView: PopupViewAccessoryViewsDelegate {
    func popupViewAccessoryView(_ popupView: PopupView) -> [UIView] {
        if parentPopup == nil {
            parentPopup = popupView
        }
        if showCancel {
            return [cancelButton, resetButton]
        } else {
            return [resetButton]
        }
    }
}

// MARK: - EqualizerViewDelegate

@objc protocol EqualizerViewDelegate {
    @objc var preAmplification: CGFloat { get set }
    @objc func setAmplification(_ amplification: CGFloat, forBand index: UInt32)
    @objc func amplification(ofBand index: UInt32) -> CGFloat
    @objc func equalizerProfiles() -> NSArray
    @objc func resetEqualizer(fromProfile profile: UInt32)
    @objc func numberOfBands() -> UInt32
    @objc func frequencyOfBand(atIndex index: UInt32) -> CGFloat
    @objc func selectedEqualizerProfile() -> UInt32
}

// MARK: - EqualizerViewUIDelegate

protocol EqualizerViewUIDelegate: AnyObject {
    func equalizerViewShowIcon()
    func equalizerViewHideIcon()
}
