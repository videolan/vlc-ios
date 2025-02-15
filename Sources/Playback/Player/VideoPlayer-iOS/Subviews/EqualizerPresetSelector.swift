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
    let presetsTableView = UITableView()
    private let profiles: [VLCAudioEqualizer.Preset]
    var delegate: EqualizerPresetSelectorDelegate?
    private let presetTableViewReuseIdentifier = "presetTableViewReuseIdentifier"

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
    func numberOfSections(in tableView: UITableView) -> Int {
        let profilesData = UserDefaults.standard.data(forKey: kVLCCustomEqualizerProfiles)
        guard let profilesData = profilesData,
              let customProfiles = NSKeyedUnarchiver(forReadingWith: profilesData).decodeObject(forKey: "root") as? CustomEqualizerProfiles else {
            return 1
        }

        return customProfiles.profiles.isEmpty ? 1 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // We need to return the number of profiles + 1 as we fake the "Off" profile in this table view
            return profiles.count + 1
        }

        let profilesData = UserDefaults.standard.data(forKey: kVLCCustomEqualizerProfiles)
        guard let profilesData = profilesData,
              let customProfiles = NSKeyedUnarchiver(forReadingWith: profilesData).decodeObject(forKey: "root") as? CustomEqualizerProfiles else {
            return 0
        }

        return customProfiles.profiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: presetTableViewReuseIdentifier)

        let colors = PresentationTheme.darkTheme.colors
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("OFF", comment: "")
            } else if indexPath.row - 1 < profiles.count {
                cell.textLabel?.text = profiles[indexPath.row - 1].name
            }
        } else {
            let profilesData = UserDefaults.standard.data(forKey: kVLCCustomEqualizerProfiles)
            guard let profilesData = profilesData,
                  let customProfiles = NSKeyedUnarchiver(forReadingWith: profilesData).decodeObject(forKey: "root") as? CustomEqualizerProfiles else {
                return cell
            }

            cell.textLabel?.text = customProfiles.profiles[indexPath.row].name
        }

        let selectedProfileIndex = PlaybackService.sharedInstance().selectedEqualizerProfile()
        if selectedProfileIndex == indexPath {
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return NSLocalizedString("CUSTOM_EQUALIZER_PROFILES", comment: "")
        default:
            return ""
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Only custom profiles can be deleted
        return indexPath.section == 0 ? false : true
    }

    // MARK: - table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let isCustomProfile: Bool = indexPath.section == 0 ? false : true
        UserDefaults.standard.setValue(isCustomProfile, forKey: kVLCCustomProfileEnabled)
        delegate?.equalizerPresetSelector(self, didSelectPreset: indexPath.row, isCustom: isCustomProfile)
        presetsTableView.reloadData()
        toggleHiddenView()
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { _, _, _ in
            self.delegate?.equalizerPresetSelector(self, displayAlertOfType: .delete, index: indexPath)
        }

        let renameAction = UIContextualAction(style: .normal, title: nil) { _, _, _ in
            self.delegate?.equalizerPresetSelector(self, displayAlertOfType: .rename, index: indexPath)
        }

        deleteAction.image = UIImage(named: "delete")?.withRenderingMode(.alwaysTemplate)
        renameAction.image = UIImage(named: "rename")?.withRenderingMode(.alwaysTemplate)
        renameAction.backgroundColor = PresentationTheme.current.colors.orangeUI

        return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let moveUpAction = UIContextualAction(style: .normal, title: nil, handler: { _, _, _ in
            self.moveProfile(.up, at: indexPath)
            tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        })

        let moveDownAction = UIContextualAction(style: .normal, title: nil, handler: { _, _, _ in
            self.moveProfile(.down, at: indexPath)
            tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        })

        moveUpAction.image = UIImage(named: "chevronUp")
        moveDownAction.image = UIImage(named: "chevronDown")

        let actions: [UIContextualAction] = [moveUpAction, moveDownAction]
        return UISwipeActionsConfiguration(actions: actions)
    }

    // MARK: - Slider event
    @objc func preampSliderDidChangeValue(sender: UISlider) {
        delegate?.equalizerPresetSelector(self, didSetPreamp: sender.value)
        preampValueLabel.text = "\(Float(Int(preampSlider.value * 100)) / 100.0)dB"
    }

    // MARK: - Public
    func setPreampSliderValue(_ value: Float) {
        preampSlider.value = value
        preampValueLabel.text = "\(Float(Int(preampSlider.value * 100)) / 100.0)dB"
    }

    func moveProfile(_ moveIdentifier: MoveEventIdentifier, at index: IndexPath) {
        let userDefaults = UserDefaults.standard
        let profilesData = userDefaults.data(forKey: kVLCCustomEqualizerProfiles)
        guard let profilesData = profilesData,
              let customProfiles = NSKeyedUnarchiver(forReadingWith: profilesData).decodeObject(forKey: "root") as? CustomEqualizerProfiles else {
            return
        }

        if moveIdentifier == .up {
            customProfiles.moveUp(index: index.row)
        } else {
            customProfiles.moveDown(index: index.row)
        }

        userDefaults.setValue(NSKeyedArchiver.archivedData(withRootObject: customProfiles), forKey: kVLCCustomEqualizerProfiles)
    }
}

@objc protocol EqualizerPresetSelectorDelegate {
    @objc func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, didSetPreamp preamp: Float)
    @objc func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, didSelectPreset preset: Int, isCustom: Bool)
    @objc func equalizerPresetSelector(_ equalizerPresetSelector: EqualizerPresetSelector, displayAlertOfType type: EqualizerEditActionsIdentifier, index: IndexPath)
}
