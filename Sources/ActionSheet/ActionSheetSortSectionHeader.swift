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
}

protocol ActionSheetSortSectionHeaderDelegate: class {
    func actionSheetSortSectionHeader(_ header: ActionSheetSortSectionHeader,
                                      onSwitchIsOnChange: Bool,
                                      type: ActionSheetSortHeaderOptions)
}

class ActionSheetSortSectionHeader: ActionSheetSectionHeader {
    private var displayGridLayoutOption = false
    private var modelType: String

    override var cellHeight: CGFloat {
        return displayGridLayoutOption ? 150 : 100
    }

    private let sortModel: SortModel
    private let userDefaults = UserDefaults.standard

    private let descendingStackView: UIStackView = {
        let descendingStackView = UIStackView()
        descendingStackView.spacing = 0
        descendingStackView.alignment = .center
        descendingStackView.translatesAutoresizingMaskIntoConstraints = false
        return descendingStackView
    }()

    private let gridLayoutStackView: UIStackView = {
        let descendingStackView = UIStackView()
        descendingStackView.spacing = 0
        descendingStackView.alignment = .center
        descendingStackView.translatesAutoresizingMaskIntoConstraints = false
        return descendingStackView
    }()

    private let mainStackView: UIStackView = {
        let descendingStackView = UIStackView()
        descendingStackView.spacing = 10
        descendingStackView.axis = .vertical
        descendingStackView.translatesAutoresizingMaskIntoConstraints = false
        return descendingStackView
    }()

    private let descendingLabel: UILabel = {
        let descendingLabel = UILabel()
        descendingLabel.textColor = PresentationTheme.current.colors.cellTextColor
        descendingLabel.text = NSLocalizedString("DESCENDING_LABEL", comment: "")
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
        let descendingLabel = UILabel()
        descendingLabel.text = NSLocalizedString("GRID_LAYOUT", comment: "")
        descendingLabel.accessibilityLabel = NSLocalizedString("GRID_LAYOUT", comment: "")
        descendingLabel.accessibilityHint = NSLocalizedString("GRID_LAYOUT", comment: "")
        //TODO: Set appropriate accessibilityLabel and accessibilityHint
        descendingLabel.font = .systemFont(ofSize: 15, weight: .medium)
        descendingLabel.textColor = PresentationTheme.current.colors.cellTextColor
        descendingLabel.translatesAutoresizingMaskIntoConstraints = false
        return descendingLabel
    }()

    let layoutChangeSwitch: UISwitch = {
        let actionSwitch = UISwitch()
        actionSwitch.addTarget(self,
                               action: #selector(handleLayoutChangeSwitch(_:)),
                               for: .valueChanged)
        actionSwitch.translatesAutoresizingMaskIntoConstraints = false
        return actionSwitch
    }()

    weak var delegate: ActionSheetSortSectionHeaderDelegate?

    init(model: SortModel, displayGridLayout: Bool = false, currentModelType: String) {
        displayGridLayoutOption = displayGridLayout
        modelType = currentModelType
        sortModel = model
        super.init(frame: .zero)
        actionSwitch.isOn = sortModel.desc

        layoutChangeSwitch.isOn = userDefaults.bool(forKey: "\(kVLCAudioLibraryGridLayout)\(modelType)")

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
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func updateTheme() {
        backgroundColor = PresentationTheme.current.colors.background
        descendingLabel.textColor = PresentationTheme.current.colors.cellTextColor
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

    private func setupStackView() {
        descendingStackView.addArrangedSubview(descendingLabel)
        descendingStackView.addArrangedSubview(actionSwitch)

        if displayGridLayoutOption {
            gridLayoutStackView.addArrangedSubview(gridLayoutLabel)
            gridLayoutStackView.addArrangedSubview(layoutChangeSwitch)
        }

        mainStackView.addArrangedSubview(descendingStackView)
        mainStackView.addArrangedSubview(gridLayoutStackView)
        addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            mainStackView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 15),
        ])
    }
}
