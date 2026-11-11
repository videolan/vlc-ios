/*****************************************************************************
 * ActionSheetCell.swift
 *
 * Copyright © 2018-2026 VLC authors and VideoLAN
 * Copyright © 2018-2026 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

enum ActionSheetCellAccessoryType {
    case none
    case toggleSwitch
    case checkmark
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

@objc(VLCActionSheetCellDelegate)
protocol ActionSheetCellDelegate {
    func actionSheetCellShouldUpdateColors() -> Bool
    @objc optional func actionSheetCellDidToggleSwitch(for cell: ActionSheetCell, state: Bool)
}

@objc(VLCActionSheetCell)
class ActionSheetCell: UICollectionViewCell {

    /// Rightmost accessory view that the cell should use. Default `checkmark`.
    private(set) var accessoryView = UIView ()
    weak var delegate: ActionSheetCellDelegate?
    var isMediaPlayerActionSheetCell: Bool = false

    @objc static var identifier: String {
        return String(describing: self)
    }

    @objc override var isSelected: Bool {
        didSet {
            updateColors()
            // only checkmarks should be hidden if they arent selected
            if accessoryType == .checkmark {
                accessoryView.isHidden = !isSelected
            }
        }
    }

    @objc let icon: ActionSheetCellImageView = {
        let icon = ActionSheetCellImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 24)
        ])
        return icon
    }()

    @objc let name: UILabel = {
        let name = UILabel()
        let colors = PresentationTheme.current.colors
        name.textColor = colors.cellTextColor
        name.backgroundColor = colors.background
        name.font = UIFont.preferredCustomFont(forTextStyle: .subheadline)
        name.lineBreakMode = .byTruncatingTail
        name.setContentHuggingPriority(.defaultLow, for: .horizontal)
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()

    @objc lazy private var accessoryTypeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .none
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    @objc lazy private var toggleSwitch: UISwitch = {
        let toggleSwitch = UISwitch()
        toggleSwitch.onTintColor = .orange
        toggleSwitch.setContentHuggingPriority(.required, for: .horizontal)
        toggleSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
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
            case .toggleSwitch:
                add(view: toggleSwitch, to: accessoryView)
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
    
    private func getThemeColors() -> ColorPalette {
        if isMediaPlayerActionSheetCell {
            return PresentationTheme.currentExcludingWhite.colors
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
        delegate?.actionSheetCellDidToggleSwitch?(for: self, state: sender.isOn)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        toggleSwitch.removeFromSuperview()
        accessoryType = .checkmark
        accessibilityIdentifier = nil
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
    
    func configure(with title: String, colors: ColorPalette, isSelected: Bool) {
        name.text = title
        name.textColor = isSelected ? colors.orangeUI : colors.cellTextColor

        backgroundColor = colors.background
        name.backgroundColor = colors.background
        stackView.backgroundColor = colors.background
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

        accessoryView.setContentHuggingPriority(.required, for: .horizontal)
        accessoryView.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(stackView)

        // property observers only trigger after the first time the values are set.
        // allow the didSet to set the checkmark image
        accessoryType = .checkmark

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stackView.heightAnchor.constraint(equalTo: heightAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    @objc private func updateTheme() {
        backgroundColor = .clear
        name.backgroundColor = .clear
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
