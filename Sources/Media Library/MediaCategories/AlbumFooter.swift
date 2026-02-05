/*****************************************************************************
 * AlbumFooter.swift
 *
 * Copyright © 2026 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class AlbumFooter: UICollectionReusableView {
    // MARK: - Properties

    static let footerID = "AlbumFooterID"

    private lazy var dividerView: UIView = {
        let dividerView = UIView(frame: .zero)
        dividerView.backgroundColor = PresentationTheme.current.colors.separatorColor
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        return dividerView
    }()

    private lazy var artistLabel: UILabel = {
        let informationLabel = UILabel()
        informationLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        informationLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        informationLabel.translatesAutoresizingMaskIntoConstraints = false
        return informationLabel
    }()

    private lazy var dateLabel: UILabel = {
        let dateLabel = UILabel()
        dateLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        dateLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        return dateLabel
    }()

    private lazy var tracksLabel: UILabel = {
        let tracksLabel = UILabel()
        tracksLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        tracksLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        tracksLabel.translatesAutoresizingMaskIntoConstraints = false
        return tracksLabel
    }()

    private lazy var iconImageView: UIImageView = {
        let icon = UIImage(named: "LaunchCone")?.withRenderingMode(.alwaysTemplate)
        let iconImageView = UIImageView(image: icon)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = PresentationTheme.current.colors.cellDetailTextColor
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        return iconImageView
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupFooterView()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTheme),
                                               name: .VLCThemeDidChangeNotification,
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods

    private func setupFooterView() {
        addSubview(dividerView)
        addSubview(iconImageView)
        addSubview(artistLabel)
        addSubview(dateLabel)
        addSubview(tracksLabel)

        NSLayoutConstraint.activate([
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            dividerView.topAnchor.constraint(equalTo: topAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            artistLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            artistLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            artistLabel.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 10),

            tracksLabel.leadingAnchor.constraint(equalTo: artistLabel.leadingAnchor),
            tracksLabel.trailingAnchor.constraint(equalTo: artistLabel.trailingAnchor),
            tracksLabel.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 10),

            dateLabel.leadingAnchor.constraint(equalTo: tracksLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: tracksLabel.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: tracksLabel.bottomAnchor, constant: 10),

            iconImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -35),
            iconImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15),
            iconImageView.widthAnchor.constraint(equalToConstant: 25),
            iconImageView.heightAnchor.constraint(equalToConstant: 25),
        ])
    }

    @objc private func updateTheme() {
        let colors: ColorPalette = PresentationTheme.current.colors

        backgroundColor = .clear
        dividerView.backgroundColor = colors.separatorColor
        artistLabel.textColor = colors.cellDetailTextColor
        tracksLabel.textColor = colors.cellDetailTextColor
        dateLabel.textColor = colors.cellDetailTextColor
        iconImageView.tintColor = colors.cellDetailTextColor
    }

    // MARK: - Public methods

    func configure(with album: VLCMLAlbum) {
        artistLabel.text = "\(album.albumArtistName())"

        var tracksContent: [String] = [album.numberOfTracksString()]
        let duration = VLCTime(number: NSNumber(value: album.duration()))
        tracksContent.append(String(describing: duration))
        tracksLabel.text = tracksContent.joined(separator: " · ")

        let releaseYear = album.releaseYear()
        if releaseYear == 0 {
            dateLabel.removeFromSuperview()
        } else {
            dateLabel.text = "\(releaseYear)"
        }
    }

    static func getFooterSize(with width: CGFloat, and collection: VLCMLAlbum) -> CGSize {
        var height: CGFloat = 100.0

        if collection.releaseYear() == 0 {
            height -= 25.0
        }

        return CGSize(width: width, height: height)
    }
}
