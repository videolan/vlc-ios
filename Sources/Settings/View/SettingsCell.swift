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

protocol SettingsCellDelegate: AnyObject {
    func settingsCellDidChangeSwitchState(preferenceKey: String, isOn: Bool)
}

class SettingsCell: UITableViewCell {

    private var userDefaults: UserDefaults { UserDefaults.standard }
    private var notificationCenter: NotificationCenter { NotificationCenter.default }

    internal var settingsBundle = Bundle()

    internal weak var delegate: SettingsCellDelegate?

    lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        let colors = PresentationTheme.current.colors
        switchControl.onTintColor = colors.orangeUI
        switchControl.addTarget(self,
                                action: #selector(handleSwitchAction),
                                for: .valueChanged)
        return switchControl
    }()

    lazy var infoButton: UIButton = {
        var infoButton = UIButton()
        let buttonType: UIButton.ButtonType = PresentationTheme.current.isDark ? .infoDark : .infoLight
        infoButton = UIButton(type: buttonType)
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchDown)
        return infoButton
    }()

    let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    let mainLabel: UILabel = {
        let label = UILabel()
        let colors = PresentationTheme.current.colors
        label.numberOfLines = 2
        label.textColor = colors.cellTextColor
        label.font = .preferredFont(forTextStyle: .callout) //16pt default
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let subtitleLabel: UILabel = {
        let label = UILabel()
        let colors = PresentationTheme.current.colors
        label.font = .preferredFont(forTextStyle: .footnote) //13pt default
        label.numberOfLines = 2
        label.textColor = colors.cellDetailTextColor
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

    var settingsItem: SettingsItem? {
        didSet {
            guard let settingsItem = settingsItem else {
                return
            }

            mainLabel.text = settingsBundle.localizedString(forKey: settingsItem.title, value: settingsItem.title, table: "Root")

            mainLabel.textColor = settingsItem.emphasizedTitle
                ? PresentationTheme.current.colors.orangeUI
                : PresentationTheme.current.colors.cellTextColor

            if let subtitle = settingsItem.subtitle {
                //Handles No Value (No user-defaults value set) case
                subtitleLabel.text = settingsBundle.localizedString(forKey: subtitle, value: subtitle, table: "Root")
            }
            else {
                subtitleLabel.text = settingsItem.subtitle
            }

            switch settingsItem.action {
            case .isLoading:
                switchControl.isHidden = true
                infoButton.isHidden = true
                activityIndicator.isHidden = false
                accessoryView = .none
                accessoryType = .none
                selectionStyle = .none
            case .toggle(_):
                switchControl.isHidden = false
                infoButton.isHidden = true
                activityIndicator.isHidden = true
                accessoryView = switchControl
                accessoryType = .none
                selectionStyle = .none
            case .showActionSheet(_, _, let hasInfo):
                switchControl.isHidden = true
                infoButton.isHidden = !hasInfo
                activityIndicator.isHidden = true
                accessoryView = .none
                accessoryType = .disclosureIndicator
                selectionStyle = .default
            case .donation:
                switchControl.isHidden = true
                infoButton.isHidden = true
                activityIndicator.isHidden = true
                accessoryView = .none
                accessoryType = .disclosureIndicator
                selectionStyle = .default
            case .openPrivacySettings:
                switchControl.isHidden = true
                infoButton.isHidden = true
                activityIndicator.isHidden = true
                accessoryView = .none
                accessoryType = .disclosureIndicator
                selectionStyle = .default
            case .forceRescanAlert, .exportMediaLibrary, .displayResetAlert:
                switchControl.isHidden = true
                infoButton.isHidden = true
                activityIndicator.isHidden = true
                accessoryView = .none
                accessoryType = .none
                selectionStyle = .default
            }

            if !activityIndicator.isHidden {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
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

        settingsItem = nil
        delegate = nil
    }

    private func setup() {
        setupView()
        setupObservers()
        themeDidChange()
    }

    private func setupView() {
        addSubview(stackView)
        addSubview(activityIndicator)
        stackView.addArrangedSubview(mainLabel)
        stackView.addArrangedSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -70),
            activityIndicator.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -30),
            activityIndicator.centerYAnchor.constraint(equalTo: stackView.centerYAnchor)
        ])
        activityIndicator.isHidden = true

        addSubview(infoButton)
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoButton.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            infoButton.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -40)
        ])
        infoButton.isHidden = true
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
        guard let settingsItem = settingsItem else { return }

        switch settingsItem.action {
        case .toggle(let preferenceKey):
            delegate?.settingsCellDidChangeSwitchState(preferenceKey: preferenceKey, isOn: sender.isOn)

        default:
            break
        }
    }

    @objc fileprivate func themeDidChange() {
        let colors = PresentationTheme.current.colors
        backgroundColor = colors.background
        selectedBackgroundView?.backgroundColor = colors.mediaCategorySeparatorColor
        mainLabel.textColor = colors.cellTextColor
        subtitleLabel.textColor = colors.cellDetailTextColor
        activityIndicator.color = colors.cellDetailTextColor
        guard #available(iOS 13, *) else {
            backgroundColor = colors.background
            mainLabel.backgroundColor = backgroundColor
            subtitleLabel.backgroundColor = backgroundColor
            activityIndicator.backgroundColor = backgroundColor
            switchControl.backgroundColor = backgroundColor
            return
        }
    }

    @objc func infoTapped(sender: UIButton) {
        guard let settingSpecifier = getSettingsSpecifier(for: (settingsItem?.preferenceKey)!) else {
            return
        }

        let title = settingsBundle.localizedString(forKey: settingSpecifier.title, value: settingSpecifier.title, table: "Root")
        let alert = UIAlertController(title: title,
                                      message: settingsBundle.localizedString(forKey: settingSpecifier.infobuttonvalue,
                                                                              value: settingSpecifier.infobuttonvalue,
                                                                              table: "Root"),
                                      preferredStyle: .actionSheet)
        let donetitle = NSLocalizedString("BUTTON_DONE", comment: "")
        alert.addAction(UIAlertAction(title: donetitle, style: .cancel, handler: nil))

        // Set up the popoverPresentationController to avoid crash issues on iPad.
        alert.popoverPresentationController?.sourceView = self
        alert.popoverPresentationController?.permittedArrowDirections = .any
        alert.popoverPresentationController?.sourceRect = self.bounds

        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    @objc private func updateValues() {
        DispatchQueue.main.async {
            self.updateSwitch()
            self.updateSubtitle()
        }
    }

    private func updateSwitch() {
        guard let settingsItem = settingsItem else { return }

        switch settingsItem.action {
        case .toggle(let preferenceKey):
            let value = self.userDefaults.bool(forKey: preferenceKey)
            self.switchControl.isOn = value
        default:
            break
        }
    }

    private func updateSubtitle() {
        if let subtitle = self.getSubtitle(for: self.settingsItem?.preferenceKey ?? "") {
            self.subtitleLabel.text = settingsBundle.localizedString(forKey: subtitle, value: subtitle, table: "Root")
        }
    }
}
