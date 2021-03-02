/*****************************************************************************
* SettingsCell.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
*
* Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import UIKit

protocol SectionType: CustomStringConvertible {
    var containsSwitch: Bool { get }
    var subtitle: String? { get }
    var preferenceKey: String? { get }
}

protocol PasscodeActivateDelegate: AnyObject {
    func passcodeLockSwitchOn(state: Bool)
}

protocol MedialibraryHidingActivateDelegate: AnyObject {
    func medialibraryHidingLockSwitchOn(state: Bool)
}

protocol MediaLibraryBackupActivateDelegate: AnyObject {
    func mediaLibraryBackupActivateSwitchOn(state: Bool)
}

protocol MediaLibraryDisableGroupingDelegate: AnyObject {
    func medialibraryDisableGroupingSwitchOn(state: Bool)
}

class SettingsCell: UITableViewCell {

    private let userDefaults = UserDefaults.standard
    private let notificationCenter = NotificationCenter.default
    private var localeDictionary = NSDictionary()
    var showsActivityIndicator = false
    weak var passcodeSwitchDelegate: PasscodeActivateDelegate?
    weak var medialibraryHidingSwitchDelegate: MedialibraryHidingActivateDelegate?
    weak var mediaLibraryBackupSwitchDelegate: MediaLibraryBackupActivateDelegate?
    weak var medialibraryDisableGroupingSwitchDelegate: MediaLibraryDisableGroupingDelegate?

    lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = PresentationTheme.current.colors.orangeUI
        switchControl.addTarget(self,
                                action: #selector(handleSwitchAction),
                                for: .valueChanged)
        return switchControl
    }()

    let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    let mainLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textColor = PresentationTheme.current.colors.cellTextColor
        label.font = .preferredFont(forTextStyle: .callout) //16pt default
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote) //13pt default
        label.numberOfLines = 2
        label.textColor = PresentationTheme.current.colors.cellDetailTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    var sectionType: SectionType? {
        didSet {
            guard let sectionType = sectionType else {
                assertionFailure("No Section Type provided")
                return
            }
            mainLabel.text = localeDictionary[sectionType.description] as? String
            if let subtitle = sectionType.subtitle, let subtitleTextLocalized = localeDictionary[subtitle] as? String {
                //Handles No Value (No user-defaults value set) case
                subtitleLabel.text = subtitleTextLocalized
            }
            else {
                subtitleLabel.text = sectionType.subtitle
            }
            switchControl.isHidden = !sectionType.containsSwitch
            if switchControl.isHidden {
                accessoryView = .none
                accessoryType = .disclosureIndicator
                selectionStyle = .default
            }
            else {
                //When Media Library is adding or removing files to device backup
                //We show a Activity Indicator instead of a switch while the process
                //is going on. On completion, we show the switch again
                if showsActivityIndicator && sectionType.preferenceKey == kVLCSettingBackupMediaLibrary {
                    activityIndicator.isHidden = false
                    accessoryView = .none
                    selectionStyle = .none
                } else {
                    activityIndicator.isHidden = true
                    accessoryView = switchControl
                    selectionStyle = .none
                }
            }
            updateSwitch()
            updateSubtitle()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundColor = .clear //Required to prevent theme mismatch during themeDidChange Notification
        activityIndicator.isHidden = true

        // Reset to default colors.
        themeDidChange()
    }

    private func setup() {
        guard let localeDict = getLocaleDictionary() else { return }
        localeDictionary = localeDict
        setupView()
        setupObservers()
        themeDidChange()
    }

    private func setupView() {

        var guide: LayoutAnchorContainer = self
        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        addSubview(stackView)
        addSubview(activityIndicator)
        stackView.addArrangedSubview(mainLabel)
        stackView.addArrangedSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            stackView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -10),
            stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -70),
            activityIndicator.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -30),
            activityIndicator.centerYAnchor.constraint(equalTo: stackView.centerYAnchor)
        ])
        activityIndicator.isHidden = true
    }

    private func setupObservers() {
        notificationCenter.addObserver(self,
                                       selector: #selector(themeDidChange),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(updateValues),
                                       name: UserDefaults.didChangeNotification,
                                       object: nil)
    }

    @objc func handleSwitchAction(sender: UISwitch) {
        guard let key = sectionType?.preferenceKey else { return }
        userDefaults.set(sender.isOn ? true : false, forKey: key)
        if sectionType?.preferenceKey == kVLCSettingPasscodeOnKey {
            passcodeSwitchDelegate?.passcodeLockSwitchOn(state: sender.isOn)
        } else if sectionType?.preferenceKey == kVLCSettingHideLibraryInFilesApp {
            medialibraryHidingSwitchDelegate?.medialibraryHidingLockSwitchOn(state: sender.isOn)
        } else if sectionType?.preferenceKey == kVLCSettingBackupMediaLibrary {
            mediaLibraryBackupSwitchDelegate?.mediaLibraryBackupActivateSwitchOn(state: sender.isOn)
        } else if sectionType?.preferenceKey == kVLCSettingsDisableGrouping {
            medialibraryDisableGroupingSwitchDelegate?.medialibraryDisableGroupingSwitchOn(state: sender.isOn)
        }
    }

    @objc fileprivate func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        selectedBackgroundView?.backgroundColor = PresentationTheme.current.colors.mediaCategorySeparatorColor
        mainLabel.textColor = PresentationTheme.current.colors.cellTextColor
        subtitleLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        activityIndicator.color = PresentationTheme.current.colors.cellDetailTextColor
    }

    @objc private func updateValues() {
        DispatchQueue.main.async {
            self.updateSwitch()
            self.updateSubtitle()
        }
    }

    private func updateSwitch() {
        if let key = self.sectionType?.preferenceKey {
            let value = self.userDefaults.bool(forKey: key)
            self.switchControl.isOn = value ? true : false
        }
    }

    private func updateSubtitle() {
        if let subtitle = self.getSubtitle(for: self.sectionType?.preferenceKey ?? "") {
            if let localizedSubtitle = self.localeDictionary[subtitle] as? String {
                self.subtitleLabel.text = localizedSubtitle
            } else {
                self.subtitleLabel.text = subtitle
            }
        }
    }
}
