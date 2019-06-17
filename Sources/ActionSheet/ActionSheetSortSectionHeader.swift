/*****************************************************************************
 * ActionSheetSortSectionHeader.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol ActionSheetSortSectionHeaderDelegate: class {
    func actionSheetSortSectionHeader(_ header: ActionSheetSortSectionHeader,
                                      onSwitchIsOnChange: Bool)
}

class ActionSheetSortSectionHeader: ActionSheetSectionHeader {
    override var cellHeight: CGFloat {
        return 100
    }

    private let sortModel: SortModel

    private let descendingStackView: UIStackView = {
        let descendingStackView = UIStackView()
        descendingStackView.spacing = 0
        descendingStackView.alignment = .center
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
        actionSwitch.addTarget(self, action: #selector(handleSwitch(_:)), for: .valueChanged)
        actionSwitch.accessibilityLabel = NSLocalizedString("DESCENDING_SWITCH_LABEL", comment: "")
        actionSwitch.accessibilityHint = NSLocalizedString("DESCENDING_SWITCH_HINT", comment: "")
        actionSwitch.translatesAutoresizingMaskIntoConstraints = false
        return actionSwitch
    }()

    weak var delegate: ActionSheetSortSectionHeaderDelegate?

    init(model: SortModel) {
        sortModel = model
        super.init(frame: .zero)
        actionSwitch.isOn = sortModel.desc
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
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func updateTheme() {
        backgroundColor = PresentationTheme.current.colors.background
        descendingLabel.textColor = PresentationTheme.current.colors.cellTextColor
    }

    @objc func handleSwitch(_ sender: UISwitch) {
        delegate?.actionSheetSortSectionHeader(self, onSwitchIsOnChange: sender.isOn)
    }

    private func setupStackView() {
        descendingStackView.addArrangedSubview(descendingLabel)
        descendingStackView.addArrangedSubview(actionSwitch)
        addSubview(descendingStackView)

        NSLayoutConstraint.activate([
            descendingStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            descendingStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            descendingStackView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 15),
            ])
    }
}
