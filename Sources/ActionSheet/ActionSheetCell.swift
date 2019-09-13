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
    case toggleSwitch
    case checkmark
    case disclosureChevron
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
    var cellIdentifier: MediaPlayerActionSheetCellIdentifier?
    
    init(
        title: String,
        imageIdentifier: String,
        accessoryType: ActionSheetCellAccessoryType = .checkmark,
        viewToPresent: UIView? = nil,
        cellIdentifier: MediaPlayerActionSheetCellIdentifier? = nil) {
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

@objc(VLCActionSheetCell)
class ActionSheetCell: UICollectionViewCell {

    /// UIViewController to present on cell selection
    weak var viewToPresent: UIView?
    /// Rightmost accessory view that the cell should use. Default `checkmark`.
    /// If `viewControllerToPresent` is set, defaults to `disclosureChevron`, otherwise `checkmark` is main default.
    private(set) var accessoryView = UIView ()
    weak var delegate: ActionSheetCellDelegate?
    var identifier: MediaPlayerActionSheetCellIdentifier?

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
        name.textColor = PresentationTheme.current.colors.cellTextColor
        name.font = UIFont.systemFont(ofSize: 15)
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
            switch accessoryType {
            case .checkmark:
                accessoryTypeImageView.image = UIImage(named: "checkmark")?.withRenderingMode(.alwaysTemplate)
                add(view: accessoryTypeImageView, to: accessoryView)
            case .disclosureChevron:
                accessoryTypeImageView.image = UIImage(named: "disclosureChevron")?.withRenderingMode(.alwaysTemplate)
                add(view: accessoryTypeImageView, to: accessoryView)
            case .toggleSwitch:
                add(view: toggleSwitch, to: accessoryView)
            }
            if accessoryType == .checkmark {
                accessoryView.isHidden = !isSelected
            } else {
                accessoryView.isHidden = false
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

    private func updateColors() {
        let shouldUpdateColors = delegate?.actionSheetCellShouldUpdateColors() ?? true
        let colors = PresentationTheme.current.colors
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
    
    func configure(withModel model: ActionSheetCellModel) {
        if model.accessoryType == .disclosureChevron {
            assert(model.viewToPresent != nil, "ActionSheetCell: Cell with disclosure chevron must have accompanying presentable UIView")
        }
        name.text = model.title
        icon.image = model.iconImage
        viewToPresent = model.viewToPresent
        identifier = model.cellIdentifier
        // disclosure chevron is set as the default accessoryView if a viewController is present
        accessoryType = model.viewToPresent != nil ? .disclosureChevron : model.accessoryType
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
        backgroundColor = PresentationTheme.current.colors.background
        name.textColor = PresentationTheme.current.colors.cellTextColor
    }
}
