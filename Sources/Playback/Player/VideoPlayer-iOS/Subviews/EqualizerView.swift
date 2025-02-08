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
        let slider: VerticalSliderControl
        let frequencyLabel: UILabel

        init(frequency: Int, index: Int) {
            stack = UIStackView()
            currentValueLabel = UILabel()
            slider = VerticalSliderControl()
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
            slider.range = -20...20
            slider.setValue(0, animated: false)
            slider.thumbImage = UIImage(named: "sliderKnob")
            slider.trackWidth = 4
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
            if let profiles = delegate?.equalizerProfiles() as? [VLCAudioEqualizer.Preset] {
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
    private let saveButton = UIButton()
    private let resetButton = UIButton()

    private var eqFrequencies: [EqualizerFrequency] = []
    private var valuesOnShow: [Float] = []
    private var oldValues: [Float] = []

    private var parentPopup: PopupView?

    private var playbackService = PlaybackService.sharedInstance()

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
        shouldDisplaySaveButton(false)
        resetValuesOnShow()
        reloadData()
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
        saveButton.setTitle(NSLocalizedString("BUTTON_SAVE", comment: ""), for: .normal)
        saveButton.addTarget(self, action: #selector(saveNewProfile), for: .touchUpInside)
        saveButton.setContentHuggingPriority(.required, for: .horizontal)

        resetButton.setTitle(NSLocalizedString("BUTTON_RESET", comment: ""), for: .normal)
        resetButton.addTarget(self, action: #selector(resetEqualizer), for: .touchUpInside)
        resetButton.setContentHuggingPriority(.required, for: .vertical)
        resetButton.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(stackView)
        setupFrequenciesStackView()
        setupConstraints()
        setupTheme()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resetEqualizer),
                                               name: NSNotification.Name(VLCPlaybackServicePlaybackDidStop),
                                               object: nil)
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
        saveButton.setTitleColor(colors.orangeUI, for: .normal)
        resetButton.setTitleColor(colors.orangeUI, for: .normal)

        for eqFrequency in eqFrequencies {
            eqFrequency.currentValueLabel.textColor = colors.cellTextColor
            eqFrequency.slider.minimumTrackLayerColor = colors.orangeUI.cgColor
            eqFrequency.slider.maximumTrackLayerColor = UIColor(white: 1, alpha: 0.25).cgColor
            eqFrequency.frequencyLabel.textColor = colors.cellTextColor
        }
    }

    @objc func reloadData() {
        if let delegate = delegate {
            presetSelectorView?.setPreampSliderValue(Float(playbackService.preAmplification))

            for (i, eqFrequency) in eqFrequencies.enumerated() {
                eqFrequency.slider.setValue(Float(delegate.amplification(ofBand: UInt32(i))), animated: false)
                eqFrequency.currentValueLabel.text = "\(Double(Int(eqFrequency.slider.value * 100)) / 100)"
            }
        }
    }
}

// MARK: - Slider events

extension EqualizerView {
    @objc func sliderWillChangeValue(sender: VerticalSliderControl) {
        oldValues.removeAll()
        for eqFrequency in eqFrequencies {
            oldValues.append(eqFrequency.slider.value)
        }
    }

    @objc func sliderDidChangeValue(sender: VerticalSliderControl) {
        playbackService.setAmplification(CGFloat(sender.value), forBand: UInt32(sender.tag))
        shouldDisplaySaveButton(true)
        UIDelegate?.equalizerViewShowIcon()
    }

    @objc func sliderDidDrag(sender: VerticalSliderControl) {
        let index = sender.tag

        if snapBandsSwitch.isOn {
            let delta = sender.value - oldValues[index]

            for i in 0..<eqFrequencies.count {
                if i != index {
                    if let currentSlider = eqFrequencies.objectAtIndex(index: i),
                       let oldValue = oldValues.objectAtIndex(index: i) {
                        let delta_index = Float(abs(i - index))
                        let newValue = oldValue + delta / Float(pow(delta_index, 3) + 1)
                        currentSlider.slider.setValue(newValue, animated: false)
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

// MARK: - Buttons event

extension EqualizerView {
    @objc func saveNewProfile() {
        let alertController = UIAlertController(title: NSLocalizedString("CUSTOM_EQUALIZER_ALERT_TITLE", comment: ""),
                                                message: NSLocalizedString("CUSTOM_EQUALIZER_ALERT_MESSAGE", comment: ""),
                                                preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.text = NSLocalizedString("DEFAULT_PROFILE_NAME", comment: "")
        }

        let saveAction = UIAlertAction(title: NSLocalizedString("BUTTON_SAVE", comment: ""), style: .default) { _ in
            let name: String = alertController.textFields?.first?.text ?? NSLocalizedString("DEFAULT_PROFILE_NAME", comment: "")
            var frequencies: [Float] = []

            for frequency in self.eqFrequencies {
                frequencies.append(frequency.slider.value)
            }

            let preAmplification = self.playbackService.preAmplification

            let customProfile = CustomEqualizerProfile(name: name, preAmpLevel: Float(preAmplification), frequencies: frequencies)
            let encodedProfiles = UserDefaults.standard.data(forKey: kVLCCustomEqualizerProfiles)
            var customProfiles: CustomEqualizerProfiles

            if let encodedProfiles = encodedProfiles,
               let profiles = NSKeyedUnarchiver(forReadingWith: encodedProfiles).decodeObject(forKey: "root") as? CustomEqualizerProfiles {
                profiles.profiles.append(customProfile)
                customProfiles = profiles
            } else {
                customProfiles = CustomEqualizerProfiles(profiles: [customProfile])
            }

            let index = customProfiles.profiles.count - 1
            let userDefaults = UserDefaults.standard
            userDefaults.setValue(NSKeyedArchiver.archivedData(withRootObject: customProfiles), forKey: kVLCCustomEqualizerProfiles)
            userDefaults.setValue(true, forKey: kVLCCustomProfileEnabled)
            userDefaults.setValue(false, forKey: kVLCSettingEqualizerProfileDisabled)
            userDefaults.setValue(index, forKey: kVLCSettingEqualizerProfile)

            self.presetSelectorView?.presetsTableView.reloadData()
            self.shouldDisplaySaveButton(false)
            self.hideEqualizerIconIfNeeded()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        UIDelegate?.displayAlert(alertController)
    }

    @objc func resetEqualizer() {
        let userDefaults = UserDefaults.standard
        let isEqualizerDisabled = userDefaults.bool(forKey: kVLCSettingEqualizerProfileDisabled)
        let isCustomProfile = userDefaults.bool(forKey: kVLCCustomProfileEnabled)

        let profile: Int
        if !isCustomProfile {
            profile = isEqualizerDisabled ? 0 : userDefaults.integer(forKey: kVLCSettingEqualizerProfile) + 1
            delegate?.resetEqualizer(fromProfile: UInt32(profile))
        } else {
            profile = userDefaults.integer(forKey: kVLCSettingEqualizerProfile)
            applyCustomProfile(profile)
        }

        reloadData()
        hideEqualizerIconIfNeeded()
        shouldDisplaySaveButton(false)
    }

    private func hideEqualizerIconIfNeeded() {
        UIDelegate?.equalizerViewHideIcon()
    }

    private func applyCustomProfile(_ index: Int) {
        let userDefaults = UserDefaults.standard
        let encodedData = userDefaults.data(forKey: kVLCCustomEqualizerProfiles)

        guard let encodedData = encodedData,
              let customProfiles = NSKeyedUnarchiver(forReadingWith: encodedData).decodeObject(forKey: "root") as? CustomEqualizerProfiles,
              index < customProfiles.profiles.count else {
            return
        }

        let selectedProfile = customProfiles.profiles[index]
        playbackService.preAmplification = CGFloat(selectedProfile.preAmpLevel)

        for (bandIndex, frequency) in selectedProfile.frequencies.enumerated() {
            playbackService.setAmplification(CGFloat(frequency), forBand: UInt32(bandIndex))
        }

        userDefaults.setValue(index, forKey: kVLCSettingEqualizerProfile)
        userDefaults.setValue(false, forKey: kVLCSettingEqualizerProfileDisabled)
        userDefaults.setValue(true, forKey: kVLCCustomProfileEnabled)
    }

    private func shouldDisplaySaveButton(_ display: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.saveButton.isHidden = !display
        }
    }
}

// MARK: - EqualizerPresetSelectorDelegate

extension EqualizerView: EqualizerPresetSelectorDelegate {
    func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, didSetPreamp preamp: Float) {
        playbackService.preAmplification = CGFloat(preamp)
        shouldDisplaySaveButton(true)
    }

    func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, didSelectPreset preset: Int, isCustom: Bool) {
        if !isCustom {
            delegate?.resetEqualizer(fromProfile: UInt32(preset))
        } else {
            applyCustomProfile(preset)
        }

        shouldDisplaySaveButton(false)
        reloadData()
    }

    func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, displayAlertOfType type: EqualizerEditActionsIdentifier, index: IndexPath) {
        let title = type == .delete ? NSLocalizedString("DELETE_CUSTOM_PROFILE_TITLE", comment: "") : NSLocalizedString("RENAME_CUSTOM_PROFILE_TITLE", comment: "")
        let message = type == .delete ? NSLocalizedString("DELETE_CUSTOM_PROFILE_MESSAGE", comment: "") : ""
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let action: UIAlertAction

        if type == .delete {
            action = UIAlertAction(title: NSLocalizedString("BUTTON_DELETE", comment: ""), style: .destructive) { _ in
                let customEncodedProfiles = UserDefaults.standard.data(forKey: kVLCCustomEqualizerProfiles)
                guard let customEncodedProfiles = customEncodedProfiles,
                      var customProfiles = NSKeyedUnarchiver(forReadingWith: customEncodedProfiles).decodeObject(forKey: "root") as? CustomEqualizerProfiles,
                      index.row < customProfiles.profiles.count else {
                    return
                }

                customProfiles.profiles.remove(at: index.row)
                UserDefaults.standard.setValue(NSKeyedArchiver.archivedData(withRootObject: customProfiles), forKey: kVLCCustomEqualizerProfiles)
                self.presetSelectorView?.presetsTableView.reloadData()
            }
        } else {
            alertController.addTextField { textField in
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.text = self.presetSelectorView?.presetsTableView.cellForRow(at: index)?.textLabel?.text
            }

            action = UIAlertAction(title: NSLocalizedString("BUTTON_RENAME", comment: ""), style: .default) { _ in
                let customEncodedProfiles = UserDefaults.standard.data(forKey: kVLCCustomEqualizerProfiles)
                guard let customEncodedProfiles = customEncodedProfiles,
                      let customProfiles = NSKeyedUnarchiver(forReadingWith: customEncodedProfiles).decodeObject(forKey: "root") as? CustomEqualizerProfiles,
                      index.row < customProfiles.profiles.count else {
                    return
                }

                guard let newName = alertController.textFields?.first?.text,
                      !newName.isEmpty else {
                    return
                }

                customProfiles.profiles[index.row].name = newName
                UserDefaults.standard.setValue(NSKeyedArchiver.archivedData(withRootObject: customProfiles), forKey: kVLCCustomEqualizerProfiles)
                self.presetSelectorView?.presetsTableView.reloadData()
            }
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel)

        alertController.addAction(action)
        alertController.addAction(cancelAction)

        UIDelegate?.displayAlert(alertController)
    }
}

// MARK: - PopupViewAccessoryViewDelegate

extension EqualizerView: PopupViewAccessoryViewsDelegate {
    func popupViewAccessoryView(_ popupView: PopupView) -> [UIView] {
        if parentPopup == nil {
            parentPopup = popupView
        }

        return [saveButton, resetButton]
    }
}

// MARK: - EqualizerViewDelegate

@objc protocol EqualizerViewDelegate {
    @objc func amplification(ofBand index: UInt32) -> CGFloat
    @objc func equalizerProfiles() -> NSArray
    @objc func resetEqualizer(fromProfile profile: UInt32)
    @objc func numberOfBands() -> UInt32
    @objc func frequencyOfBand(atIndex index: UInt32) -> CGFloat
}

// MARK: - EqualizerViewUIDelegate

protocol EqualizerViewUIDelegate: AnyObject {
    func equalizerViewShowIcon()
    func equalizerViewHideIcon()
    func displayAlert(_ alert: UIAlertController)
}
