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

protocol ActionSheetSortSectionHeaderDelegate: AnyObject {
    func actionSheetSortSectionHeader(_ header: ActionSheetSortSectionHeader,
                                      onSwitchIsOnChange: Bool,
                                      type: ActionSheetSortHeaderOptions)
    func actionSheetSortSectionHeaderShouldHideFeatArtists(onSwitchIsOnChange: Bool)
    func actionSheetSortSectionHeaderShouldHideTrackNumbers(onSwitchIsOnChange: Bool)
}

class ActionSheetSortSectionHeader: ActionSheetSectionHeader {
    private var modelType: String

    override var cellHeight: CGFloat {
        return isAdditionalOptionShown ? 225 : 185
    }

    private var sortModel: SortModel
    private var secondSortModel: SortModel?
    private let userDefaults = UserDefaults.standard
    private var isAdditionalOptionShown: Bool = false

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

    private let hideFeatArtistsStackView: UIStackView = {
        let hideFeatArtistsStackView = UIStackView()
        hideFeatArtistsStackView.spacing = 0
        hideFeatArtistsStackView.alignment = .center
        hideFeatArtistsStackView.translatesAutoresizingMaskIntoConstraints = false
        return hideFeatArtistsStackView
    }()

    private let hideTrackNumbersStackView: UIStackView = {
        let hideTrackNumbersStackView = UIStackView()
        hideTrackNumbersStackView.spacing = 0
        hideTrackNumbersStackView.alignment = .center
        hideTrackNumbersStackView.translatesAutoresizingMaskIntoConstraints = false
        return hideTrackNumbersStackView
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
        descendingLabel.font = UIFont.preferredCustomFont(forTextStyle: .subheadline)
        descendingLabel.translatesAutoresizingMaskIntoConstraints = false
        return descendingLabel
    }()

    lazy var actionSwitch: UISwitch = {
        let actionSwitch = UISwitch()
        actionSwitch.addTarget(self, action: #selector(handleDescendingSwitch(_:)), for: .valueChanged)
        actionSwitch.accessibilityLabel = NSLocalizedString("DESCENDING_SWITCH_LABEL", comment: "")
        actionSwitch.accessibilityHint = NSLocalizedString("DESCENDING_SWITCH_HINT", comment: "")
        actionSwitch.translatesAutoresizingMaskIntoConstraints = false
        return actionSwitch
    }()

    private let gridLayoutLabel: UILabel = {
        let gridLayoutLabel = UILabel()
        let colors = PresentationTheme.current.colors
        gridLayoutLabel.text = NSLocalizedString("GRID_LAYOUT", comment: "")
        gridLayoutLabel.accessibilityLabel = NSLocalizedString("GRID_LAYOUT", comment: "")
        gridLayoutLabel.accessibilityHint = NSLocalizedString("GRID_LAYOUT", comment: "")
        //TODO: Set appropriate accessibilityLabel and accessibilityHint
        gridLayoutLabel.font = UIFont.preferredCustomFont(forTextStyle: .subheadline)
        gridLayoutLabel.textColor = colors.cellTextColor
        gridLayoutLabel.backgroundColor = colors.background
        gridLayoutLabel.translatesAutoresizingMaskIntoConstraints = false
        return gridLayoutLabel
    }()

    private let displayByLabel: UILabel = {
        let displayByLabel = UILabel()
        let colors = PresentationTheme.current.colors
        displayByLabel.text = NSLocalizedString("DISPLAY_AS", comment: "")
        displayByLabel.accessibilityLabel = NSLocalizedString("DISPLAY_AS", comment: "")
        displayByLabel.accessibilityHint = NSLocalizedString("DISPLAY_AS", comment: "")
        displayByLabel.font = UIFont.preferredCustomFont(forTextStyle: .headline).bolded
        displayByLabel.textColor = colors.cellTextColor
        displayByLabel.backgroundColor = colors.background
        displayByLabel.translatesAutoresizingMaskIntoConstraints = false
        return displayByLabel
    }()

    private lazy var layoutChangeSwitch: UISwitch = {
        let layoutChangeSwitch = UISwitch()
        layoutChangeSwitch.addTarget(self,
                               action: #selector(handleLayoutChangeSwitch(_:)),
                               for: .valueChanged)
        layoutChangeSwitch.accessibilityLabel = NSLocalizedString("GRID_LAYOUT", comment: "")
        layoutChangeSwitch.accessibilityHint = NSLocalizedString("GRID_LAYOUT_HINT", comment: "")
        layoutChangeSwitch.translatesAutoresizingMaskIntoConstraints = false
        return layoutChangeSwitch
    }()

    private lazy var hideFeatArtistsLabel: UILabel = {
        let hideFeatArtistsLabel = UILabel()
        let colors = PresentationTheme.current.colors
        hideFeatArtistsLabel.text = NSLocalizedString("HIDE_FEAT_ARTISTS", comment: "")
        hideFeatArtistsLabel.accessibilityLabel = NSLocalizedString("HIDE_FEAT_ARTISTS", comment: "")
        hideFeatArtistsLabel.accessibilityHint = NSLocalizedString("HIDE_FEAT_ARTISTS", comment: "")
        hideFeatArtistsLabel.font = UIFont.preferredCustomFont(forTextStyle: .subheadline)
        hideFeatArtistsLabel.textColor = colors.cellTextColor
        hideFeatArtistsLabel.backgroundColor = colors.background
        hideFeatArtistsLabel.translatesAutoresizingMaskIntoConstraints = false
        return hideFeatArtistsLabel
    }()

    private lazy var hideFeatArtistsSwitch: UISwitch = {
        let hideFeatArtistsSwitch = UISwitch()
        hideFeatArtistsSwitch.addTarget(self, action: #selector(handleHideFeatArtistsSwitch(_:)), for: .valueChanged)
        hideFeatArtistsSwitch.accessibilityLabel = NSLocalizedString("HIDE_FEAT_ARTISTS", comment: "")
        hideFeatArtistsSwitch.accessibilityHint = NSLocalizedString("HIDE_FEAT_ARTISTS", comment: "")
        hideFeatArtistsSwitch.translatesAutoresizingMaskIntoConstraints = false
        return hideFeatArtistsSwitch
    }()

    let hideTrackNumbersLabel: UILabel = {
        let hideTrackNumbersLabel = UILabel()
        let colors = PresentationTheme.current.colors
        hideTrackNumbersLabel.text = NSLocalizedString("HIDE_TRACK_NUMBERS", comment: "")
        hideTrackNumbersLabel.accessibilityLabel = NSLocalizedString("HIDE_TRACK_NUMBERS", comment: "")
        hideTrackNumbersLabel.accessibilityHint = NSLocalizedString("HIDE_TRACK_NUMBERS", comment: "")
        hideTrackNumbersLabel.font = UIFont.preferredCustomFont(forTextStyle: .subheadline)
        hideTrackNumbersLabel.textColor = colors.cellTextColor
        hideTrackNumbersLabel.backgroundColor = colors.background
        hideTrackNumbersLabel.translatesAutoresizingMaskIntoConstraints = false
        return hideTrackNumbersLabel
    }()

    private lazy var hideTrackNumbersSwitch: UISwitch = {
        let hideTrackNumbersSwitch = UISwitch()
        hideTrackNumbersSwitch.addTarget(self, action: #selector(handleHideTrackNumbersSwitch(_:)), for: .valueChanged)
        hideTrackNumbersSwitch.accessibilityLabel = NSLocalizedString("HIDE_TRACK_NUMBERS", comment: "")
        hideTrackNumbersSwitch.accessibilityHint = NSLocalizedString("HIDE_TRACK_NUMBERS", comment: "")
        hideTrackNumbersSwitch.translatesAutoresizingMaskIntoConstraints = false
        return hideTrackNumbersSwitch
    }()

    weak var delegate: ActionSheetSortSectionHeaderDelegate?

    private var isVideoModel: Bool

    init(model: SortModel, secondModel: SortModel?,
         isVideoModel: Bool, currentModelType: String) {
        modelType = currentModelType
        sortModel = model
        secondSortModel = secondModel
        self.isVideoModel = isVideoModel
        super.init(frame: .zero)
        actionSwitch.isOn = sortModel.desc

        setSwitchIsOnFromUserDefaults()
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
            setSwitchIsOnFromUserDefaults()
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func updateTheme() {
        let colors = PresentationTheme.current.colors
        backgroundColor = colors.background
        title.textColor = colors.cellTextColor
        title.backgroundColor = backgroundColor
        displayByLabel.textColor = colors.cellTextColor
        displayByLabel.backgroundColor = backgroundColor
        descendingLabel.textColor = colors.cellTextColor
        descendingLabel.backgroundColor = backgroundColor
        gridLayoutLabel.textColor = colors.cellTextColor
        gridLayoutLabel.backgroundColor = backgroundColor
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

    @objc func handleHideFeatArtistsSwitch(_ sender: UISwitch) {
        delegate?.actionSheetSortSectionHeaderShouldHideFeatArtists(onSwitchIsOnChange: sender.isOn)
    }

    @objc func handleHideTrackNumbersSwitch(_ sender: UISwitch) {
        delegate?.actionSheetSortSectionHeaderShouldHideTrackNumbers(onSwitchIsOnChange: sender.isOn)
    }

    private func setSwitchIsOnFromUserDefaults() {
        let key = isVideoModel ? kVLCVideoLibraryGridLayout : kVLCAudioLibraryGridLayout
        layoutChangeSwitch.isOn = UserDefaults.standard.bool(forKey: key + modelType)
    }

    private func setupStackView() {
        descendingStackView.addArrangedSubview(descendingLabel)
        descendingStackView.addArrangedSubview(actionSwitch)

        mainStackView.addArrangedSubview(descendingStackView)

        gridLayoutStackView.addArrangedSubview(gridLayoutLabel)
        gridLayoutStackView.addArrangedSubview(layoutChangeSwitch)

        secondaryStackView.addArrangedSubview(gridLayoutStackView)

        addSubview(mainStackView)
        addSubview(secondaryStackView)
        addSubview(displayByLabel)
        addSubview(title)

        NSLayoutConstraint.activate([
            displayByLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            displayByLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            displayByLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),

            secondaryStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            secondaryStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            secondaryStackView.topAnchor.constraint(equalTo: displayByLabel.bottomAnchor, constant: 10),

            title.topAnchor.constraint(equalTo: secondaryStackView.bottomAnchor, constant: 20),
            title.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),

            mainStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            mainStackView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
        ])
    }

    func updateHeaderForArtists() {
        isAdditionalOptionShown = true
        hideFeatArtistsStackView.addArrangedSubview(hideFeatArtistsLabel)
        hideFeatArtistsStackView.addArrangedSubview(hideFeatArtistsSwitch)

        secondaryStackView.addArrangedSubview(hideFeatArtistsStackView)

        hideFeatArtistsSwitch.isOn = UserDefaults.standard.bool(forKey: kVLCAudioLibraryHideFeatArtists)
    }

    func updateHeaderForAlbums() {
        isAdditionalOptionShown = true
        hideTrackNumbersStackView.addArrangedSubview(hideTrackNumbersLabel)
        hideTrackNumbersStackView.addArrangedSubview(hideTrackNumbersSwitch)

        secondaryStackView.addArrangedSubview(hideTrackNumbersStackView)

        hideTrackNumbersSwitch.isOn = UserDefaults.standard.bool(forKey: kVLCAudioLibraryHideTrackNumbers)
    }
}
