/*****************************************************************************
 * ActionSheetSortSectionHeader.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

enum ActionSheetSortHeaderOptions {
    case descendingOrder
    case layoutChange
    case groupChange
}

protocol ActionSheetSortSectionHeaderDelegate: class {
    func actionSheetSortSectionHeader(_ header: ActionSheetSortSectionHeader,
                                      onSwitchIsOnChange: Bool,
                                      type: ActionSheetSortHeaderOptions)
}

class ActionSheetSortSectionHeader: ActionSheetSectionHeader {
    private var displayGroupsLayoutOption = false
    private var modelType: String

    override var cellHeight: CGFloat {
        return displayGroupsLayoutOption ? 225 : 185
    }

    private var sortModel: SortModel
    private var secondSortModel: SortModel?
    private let userDefaults = UserDefaults.standard

    private let descendingStackView: UIStackView = {
        let descendingStackView = UIStackView()
        descendingStackView.spacing = 0
        descendingStackView.alignment = .center
        descendingStackView.translatesAutoresizingMaskIntoConstraints = false
        return descendingStackView
    }()

    private let gridLayoutStackView: UIStackView = {
        let gridLayoutStackView = UIStackView()
        gridLayoutStackView.spacing = 0
        gridLayoutStackView.alignment = .center
        gridLayoutStackView.translatesAutoresizingMaskIntoConstraints = false
        return gridLayoutStackView
    }()

    private let disableGroupsStackView: UIStackView = {
        let disableGroupsStackView = UIStackView()
        disableGroupsStackView.spacing = 0
        disableGroupsStackView.alignment = .center
        disableGroupsStackView.translatesAutoresizingMaskIntoConstraints = false
        return disableGroupsStackView
    }()

    private let mainStackView: UIStackView = {
        let mainStackView = UIStackView()
        mainStackView.spacing = 10
        mainStackView.axis = .vertical
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        return mainStackView
    }()

    private let secondaryStackView: UIStackView = {
        let secondaryStackView = UIStackView()
        secondaryStackView.spacing = 10
        secondaryStackView.axis = .vertical
        secondaryStackView.translatesAutoresizingMaskIntoConstraints = false
        return secondaryStackView
    }()

    private let descendingLabel: UILabel = {
        let descendingLabel = UILabel()
        descendingLabel.textColor = PresentationTheme.current.colors.cellTextColor
        descendingLabel.text = NSLocalizedString("DESCENDING_LABEL", comment: "")
        descendingLabel.accessibilityLabel = NSLocalizedString("DESCENDING_LABEL", comment: "")
        descendingLabel.accessibilityHint = NSLocalizedString("DESCENDING_LABEL", comment: "")
        descendingLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        descendingLabel.translatesAutoresizingMaskIntoConstraints = false
        return descendingLabel
    }()

    let actionSwitch: UISwitch = {
        let actionSwitch = UISwitch()
        actionSwitch.addTarget(self, action: #selector(handleDescendingSwitch(_:)), for: .valueChanged)
        actionSwitch.accessibilityLabel = NSLocalizedString("DESCENDING_SWITCH_LABEL", comment: "")
        actionSwitch.accessibilityHint = NSLocalizedString("DESCENDING_SWITCH_HINT", comment: "")
        actionSwitch.translatesAutoresizingMaskIntoConstraints = false
        return actionSwitch
    }()

    private let gridLayoutLabel: UILabel = {
        let gridLayoutLabel = UILabel()
        gridLayoutLabel.text = NSLocalizedString("GRID_LAYOUT", comment: "")
        gridLayoutLabel.accessibilityLabel = NSLocalizedString("GRID_LAYOUT", comment: "")
        gridLayoutLabel.accessibilityHint = NSLocalizedString("GRID_LAYOUT", comment: "")
        //TODO: Set appropriate accessibilityLabel and accessibilityHint
        gridLayoutLabel.font = .systemFont(ofSize: 15, weight: .medium)
        gridLayoutLabel.textColor = PresentationTheme.current.colors.cellTextColor
        gridLayoutLabel.translatesAutoresizingMaskIntoConstraints = false
        return gridLayoutLabel
    }()

    private let disableGroupsLabel: UILabel = {
        let disableGroupsLabel = UILabel()
        disableGroupsLabel.text = NSLocalizedString("DISABLE_GROUPS", comment: "")
        disableGroupsLabel.accessibilityLabel = NSLocalizedString("DISABLE_GROUPS", comment: "")
        disableGroupsLabel.accessibilityHint = NSLocalizedString("DISABLE_GROUPS", comment: "")
        disableGroupsLabel.font = .systemFont(ofSize: 15, weight: .medium)
        disableGroupsLabel.textColor = PresentationTheme.current.colors.cellTextColor
        disableGroupsLabel.translatesAutoresizingMaskIntoConstraints = false
        return disableGroupsLabel
    }()

    private let displayByLabel: UILabel = {
        let displayByLabel = UILabel()
        displayByLabel.text = NSLocalizedString("DISPLAY_AS", comment: "")
        displayByLabel.accessibilityLabel = NSLocalizedString("DISPLAY_AS", comment: "")
        displayByLabel.accessibilityHint = NSLocalizedString("DISPLAY_AS", comment: "")
        displayByLabel.font = .boldSystemFont(ofSize: 17)
        displayByLabel.textColor = PresentationTheme.current.colors.cellTextColor
        displayByLabel.translatesAutoresizingMaskIntoConstraints = false
        return displayByLabel
    }()

    let layoutChangeSwitch: UISwitch = {
        let layoutChangeSwitch = UISwitch()
        layoutChangeSwitch.addTarget(self,
                               action: #selector(handleLayoutChangeSwitch(_:)),
                               for: .valueChanged)
        layoutChangeSwitch.accessibilityLabel = NSLocalizedString("GRID_LAYOUT", comment: "")
        layoutChangeSwitch.accessibilityHint = NSLocalizedString("GRID_LAYOUT", comment: "")
        layoutChangeSwitch.translatesAutoresizingMaskIntoConstraints = false
        return layoutChangeSwitch
    }()

    let disableGroupsSwitch: UISwitch = {
        let disableGroupsSwitch = UISwitch()
        disableGroupsSwitch.addTarget(self,
                                      action: #selector(handleDisableGroupChangeSwitch(_:)),
                                      for: .valueChanged)
        disableGroupsSwitch.accessibilityHint = NSLocalizedString("DISABLE_GROUPS_SWITCH_HINT", comment: "")
        disableGroupsSwitch.translatesAutoresizingMaskIntoConstraints = false
        return disableGroupsSwitch
    }()

    weak var delegate: ActionSheetSortSectionHeaderDelegate?

    init(model: SortModel, secondModel: SortModel?, displayGroupsLayout: Bool = false, currentModelType: String) {
        displayGroupsLayoutOption = displayGroupsLayout
        modelType = currentModelType
        sortModel = model
        secondSortModel = secondModel
        super.init(frame: .zero)
        actionSwitch.isOn = sortModel.desc

        layoutChangeSwitch.isOn = userDefaults.bool(forKey: "\(kVLCAudioLibraryGridLayout)\(modelType)")

        disableGroupsSwitch.isOn = userDefaults.bool(forKey: "\(kVLCGroupLayout)\(modelType)")

        translatesAutoresizingMaskIntoConstraints = false
        setupStackView()
        updateTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme),
                                               name: .VLCThemeDidChangeNotification, object: nil)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow != nil {
            // ActionSheetSortSectionHeader did appear.
            actionSwitch.isOn = sortModel.desc

            layoutChangeSwitch.isOn = userDefaults.bool(forKey: "\(kVLCAudioLibraryGridLayout)\(modelType)")

            disableGroupsSwitch.isOn = userDefaults.bool(forKey: "\(kVLCGroupLayout)\(modelType)")
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func updateTheme() {
        backgroundColor = PresentationTheme.current.colors.background
        displayByLabel.textColor = PresentationTheme.current.colors.cellTextColor
        disableGroupsLabel.textColor = PresentationTheme.current.colors.cellTextColor
        descendingLabel.textColor = PresentationTheme.current.colors.cellTextColor
        gridLayoutLabel.textColor = PresentationTheme.current.colors.cellTextColor
    }

    @objc func handleDescendingSwitch(_ sender: UISwitch) {
        delegate?.actionSheetSortSectionHeader(self,
                                               onSwitchIsOnChange: sender.isOn,
                                               type: .descendingOrder)
    }

    @objc func handleLayoutChangeSwitch(_ sender: UISwitch) {
        delegate?.actionSheetSortSectionHeader(self,
                                               onSwitchIsOnChange: sender.isOn,
                                               type: .layoutChange)
     }

    @objc func handleDisableGroupChangeSwitch(_ sender: UISwitch) {
        delegate?.actionSheetSortSectionHeader(self, onSwitchIsOnChange: sender.isOn, type: .groupChange)

        layoutChangeSwitch.isOn = userDefaults.bool(forKey: "\(kVLCAudioLibraryGridLayout)\(modelType)")
        actionSwitch.isOn = sortModel.desc
        if let model = secondSortModel {
            let previousSortModel = sortModel
            sortModel = model
            secondSortModel = previousSortModel
            willMove(toWindow: nil)
        }
    }

    private func setupStackView() {
        descendingStackView.addArrangedSubview(descendingLabel)
        descendingStackView.addArrangedSubview(actionSwitch)

        mainStackView.addArrangedSubview(descendingStackView)

        gridLayoutStackView.addArrangedSubview(gridLayoutLabel)
        gridLayoutStackView.addArrangedSubview(layoutChangeSwitch)

        secondaryStackView.addArrangedSubview(gridLayoutStackView)

        if displayGroupsLayoutOption {
            disableGroupsStackView.addArrangedSubview(disableGroupsLabel)
            disableGroupsStackView.addArrangedSubview(disableGroupsSwitch)
            secondaryStackView.addArrangedSubview(disableGroupsStackView)
        }

        addSubview(mainStackView)
        addSubview(secondaryStackView)
        addSubview(displayByLabel)

        titleConstraint = title.topAnchor.constraint(equalTo: secondaryStackView.bottomAnchor, constant: 15)

        NSLayoutConstraint.activate([
            displayByLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            displayByLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            displayByLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),

            secondaryStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            secondaryStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            secondaryStackView.topAnchor.constraint(equalTo: displayByLabel.bottomAnchor, constant: 15),

            mainStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            mainStackView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 15),
        ])
    }
}
