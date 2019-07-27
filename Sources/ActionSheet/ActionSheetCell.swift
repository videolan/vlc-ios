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

enum ActionSheetCellAccessoryType: Equatable {
    case none
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

@objc (VLCActionSheetCellItem)
@objcMembers class ActionSheetCellItem: NSObject {
    var title: String
    var iconImage: UIImage?
    var associatedViewController: UIViewController?
    
    init(imageIdentifier: String, title: String, viewController: UIViewController? = nil) {
        self.title = title
        self.iconImage = UIImage(named: imageIdentifier)
        self.associatedViewController = viewController
    }
}

@objc(VLCActionSheetCell)
class ActionSheetCell: UICollectionViewCell {
    
    weak var associatedViewController: UIViewController?

    @objc static var identifier: String {
        return String(describing: self)
    }

    override var isSelected: Bool {
        didSet {
            updateColors()
            // only checkmarks should be hidden if they arent selected
            accessoryTypeImageView.isHidden = !isSelected && accessoryType == .checkmark
        }
    }
    
    var cellItemModel: ActionSheetCellItem? = nil {
        didSet {
            if let cellItemModel = cellItemModel {
                name.text = cellItemModel.title
                icon.image = cellItemModel.iconImage?.withRenderingMode(.alwaysTemplate)
                icon.tintColor = .orange
                associatedViewController = cellItemModel.associatedViewController
            } else {
                icon.tintColor = .none
                associatedViewController = nil
            }
        }
    }

    let icon: ActionSheetCellImageView = {
        let icon = ActionSheetCellImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        return icon
    }()

    let name: UILabel = {
        let name = UILabel()
        name.textColor = PresentationTheme.current.colors.cellTextColor
        name.font = UIFont.systemFont(ofSize: 15)
        name.translatesAutoresizingMaskIntoConstraints = false
        name.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return name
    }()

    private var accessoryTypeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .none
        imageView.tintColor = PresentationTheme.current.colors.cellDetailTextColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    var accessoryType: ActionSheetCellAccessoryType = .checkmark {
        didSet {
            switch accessoryType {
            case .checkmark:
                accessoryTypeImageView.image = UIImage(named: "checkmark")?.withRenderingMode(.alwaysTemplate)
                accessoryTypeImageView.isHidden = !isSelected
            case .disclosureChevron:
                accessoryTypeImageView.image = UIImage(named: "disclosureChevron")?.withRenderingMode(.alwaysTemplate)
                accessoryTypeImageView.isHidden = false
            case .none:
                accessoryTypeImageView.image = nil
                accessoryTypeImageView.isHidden = true
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

    private func updateColors() {
        let colors = PresentationTheme.current.colors
        name.textColor = isSelected ? colors.orangeUI : colors.cellTextColor
        tintColor = isSelected ? colors.orangeUI : colors.cellDetailTextColor
        if accessoryType == .checkmark {
            let defaultColor = PresentationTheme.current.colors.cellDetailTextColor
            accessoryTypeImageView.tintColor = isSelected ? .orange : defaultColor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        updateColors()
    }

    private func setupViews() {
        backgroundColor = PresentationTheme.current.colors.background

        // property observers only trigger after the first time the values are set.
        // allow the didSet to set the checkmark image
        accessoryType = .checkmark
        
        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(name)
        stackView.addArrangedSubview(accessoryTypeImageView)
        addSubview(stackView)

        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        NSLayoutConstraint.activate([
            icon.heightAnchor.constraint(equalToConstant: 25),
            icon.widthAnchor.constraint(equalTo: icon.heightAnchor),

            stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            stackView.heightAnchor.constraint(equalTo: heightAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor)
        ])
    }
}
