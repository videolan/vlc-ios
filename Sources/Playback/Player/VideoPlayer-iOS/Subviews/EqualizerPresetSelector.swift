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

class EqualizerPresetSelector: SpoilerButton, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    private let hiddenView = UIView()
    private let preampLabel = UILabel()
    private let preampSlider = UISlider()
    private let preampValueLabel = UILabel()
    private let preampStackView = UIStackView()
    private let presetsTableView = UITableView()
    private let profiles: [VLCAudioEqualizer.Preset]
    var delegate: EqualizerPresetSelectorDelegate?
    private let presetTableViewReuseIdentifier = "presetTableViewReuseIdentifier"
    var selectedProfileIndex = Int.init(0)

    // MARK: - Init
    required init(coder: NSCoder) {
        self.profiles = []
        super.init(coder: coder)
    }

    init(profiles: [VLCAudioEqualizer.Preset]) {
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

    private func setupTableView() {
        presetsTableView.translatesAutoresizingMaskIntoConstraints = false
        presetsTableView.backgroundColor = PresentationTheme.darkTheme.colors.background
        presetsTableView.dataSource = self
        presetsTableView.delegate = self
    }

    private func setupViews() {
        setupPreampViews()
        setupTableView()

        hiddenView.translatesAutoresizingMaskIntoConstraints = false
        hiddenView.addSubview(preampStackView)
        hiddenView.addSubview(presetsTableView)

        let newConstraints = [
            preampStackView.topAnchor.constraint(equalTo: hiddenView.topAnchor),
            preampStackView.leadingAnchor.constraint(equalTo: hiddenView.leadingAnchor),
            preampStackView.trailingAnchor.constraint(equalTo: hiddenView.trailingAnchor),
            presetsTableView.topAnchor.constraint(equalTo: preampStackView.bottomAnchor, constant: 10),
            presetsTableView.leadingAnchor.constraint(equalTo: hiddenView.leadingAnchor),
            presetsTableView.trailingAnchor.constraint(equalTo: hiddenView.trailingAnchor),
            presetsTableView.bottomAnchor.constraint(equalTo: hiddenView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(newConstraints)

        setTitle(NSLocalizedString("PRESET_PREAMP_SETTING", comment: ""))
        setHiddenView(with: hiddenView)

        presetsTableView.reloadData()
    }

    // MARK: - table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: presetTableViewReuseIdentifier)

        let colors = PresentationTheme.darkTheme.colors
        if indexPath.row == 0 {
            cell.textLabel?.text = NSLocalizedString("OFF", comment: "")
        } else {
            cell.textLabel?.text = profiles[indexPath.row].name
        }

        if selectedProfileIndex == indexPath.row {
            cell.textLabel?.textColor = colors.orangeUI
            cell.textLabel?.font = .boldSystemFont(ofSize: 16)
        } else {
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = .systemFont(ofSize: 16)
        }
        cell.backgroundColor = colors.cellBackgroundA
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        return cell
    }

    // MARK: - table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        delegate?.equalizerPresetSelector(self, didSelectPreset: indexPath.row)
        toggleHiddenView()
    }

    @objc func preampSliderDidChangeValue(sender: UISlider) {
        delegate?.equalizerPresetSelector(self, didSetPreamp: sender.value)
        preampValueLabel.text = "\(Float(Int(preampSlider.value * 100)) / 100.0)dB"
    }

    // MARK: - Public
    func setPreampSliderValue(_ value: Float) {
        preampSlider.value = value
        preampValueLabel.text = "\(Float(Int(preampSlider.value * 100)) / 100.0)dB"
    }

    func setSelectedProfileValue(_ value: UInt32) {
        selectedProfileIndex = Int(value)
        presetsTableView.reloadData()
    }
}

@objc protocol EqualizerPresetSelectorDelegate {
    @objc func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, didSetPreamp preamp: Float)
    @objc func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, didSelectPreset preset: Int)
}
