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
        case checkmark
        case disclosureChevron
        case custom(image: UIImage)
    
        static func ==(lhs: ActionSheetCellAccessoryType, rhs: ActionSheetCellAccessoryType) -> Bool {
            switch lhs {
            case .checkmark:
                switch rhs {
                case .checkmark:
                    return true
                default:
                    return false
                }
            case .disclosureChevron:
                switch rhs {
                case .disclosureChevron:
                    return true
                default:
                    return false
                }
            case .custom( _):
                switch rhs {
                case .custom( _):
                    return true
                default:
                    return false
                }
            default:
                assertionFailure("Unhandled ActionSheetAccessoryType")
            }
        }
    }

extension UIImage {
        class var checkmark: UIImage? {
                return UIImage(named: "checkboxSelected")
            }
    
        class var disclosureChevron: UIImage? {
                return UIImage(named: "disclosureChevron")
            }
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

@objc(VLCActionSheetCell)
class ActionSheetCell: UICollectionViewCell {

    @objc static var identifier: String {
        return String(describing: self)
    }

    override var isSelected: Bool {
        didSet {
            updateColors()
//            checkmark.isHidden = !isSelected
            if accessoryType == .checkmark {
                accessoryTypeImageView.isHidden = !isSelected
                accessoryTypeImageView.tintColor = isSelected ? .orange : .white
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
    
    var accessoryType: ActionSheetCellAccessoryType {
        didSet {
            switch accessoryType {
            case .checkmark:
                accessoryTypeImageView.image = .checkmark
                accessoryTypeImageView.isHidden = true
            case .disclosureChevron:
                accessoryTypeImageView.image = .disclosureChevron
            case .custom(let image):
                accessoryTypeImageView.image = image
            default:
                assertionFailure("Unhandled ActionSheetAccessoryType")
            }
        }
    }
    
    private let accessoryTypeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = .checkmark
        imageView.backgroundColor = .none
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

//    let checkmark: UILabel = {
//        let checkmark = UILabel()
//        checkmark.text = "✓"
//        checkmark.font = UIFont.systemFont(ofSize: 18)
//        checkmark.textColor = PresentationTheme.current.colors.orangeUI
//        checkmark.translatesAutoresizingMaskIntoConstraints = false
//        checkmark.isHidden = true
//        return checkmark
//    }()

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 15.0
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        accessoryType = .checkmark
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        accessoryType = .checkmark
        super.init(coder: aDecoder)
        setupViews()
    }

    private func updateColors() {
        let colors = PresentationTheme.current.colors
        name.textColor = isSelected ? colors.orangeUI : colors.cellTextColor
        tintColor = isSelected ? colors.orangeUI : colors.cellDetailTextColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        updateColors()
    }

    private func setupViews() {
        backgroundColor = PresentationTheme.current.colors.background

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
