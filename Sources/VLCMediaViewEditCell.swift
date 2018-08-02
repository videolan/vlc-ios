/*****************************************************************************
 * VLCMediaViewEditCell.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

struct VLCCheckView {
    var isEnabled: Bool {
        didSet {
            let backgroundColor: UIColor = isEnabled ? .orange : .clear
            let borderColor: UIColor = isEnabled ? .clear : .lightGray
            view.backgroundColor = backgroundColor
            view.layer.borderColor = borderColor.cgColor
        }
    }
    var view: UIView
}

class VLCMediaViewEditCell: UICollectionViewCell {

    static let identifier = String(describing: VLCMediaViewEditCell.self)

    static let height: CGFloat = 56

    var checkView: VLCCheckView = {
        var view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.layer.cornerRadius = view.frame.width / 2
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 1
        return VLCCheckView(isEnabled: false, view: view)
    }()

    let thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFit
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 3
        return thumbnailImageView
    }()

    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    let subInfoLabel: UILabel = {
        let subInfoLabel = UILabel()
        subInfoLabel.textColor = PresentationTheme.current.colors.cellTextColor
        subInfoLabel.font = UIFont.systemFont(ofSize: 13)
        subInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        return subInfoLabel
    }()

    let sizeLabel: UILabel = {
        let sizeLabel = UILabel()
        sizeLabel.textColor = PresentationTheme.current.colors.cellTextColor
        sizeLabel.font = UIFont.systemFont(ofSize: 11)
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        return sizeLabel
    }()

    let mainStackView: UIStackView = {
        let mainStackView = UIStackView()
        mainStackView.spacing = 20.0
        mainStackView.axis = .horizontal
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        return mainStackView
    }()

    let mediaInfoStackView: UIStackView = {
        let mediaInfoStackView = UIStackView()
        mediaInfoStackView.spacing = 5.0
        mediaInfoStackView.axis = .vertical
        mediaInfoStackView.alignment = .leading
        mediaInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        return mediaInfoStackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    private func setupViews() {

        mediaInfoStackView.addArrangedSubview(titleLabel)
        mediaInfoStackView.addArrangedSubview(subInfoLabel)
        mediaInfoStackView.addArrangedSubview(sizeLabel)

        mainStackView.addArrangedSubview(checkView.view)
        mainStackView.addArrangedSubview(thumbnailImageView)
        mainStackView.addArrangedSubview(mediaInfoStackView)

        addSubview(mainStackView)

        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        NSLayoutConstraint.activate([
            checkView.view.heightAnchor.constraint(equalToConstant: 20),
            checkView.view.widthAnchor.constraint(equalTo: checkView.view.heightAnchor),

            thumbnailImageView.heightAnchor.constraint(equalToConstant: VLCMediaViewEditCell.height),
            thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor),

            mainStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            mainStackView.heightAnchor.constraint(equalTo: heightAnchor),
            mainStackView.topAnchor.constraint(equalTo: topAnchor)
            ])
    }
}
