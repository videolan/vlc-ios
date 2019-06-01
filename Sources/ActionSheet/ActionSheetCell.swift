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

@objc(VLCActionSheetCell)
class ActionSheetCell: UICollectionViewCell {

    @objc static var identifier: String {
        return String(describing: self)
    }

    override var isSelected: Bool {
        didSet {
            updateColors()
            checkmark.isHidden = !isSelected
        }
    }

    let icon: UIImageView = {
        let icon = UIImageView()
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

    let checkmark: UILabel = {
        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = UIFont.systemFont(ofSize: 18)
        checkmark.textColor = PresentationTheme.current.colors.orangeUI
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmark.isHidden = true
        return checkmark
    }()

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
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        updateColors()
    }

    private func setupViews() {
        backgroundColor = PresentationTheme.current.colors.background

        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(name)
        stackView.addArrangedSubview(checkmark)
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
