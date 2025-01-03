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

    private enum Constants {
        static let mainLabelFont: UIFont = .preferredFont(forTextStyle: .callout) //16pt default
        static let subtitleLabelFont: UIFont = .preferredFont(forTextStyle: .footnote) //13pt default
        static let numberOfLines = 2
        static let minHeight: CGFloat = 44
        static let marginTop: CGFloat = 10
        static let marginBottom: CGFloat = 10
        static let marginLeading: CGFloat = 20
        static let marginTrailing: CGFloat = 70
    }

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
        label.numberOfLines = Constants.numberOfLines
        label.textColor = colors.cellTextColor
        label.font = Constants.mainLabelFont
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let subtitleLabel: UILabel = {
        let label = UILabel()
        let colors = PresentationTheme.current.colors
        label.font = Constants.subtitleLabelFont
        label.numberOfLines = Constants.numberOfLines
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

    static func height(for settingsItem: SettingsItem, width: CGFloat) -> CGFloat {
        let w = max(width - (Constants.marginLeading + Constants.marginTrailing), 1)

        measurementTitleLabel.text = settingsItem.title
        measurementSubitleLabel.text = settingsItem.subtitle

        let rect = CGRect(origin: .zero, size: CGSize(width: w, height: .greatestFiniteMagnitude))

        let titleHeight = measurementTitleLabel
            .textRect(forBounds: rect, limitedToNumberOfLines: Constants.numberOfLines).height

        let subtitleHeight = measurementSubitleLabel
            .textRect(forBounds: rect, limitedToNumberOfLines: Constants.numberOfLines).height

        return max(
            Constants.marginTop + titleHeight + subtitleHeight + Constants.marginBottom,
            Constants.minHeight
        )
    }

    private static let measurementTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = Constants.numberOfLines
        label.font = Constants.mainLabelFont
        return label
    }()

    private static let measurementSubitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = Constants.numberOfLines
        label.font = Constants.subtitleLabelFont
        return label
    }()

    var settingsItem: SettingsItem? {
        didSet {
            guard let settingsItem = settingsItem else {
                return
            }

            mainLabel.text = settingsItem.title

            mainLabel.textColor = settingsItem.isTitleEmphasized
                ? PresentationTheme.current.colors.orangeUI
                : PresentationTheme.current.colors.cellTextColor

            subtitleLabel.text = settingsItem.subtitle

            switch settingsItem.action {
            case .isLoading:
                switchControl.isHidden = true
                infoButton.isHidden = true
                activityIndicator.isHidden = false
                accessoryView = .none
                accessoryType = .none
                selectionStyle = .none
            case .toggle(_, let isOn):
                switchControl.isHidden = false
                switchControl.isOn = isOn
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
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(mainLabel)
        stackView.addArrangedSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: Constants.marginLeading),
            stackView.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: Constants.marginTop),
            stackView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -Constants.marginBottom),
            stackView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -Constants.marginTrailing)
        ])

        contentView.addSubview(activityIndicator)
        activityIndicator.isHidden = true
        NSLayoutConstraint.activate([
            activityIndicator.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -30),
            activityIndicator.centerYAnchor.constraint(equalTo: stackView.centerYAnchor)
        ])

        contentView.addSubview(infoButton)
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
    }

    @objc func handleSwitchAction(sender: UISwitch) {
        guard let settingsItem = settingsItem else { return }

        switch settingsItem.action {
        case .toggle(let preferenceKey, _):
            delegate?.settingsCellDidChangeSwitchState(preferenceKey: preferenceKey, isOn: sender.isOn)

        default:
            // we should never get here; only toggles have a switch
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

}
