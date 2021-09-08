/*****************************************************************************
* EqualizerPresetSelector.swift
*
* Copyright © 2021 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import UIKit

private class EqualizerPresetButton: UIButton {
    let id: Int
    private let title: String

    // MARK: - Init
    init(id: Int, title: String) {
        self.id = id
        self.title = title
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        self.id = -1
        self.title = ""
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        setTitle(title, for: .normal)
        titleLabel?.font = .boldSystemFont(ofSize: 16)
        setTitleColor(PresentationTheme.current.colors.orangeUI, for: .normal)
    }
}

private class EqualizerPresetButtonsFactory {
    static func generate(with profiles: [NSString]) -> [EqualizerPresetButton] {
        var buttons: [EqualizerPresetButton] = []

        for (i, profile) in profiles.enumerated() {
            let button = EqualizerPresetButton(id: i, title: String(profile))
            buttons.append(button)
        }

        return buttons
    }
}

class EqualizerPresetSelector: SpoilerButton {
    // MARK: - Properties
    private let hiddenView = UIView()
    private let preampLabel = UILabel()
    private let preampSlider = UISlider()
    private let preampValueLabel = UILabel()
    private let preampStackView = UIStackView()
    private let presetsScrollView = UIScrollView()
    private let presetsStackView = UIStackView()
    private let profiles: [NSString]
    var delegate: EqualizerPresetSelectorDelegate?

    // MARK: - Init
    required init(coder: NSCoder) {
        self.profiles = []
        super.init(coder: coder)
    }

    init(profiles: [NSString]) {
        self.profiles = profiles
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        setupViews()
    }

    // MARK: - Setup
    private func setupPreampViews() {
        preampStackView.axis = .horizontal
        preampStackView.alignment = .leading
        preampStackView.distribution = .fill
        preampStackView.spacing = 10
        preampStackView.translatesAutoresizingMaskIntoConstraints = false

        preampStackView.addArrangedSubview(preampLabel)
        preampStackView.addArrangedSubview(preampSlider)
        preampStackView.addArrangedSubview(preampValueLabel)

        preampLabel.text = NSLocalizedString("PREAMP", comment: "")
        preampLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        preampLabel.setContentHuggingPriority(.required, for: .horizontal)
        preampLabel.translatesAutoresizingMaskIntoConstraints = false
        preampLabel.textColor = PresentationTheme.darkTheme.colors.cellTextColor

        preampSlider.maximumValue = 20.0
        preampSlider.value = 0.0
        preampSlider.minimumValue = -20.0
        preampSlider.setThumbImage(UIImage(named: "sliderKnob"), for: .normal)
        preampSlider.clipsToBounds = true
        preampSlider.tintColor = PresentationTheme.current.colors.orangeUI
        preampSlider.translatesAutoresizingMaskIntoConstraints = false
        preampSlider.addTarget(self, action: #selector(preampSliderDidChangeValue), for: .valueChanged)


        preampValueLabel.text = "\(Float(Int(preampSlider.value * 100)) / 100.0)dB"
        preampValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        preampValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        preampValueLabel.translatesAutoresizingMaskIntoConstraints = false
        preampValueLabel.textColor = PresentationTheme.darkTheme.colors.cellTextColor
    }

    private func setupStackView() {
        presetsStackView.axis = .vertical
        presetsStackView.alignment = .top
        presetsStackView.distribution = .fill
        presetsStackView.spacing = 0
        presetsStackView.translatesAutoresizingMaskIntoConstraints = false

        let buttons = EqualizerPresetButtonsFactory.generate(with: profiles)
        for button in buttons {
            presetsStackView.addArrangedSubview(button)
            button.addTarget(self, action: #selector(didSelectPreset(sender:)), for: .touchUpInside)
            button.widthAnchor.constraint(equalTo: presetsStackView.widthAnchor).isActive = true
        }
    }

    private func setupScrollView() {
        presetsScrollView.translatesAutoresizingMaskIntoConstraints = false
        presetsScrollView.indicatorStyle = .white
        presetsScrollView.addSubview(presetsStackView)

        let newConstraints = [
            presetsStackView.topAnchor.constraint(equalTo: presetsScrollView.topAnchor),
            presetsStackView.bottomAnchor.constraint(equalTo: presetsScrollView.bottomAnchor),
            presetsStackView.widthAnchor.constraint(equalTo: presetsScrollView.widthAnchor),
            presetsStackView.centerXAnchor.constraint(equalTo: presetsScrollView.centerXAnchor)
        ]
        NSLayoutConstraint.activate(newConstraints)
    }

    private func setupViews() {
        setupPreampViews()
        setupStackView()
        setupScrollView()

        hiddenView.translatesAutoresizingMaskIntoConstraints = false
        hiddenView.addSubview(preampStackView)
        hiddenView.addSubview(presetsScrollView)

        let newConstraints = [
            preampStackView.topAnchor.constraint(equalTo: hiddenView.topAnchor),
            preampStackView.leadingAnchor.constraint(equalTo: hiddenView.leadingAnchor),
            preampStackView.trailingAnchor.constraint(equalTo: hiddenView.trailingAnchor),
            presetsScrollView.topAnchor.constraint(equalTo: preampStackView.bottomAnchor, constant: 10),
            presetsScrollView.leadingAnchor.constraint(equalTo: hiddenView.leadingAnchor),
            presetsScrollView.trailingAnchor.constraint(equalTo: hiddenView.trailingAnchor),
            presetsScrollView.bottomAnchor.constraint(equalTo: hiddenView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(newConstraints)

        setTitle(NSLocalizedString("PRESET_PREAMP_SETTING", comment: ""))
        setHiddenView(with: hiddenView)
    }

    @objc func preampSliderDidChangeValue(sender: UISlider) {
        delegate?.equalizerPresetSelector(self, didSetPreamp: sender.value)
        preampValueLabel.text = "\(Float(Int(preampSlider.value * 100)) / 100.0)dB"
    }

    @objc private func didSelectPreset(sender: EqualizerPresetButton) {
        delegate?.equalizerPresetSelector(self, didSelectPreset: sender.id)
        toggleHiddenView()
    }

    // MARK: - Public
    func setPreampSliderValue(_ value: Float) {
        preampSlider.value = value
        preampValueLabel.text = "\(Float(Int(preampSlider.value * 100)) / 100.0)dB"
    }
}

@objc protocol EqualizerPresetSelectorDelegate {
    @objc func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, didSetPreamp preamp: Float)
    @objc func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, didSelectPreset preset: Int)
}
