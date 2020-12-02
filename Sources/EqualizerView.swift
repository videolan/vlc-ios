/*****************************************************************************
* EqualizerView.swift
*
* Copyright © 2020 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
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
        }

        private func setupFrequencyLabel(name: String) {
            frequencyLabel.text = name
            frequencyLabel.textAlignment = .center
            frequencyLabel.font = .systemFont(ofSize: 11)
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

    @objc var delegate: EqualizerViewDelegate? {
        didSet {
            createFrequencyStacks()
            setupViews()
        }
    }
    @objc var UIDelegate: EqualizerViewUIDelegate?

    override var isHidden: Bool {
        didSet {
            frequenciesScrollView.contentSize = frequenciesStackView.frame.size
            if isHidden == false {
                valuesOnShow.removeAll()
                for eqFrequency in eqFrequencies {
                    valuesOnShow.append(eqFrequency.slider.value)
                }
            }
        }
    }

    // Container views
    private let stackView = UIStackView()
    private let presetsStackView = UIStackView()
    private let preampStackView = UIStackView()
    private let labelsAndFrequenciesStackView = UIStackView()
    private let labelsStackView = UIStackView()
    private let frequenciesScrollView = UIScrollView()
    private let frequenciesStackView = UIStackView()
    private let snapBandsStackView = UIStackView()
    private let buttonsStackView = UIStackView()

    private let presetsLabel = UILabel()
    private let presetsPicker = UIPickerView()
    private let preampLabel = UILabel()
    private let preampSlider = VLCSlider()
    private let plus20Label = UILabel()
    private let zeroLabel = UILabel()
    private let minus20Label = UILabel()
    private let snapBandLabel = UILabel()
    private let snapBandSwitch = UISwitch()
    private let cancelButton = UIButton()
    private let resetButton = UIButton()

    private var eqFrequencies: [EqualizerFrequency] = []
    private var valuesOnShow: [Float] = []
    private var oldValues: [Float] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNotifications()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNotifications()
    }

    // MARK: - Setup
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
    }

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
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fillProportionally
        stackView.spacing = 10

        let contentStackViews: [UIStackView] = [
            presetsStackView,
            preampStackView,
            labelsAndFrequenciesStackView,
            snapBandsStackView,
            buttonsStackView
        ]

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
        buttonsStackView.alignment = .fill
        buttonsStackView.distribution = .fillEqually

        //Init presets views
        presetsLabel.text = NSLocalizedString("PRESETS", comment: "")
        presetsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        presetsLabel.setContentHuggingPriority(.required, for: .horizontal)
        presetsPicker.delegate = self
        presetsPicker.dataSource = self
        presetsPicker.setContentHuggingPriority(.required, for: .vertical)
        presetsStackView.addArrangedSubview(presetsLabel)
        presetsStackView.addArrangedSubview(presetsPicker)

        //Init preamp views
        preampLabel.text = NSLocalizedString("PREAMP", comment: "")
        preampLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        preampLabel.setContentHuggingPriority(.required, for: .horizontal)
        preampSlider.maximumValue = 20.0
        preampSlider.value = 0.0
        preampSlider.minimumValue = -20.0
        preampSlider.setContentHuggingPriority(.required, for: .vertical)
        preampSlider.addTarget(self, action: #selector(preampSliderDidChangeValue), for: .valueChanged)
        preampStackView.addArrangedSubview(preampLabel)
        preampStackView.addArrangedSubview(preampSlider)

        //Init frequencies zone
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .fill
        labelsStackView.distribution = .equalSpacing
        labelsStackView.spacing = 10
        plus20Label.text = "\n+20dB"
        plus20Label.numberOfLines = 2
        plus20Label.font = .systemFont(ofSize: 11)
        zeroLabel.text = "+0dB"
        zeroLabel.font = .systemFont(ofSize: 11)
        minus20Label.text = "-20dB\n"
        minus20Label.numberOfLines = 2
        minus20Label.font = .systemFont(ofSize: 11)
        labelsStackView.addArrangedSubview(plus20Label)
        labelsStackView.addArrangedSubview(zeroLabel)
        labelsStackView.addArrangedSubview(minus20Label)

        //Init snapBand views
        snapBandLabel.text = NSLocalizedString("SNAP_BANDS", comment: "")
        snapBandLabel.textAlignment = .right
        snapBandSwitch.isOn = UserDefaults.standard.bool(forKey: kVLCEqualizerSnapBands)
        snapBandSwitch.addTarget(self, action: #selector(snapBandsSwitchDidChangeValue), for: .valueChanged)
        snapBandsStackView.addArrangedSubview(snapBandLabel)
        snapBandsStackView.addArrangedSubview(snapBandSwitch)

        //Init buttons views
        cancelButton.setTitle(NSLocalizedString("BUTTON_CANCEL", comment: ""), for: .normal)
        resetButton.setTitle(NSLocalizedString("BUTTON_RESET", comment: ""), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelEqualizer), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetEqualizer), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(cancelButton)
        buttonsStackView.addArrangedSubview(resetButton)

        addSubview(stackView)
        setupFrequenciesStackView()
        setupConstraints()
        themeDidChange()
    }

    private func setupConstraints() {
        var newConstraints: [NSLayoutConstraint] = []

        newConstraints.append(stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8))
        newConstraints.append(stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8))
        newConstraints.append(stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8))
        newConstraints.append(stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8))

        let contentStackViews: [UIStackView] = [
            presetsStackView,
            preampStackView,
            labelsAndFrequenciesStackView,
            snapBandsStackView,
            buttonsStackView
        ]

        for contentStackView in contentStackViews {
            newConstraints.append(contentStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor))
            newConstraints.append(contentStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor))
        }

        //Presets constraints
        newConstraints.append(presetsPicker.heightAnchor.constraint(equalToConstant: 100))
        newConstraints.append(presetsLabel.centerYAnchor.constraint(equalTo: presetsPicker.centerYAnchor))

        //Preamp constraints
        newConstraints.append(preampLabel.centerYAnchor.constraint(equalTo: preampSlider.centerYAnchor))

        //Frequencies constraints
        newConstraints.append(labelsAndFrequenciesStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100))
        newConstraints.append(labelsStackView.heightAnchor.constraint(equalTo: labelsAndFrequenciesStackView.heightAnchor))
        newConstraints.append(frequenciesScrollView.heightAnchor.constraint(equalTo: labelsAndFrequenciesStackView.heightAnchor))
        newConstraints.append(frequenciesStackView.heightAnchor.constraint(equalTo: frequenciesScrollView.heightAnchor))
        newConstraints.append(frequenciesStackView.centerYAnchor.constraint(equalTo: frequenciesScrollView.centerYAnchor))
        newConstraints.append(frequenciesStackView.leadingAnchor.constraint(equalTo: frequenciesScrollView.leadingAnchor))
        for eqFrequency in eqFrequencies {
            newConstraints.append(eqFrequency.stack.heightAnchor.constraint(equalTo: frequenciesStackView.heightAnchor))
            newConstraints.append(eqFrequency.stack.widthAnchor.constraint(greaterThanOrEqualToConstant: 40))
        }

        //SnapBands constraints
        newConstraints.append(snapBandLabel.centerYAnchor.constraint(equalTo: snapBandSwitch.centerYAnchor))

        NSLayoutConstraint.activate(newConstraints)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        frequenciesScrollView.contentSize = frequenciesStackView.frame.size
    }

    private func setupFrequenciesStackView() {

        labelsAndFrequenciesStackView.addArrangedSubview(labelsStackView)
        frequenciesStackView.translatesAutoresizingMaskIntoConstraints = false
        frequenciesStackView.axis = .horizontal
        frequenciesStackView.alignment = .leading
        frequenciesStackView.distribution = .fill
        frequenciesStackView.spacing = 5

        for eqFrequency in eqFrequencies {
            eqFrequency.slider.addTarget(self, action: #selector(sliderDidChangeValue), for: .valueChanged)
            eqFrequency.slider.addTarget(self, action: #selector(sliderWillChangeValue), for: .touchDown)
            eqFrequency.slider.addTarget(self, action: #selector(sliderDidDrag), for: .touchDragInside)
            frequenciesStackView.addArrangedSubview(eqFrequency.stack)
        }

        frequenciesScrollView.addSubview(frequenciesStackView)

        labelsAndFrequenciesStackView.addArrangedSubview(frequenciesScrollView)
    }

    @objc func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        presetsLabel.textColor = PresentationTheme.current.colors.cellTextColor
        presetsPicker.tintColor = PresentationTheme.current.colors.cellTextColor
        preampLabel.textColor = PresentationTheme.current.colors.cellTextColor
        preampSlider.tintColor = PresentationTheme.current.colors.orangeUI
        plus20Label.textColor = PresentationTheme.current.colors.cellTextColor
        zeroLabel.textColor = PresentationTheme.current.colors.cellTextColor
        minus20Label.textColor = PresentationTheme.current.colors.cellTextColor
        snapBandLabel.textColor = PresentationTheme.current.colors.cellTextColor

        for eqFrequency in eqFrequencies {
            eqFrequency.currentValueLabel.textColor = PresentationTheme.current.colors.cellTextColor
            eqFrequency.slider.tintColor = PresentationTheme.current.colors.orangeUI
            eqFrequency.frequencyLabel.textColor = PresentationTheme.current.colors.cellTextColor
        }
    }

    @objc func reloadData() {
        if let delegate = delegate {
            preampSlider.value = Float(delegate.preAmplification)

            for (i, eqFrequency) in eqFrequencies.enumerated() {
                eqFrequency.slider.value = Float(delegate.amplification(ofBand: UInt32(i)))
                eqFrequency.currentValueLabel.text = "\(Double(Int(eqFrequency.slider.value * 100)) / 100)"
            }
        }
    }
}

// MARK: - Slider events

extension EqualizerView {
    @objc func preampSliderDidChangeValue(sender: UISlider) {
        delegate?.preAmplification = CGFloat(sender.value)
        UIDelegate?.equalizerViewReceivedUserInput()
    }

    @objc func sliderWillChangeValue(sender: UISlider) {
        oldValues.removeAll()
        for eqFrequency in eqFrequencies {
            oldValues.append(eqFrequency.slider.value)
        }
    }

    @objc func sliderDidChangeValue(sender: UISlider) {
        delegate?.setAmplification(CGFloat(sender.value), forBand: UInt32(sender.tag))
        UIDelegate?.equalizerViewReceivedUserInput()
    }

    @objc func sliderDidDrag(sender: UISlider) {
        let index = sender.tag

        if snapBandSwitch.isOn {
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

        if snapBandSwitch.isOn {
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
    }

    @objc func resetEqualizer() {
        for eqFrequency in eqFrequencies {
            eqFrequency.slider.value = 0
            sliderDidChangeValue(sender: eqFrequency.slider.slider)
            eqFrequency.currentValueLabel.text = "0.0"
        }
    }
}

// MARK: - UIPickerView

extension EqualizerView: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let count = delegate?.equalizerProfiles().count {
            return count + 1
        } else {
            return 0
        }
    }

    private func stringForRow(_ row: Int) -> String {
        if row == 0 {
            return NSLocalizedString("OFF", comment: "")
        } else if let equalizerProfiles = delegate?.equalizerProfiles() as? [NSString] {
            return String(equalizerProfiles.objectAtIndex(index: row - 1) ?? "")
        } else {
            return ""
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return stringForRow(row)
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: stringForRow(row),
                                  attributes: [NSAttributedString.Key.foregroundColor: PresentationTheme.current.colors.cellTextColor])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.resetEqualizer(fromProfile: UInt32(row))
        reloadData()
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
}

// MARK: - EqualizerViewUIDelegate

@objc protocol EqualizerViewUIDelegate {
    @objc func equalizerViewReceivedUserInput()
}
