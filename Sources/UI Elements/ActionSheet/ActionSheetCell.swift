/*****************************************************************************
 * ActionSheetCell.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

enum ActionSheetCellAccessoryType {
    case none
    case toggleSwitch
    case checkmark
    case disclosureChevron
    case popup
}

class ActionSheetCellImageView: UIImageView {
    override var image: UIImage? {
        didSet {
            super.image = image
            isHidden = false
        }
    }

    override init(image: UIImage? = nil) {
        super.init(image: image)
        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Model that determines the layout presentation of the ActionSheetCell.
@objc (VLCActionSheetCellModel)
@objcMembers class ActionSheetCellModel: NSObject {
    var title: String
    var iconImage: UIImage?
    var viewToPresent: UIView?
    var accessoryType: ActionSheetCellAccessoryType
    var cellIdentifier: ActionSheetCellIdentifier?
    
    init(
        title: String,
        imageIdentifier: String,
        accessoryType: ActionSheetCellAccessoryType = .checkmark,
        viewToPresent: UIView? = nil,
        cellIdentifier: ActionSheetCellIdentifier? = nil) {
            self.title = title
            iconImage = UIImage(named: imageIdentifier)?.withRenderingMode(.alwaysTemplate)
            self.accessoryType = accessoryType
            self.viewToPresent = viewToPresent
            self.cellIdentifier = cellIdentifier
    }
}

@objc (VLCActionSheetCellDelegate)
protocol ActionSheetCellDelegate {
    func actionSheetCellShouldUpdateColors() -> Bool
    func actionSheetCellDidToggleSwitch(for cell: ActionSheetCell, state: Bool)
}

@objc (VLCDoubleActionSheetCellDelegate)
protocol DoubleActionSheetCellDelegate {
    func doubleActionSheetCellShouldUpdateColors() -> Bool
    func doubleActionSheetCellDidTapLeft(_ cell: DoubleActionSheetCell)
    func doubleActionSheetCellDidTapRight(_ cell: DoubleActionSheetCell)
}

class DoubleActionSheetCell: UICollectionViewCell {
    // MARK: - Properties

    static var reusableIdentifier: String {
        return NSStringFromClass(self)
    }

    weak var delegate: DoubleActionSheetCellDelegate?

    private let mainStackView: UIStackView = {
        var mainStackView: UIStackView = UIStackView()
        mainStackView.axis = .horizontal
        mainStackView.distribution = .fill
        mainStackView.spacing = 20
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        return mainStackView
    }()

    private let leftStackView: UIStackView = {
        var leftStackView: UIStackView = UIStackView()
        leftStackView.axis = .horizontal
        leftStackView.alignment = .center
        leftStackView.spacing = 10
        leftStackView.translatesAutoresizingMaskIntoConstraints = false
        return leftStackView
    }()

    private let leftIcon: ActionSheetCellImageView = {
        let leftIcon = ActionSheetCellImageView()
        leftIcon.setContentHuggingPriority(.required, for: .horizontal)
        leftIcon.contentMode = .scaleAspectFit
        leftIcon.translatesAutoresizingMaskIntoConstraints = false
        return leftIcon
    }()

    private let leftName: UILabel = {
        let name = UILabel()
        let colors = PresentationTheme.current.colors
        name.textColor = colors.cellTextColor
        name.backgroundColor = colors.background
        name.font = UIFont.preferredCustomFont(forTextStyle: .subheadline)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()

    private let rightStackView: UIStackView = {
        var rightStackView: UIStackView = UIStackView()
        rightStackView.axis = .horizontal
        rightStackView.alignment = .center
        rightStackView.spacing = 10
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        return rightStackView
    }()

    private let rightIcon: ActionSheetCellImageView = {
        let rightIcon = ActionSheetCellImageView()
        rightIcon.setContentHuggingPriority(.required, for: .horizontal)
        rightIcon.contentMode = .scaleAspectFit
        rightIcon.translatesAutoresizingMaskIntoConstraints = false
        return rightIcon
    }()

    private let rightName: UILabel = {
        let rightName = UILabel()
        let colors = PresentationTheme.current.colors
        rightName.textColor = colors.cellTextColor
        rightName.backgroundColor = colors.background
        rightName.font = UIFont.preferredCustomFont(forTextStyle: .subheadline)
        rightName.translatesAutoresizingMaskIntoConstraints = false
        return rightName
    }()

    private let separatorView: UIView = {
        let separatorView = UIView(frame: .zero)
        separatorView.backgroundColor = .lightGray
        return separatorView
    }()

    private lazy var rightTapGestureRecognizer: UITapGestureRecognizer = {
        let rightTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                               action: #selector(handleTapOnCell(_:)))
        return rightTapGestureRecognizer
    }()

    private lazy var leftTapGestureRecognizer: UITapGestureRecognizer = {
        let leftTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                               action: #selector(handleTapOnCell(_:)))
        return leftTapGestureRecognizer
    }()

    @objc func handleTapOnCell(_ sender: UITapGestureRecognizer) {
        if sender == leftTapGestureRecognizer {
            delegate?.doubleActionSheetCellDidTapLeft(self)
        } else {
            delegate?.doubleActionSheetCellDidTapRight(self)
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Setup

    private func setupViews() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme),
                                               name: .VLCThemeDidChangeNotification, object: nil)

        translatesAutoresizingMaskIntoConstraints = false
        
        leftStackView.addArrangedSubview(leftIcon)
        leftStackView.addArrangedSubview(leftName)

        rightStackView.addArrangedSubview(rightIcon)
        rightStackView.addArrangedSubview(rightName)

        mainStackView.addArrangedSubview(leftStackView)
        mainStackView.addArrangedSubview(separatorView)
        mainStackView.addArrangedSubview(rightStackView)

        rightStackView.addGestureRecognizer(rightTapGestureRecognizer)
        leftStackView.addGestureRecognizer(leftTapGestureRecognizer)
        addSubview(mainStackView)
        updateTheme()
    }


    private func getThemeColors() -> ColorPalette {
        if PresentationTheme.current.isBlack {
            return PresentationTheme.blackTheme.colors
        } else {
            return PresentationTheme.darkTheme.colors
        }
    }
    @objc private func updateTheme() {
        let colors = getThemeColors()
        backgroundColor = colors.background
        leftName.backgroundColor = backgroundColor
        rightName.backgroundColor = backgroundColor
        mainStackView.backgroundColor = colors.background
        rightStackView.backgroundColor = colors.background
        leftStackView.backgroundColor = colors.background
    }

    private func setupConstraints() {
        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            mainStackView.heightAnchor.constraint(equalTo: heightAnchor),
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            leftStackView.widthAnchor.constraint(equalTo: rightStackView.widthAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func configureRightCell(with name: String, image: UIImage, isEnabled: Bool = true) {
        rightIcon.image = image
        rightName.text = name
        rightName.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        rightIcon.tintColor = isEnabled ? PresentationTheme.currentExcludingWhite.colors.orangeUI : .white
    }

    func configureLeftCell(with name: String, image: UIImage, isEnabled: Bool = true) {
        leftIcon.image = image
        leftName.text = name
        leftName.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        leftIcon.tintColor = isEnabled ? PresentationTheme.currentExcludingWhite.colors.orangeUI : .white
    }
}

@objc(VLCActionSheetCell)
class ActionSheetCell: UICollectionViewCell {

    /// UIViewController to present on cell selection
    weak var viewToPresent: UIView?
    /// Rightmost accessory view that the cell should use. Default `checkmark`.
    /// If `viewControllerToPresent` is set, defaults to `disclosureChevron`, otherwise `checkmark` is main default.
    private(set) var accessoryView = UIView ()
    weak var delegate: ActionSheetCellDelegate?
    var identifier: ActionSheetCellIdentifier?
    var isMediaPlayerActionSheetCell: Bool = false

    @objc static var identifier: String {
        return String(describing: self)
    }

    override var isSelected: Bool {
        didSet {
            updateColors()
            // only checkmarks should be hidden if they arent selected
            if accessoryType == .checkmark {
                accessoryView.isHidden = !isSelected
            }
        }
    }

    let icon: ActionSheetCellImageView = {
        let icon = ActionSheetCellImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.contentMode = .scaleAspectFit
        return icon
    }()

    let name: UILabel = {
        let name = UILabel()
        let colors = PresentationTheme.current.colors
        name.textColor = colors.cellTextColor
        name.backgroundColor = colors.background
        name.font = UIFont.preferredCustomFont(forTextStyle: .subheadline)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()

    lazy private var accessoryTypeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .none
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy private var toggleSwitch: UISwitch = {
        let toggleSwitch = UISwitch()
        toggleSwitch.onTintColor = .orange
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
        return toggleSwitch
    }()

    private(set) var accessoryType: ActionSheetCellAccessoryType = .checkmark {
        didSet {
            accessoryView.isHidden = false
            switch accessoryType {
            case .checkmark:
                accessoryTypeImageView.image = UIImage(named: "checkmark")?.withRenderingMode(.alwaysTemplate)
                add(view: accessoryTypeImageView, to: accessoryView)
                accessoryView.isHidden = !isSelected
            case .disclosureChevron:
                accessoryTypeImageView.image = UIImage(named: "disclosureChevron")?.withRenderingMode(.alwaysTemplate)
                add(view: accessoryTypeImageView, to: accessoryView)
            case .toggleSwitch:
                add(view: toggleSwitch, to: accessoryView)
            case .popup:
                accessoryTypeImageView.image = UIImage(named: "iconMoreOptions")?.withRenderingMode(.alwaysTemplate)
                add(view: accessoryTypeImageView, to: accessoryView)
            case .none:
                accessoryView.isHidden = true
            }
        }
    }

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 15.0
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    convenience init(withCellModel model: ActionSheetCellModel) {
        self.init()
        configure(withModel: model)
        setupViews()
    }

    private func getThemeColors() -> ColorPalette {
        if isMediaPlayerActionSheetCell && PresentationTheme.current.isBlack {
            return PresentationTheme.blackTheme.colors
        } else if isMediaPlayerActionSheetCell {
            return PresentationTheme.darkTheme.colors
        } else {
            return PresentationTheme.current.colors
        }
    }

    private func updateColors() {
        let shouldUpdateColors = delegate?.actionSheetCellShouldUpdateColors() ?? true
        let colors = getThemeColors()
        if shouldUpdateColors {
            name.textColor = isSelected ? colors.orangeUI : colors.cellTextColor
            tintColor = isSelected ? colors.orangeUI : colors.cellDetailTextColor
        }
        if accessoryType != .toggleSwitch {
            accessoryView.tintColor = isSelected && accessoryType == .checkmark ? colors.orangeUI : colors.cellDetailTextColor
        }
    }

    @objc private func switchToggled(_ sender: UISwitch) {
        delegate?.actionSheetCellDidToggleSwitch(for: self, state: sender.isOn)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        toggleSwitch.removeFromSuperview()
        accessoryType = .checkmark
        identifier = nil
        updateColors()
    }

    private func add(view: UIView, to parentView: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        parentView.subviews.forEach { $0.removeFromSuperview() }
        parentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: parentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor)
        ])
    }
    
    func configure(withModel model: ActionSheetCellModel, isFromMediaPlayerActionSheet: Bool = false) {
        if model.accessoryType == .disclosureChevron {
            assert(model.viewToPresent != nil, "ActionSheetCell: Cell with disclosure chevron must have accompanying presentable UIView")
        }
        name.text = model.title
        icon.image = model.iconImage
        viewToPresent = model.viewToPresent
        identifier = model.cellIdentifier
        // disclosure chevron is set as the default accessoryView if a viewController is present
        accessoryType = model.viewToPresent != nil && model.accessoryType != .popup && model.accessoryType != .none ? .disclosureChevron : model.accessoryType
        isMediaPlayerActionSheetCell = isFromMediaPlayerActionSheet
        let colors = getThemeColors()

        if accessoryType == .disclosureChevron || accessoryType == .popup {
            accessoryTypeImageView.tintColor = colors.orangeUI
        }

        if let identifier = model.cellIdentifier {
            name.accessibilityLabel = identifier.description
            name.accessibilityHint = identifier.accessibilityHint
        }

        updateColors()
    }

    func setToggleSwitch(state: Bool) {
        if accessoryType == .toggleSwitch {
            toggleSwitch.isOn = state
        }
    }

    private func setupViews() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme),
                                               name: .VLCThemeDidChangeNotification, object: nil)
        updateTheme()

        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(name)
        stackView.addArrangedSubview(accessoryView)

        addSubview(stackView)

        // property observers only trigger after the first time the values are set.
        // allow the didSet to set the checkmark image
        accessoryType = .checkmark

        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            stackView.heightAnchor.constraint(equalTo: heightAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    @objc private func updateTheme() {
        let colors = getThemeColors()
        backgroundColor = colors.background
        name.textColor = colors.cellTextColor
        name.backgroundColor = backgroundColor
        stackView.backgroundColor = colors.background
        viewToPresent?.backgroundColor = backgroundColor
        updateColors()
    }

    func setAccessoryType(to type: ActionSheetCellAccessoryType) {
        guard type != accessoryType else {
            // The current accessory type is already the wanted one.
            return
        }

        accessoryType = type
    }
}
