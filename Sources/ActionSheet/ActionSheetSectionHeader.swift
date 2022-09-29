/*****************************************************************************
 * ActionSheetSectionHeader.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class ActionSheetSectionHeader: UIView {

    static let identifier = "VLCActionSheetSectionHeader"

    public var accessoryViewsDelegate: ActionSheetAccessoryViewsDelegate? {
        didSet {
            addAccessoryViews()
        }
    }

    var cellHeight: CGFloat {
        return 50
    }

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    let title: UILabel = {
        let title = UILabel()
        let colors = PresentationTheme.current.colors
        title.font = UIFont.preferredCustomFont(forTextStyle: .headline).bolded
        title.textColor = colors.cellTextColor
        title.backgroundColor = colors.background
        title.setContentHuggingPriority(.required, for: .vertical)
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()

    let separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = .lightGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()

    let previousButton: UIButton = {
        let previousButton = UIButton()
        previousButton.setImage(UIImage(named: "disclosureChevron")?.withRenderingMode(.alwaysTemplate), for: .normal)
        previousButton.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        previousButton.tintColor = PresentationTheme.current.colors.orangeUI
        previousButton.setContentHuggingPriority(.required, for: .horizontal)
        previousButton.setContentHuggingPriority(.required, for: .vertical)
        previousButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        previousButton.accessibilityLabel = NSLocalizedString("BUTTON_BACK", comment: "")
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        previousButton.isHidden = true
        return previousButton
    }()

    lazy var guide: LayoutAnchorContainer = {
        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        return guide
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
        setupSeparator()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupStackView()
        setupSeparator()
    }

    fileprivate func setupStackView() {
        stackView.addArrangedSubview(previousButton)
        stackView.addArrangedSubview(title)
        addAccessoryViews()

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    fileprivate func addAccessoryViews() {
        if let accessoryViews = accessoryViewsDelegate?.actionSheetAccessoryViews(self) {
            for accessoryView in accessoryViews {
                stackView.addArrangedSubview(accessoryView)
            }
        }
    }

    func updateAccessoryViews() {
        while stackView.arrangedSubviews.count > 2 {
            if let subview = stackView.arrangedSubviews.last {
                stackView.removeArrangedSubview(subview)
                subview.removeFromSuperview()
            }
        }
        addAccessoryViews()
        stackView.layoutSubviews()
    }

    fileprivate func setupSeparator() {
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.topAnchor.constraint(equalTo: bottomAnchor, constant: -1)
        ])
    }

    fileprivate func setupTitle() {
        addSubview(title)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
        ])
    }
}

protocol ActionSheetAccessoryViewsDelegate {
    func actionSheetAccessoryViews(_ actionSheet: ActionSheetSectionHeader) -> [UIView]
}
