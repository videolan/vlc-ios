/*****************************************************************************
* MediaGridCollectionCell.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
* $Id$
*
* Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import UIKit

class MediaGridCollectionCell: BaseCollectionViewCell {

    private let notificationCenter = NotificationCenter.default
    private let userDefaults = UserDefaults.standard
    private let selectionOverlayColor = UIColor.orange.withAlphaComponent(0.4)

    private let checkboxImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let selectionOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = PresentationTheme.current.colors.orangeUI
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0.4
        return view
    }()

    let thumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let newLabel: UILabel = {
        let label = UILabel()
        label.textColor = PresentationTheme.current.colors.orangeUI
        label.text = NSLocalizedString("NEW", comment: "")
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let titleLabel: VLCMarqueeLabel = {
        let label = VLCMarqueeLabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = PresentationTheme.current.colors.cellTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: VLCMarqueeLabel = {
        let label = VLCMarqueeLabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = PresentationTheme.current.colors.cellDetailTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let sizeLabel: VLCMarqueeLabel = {
        let label = VLCMarqueeLabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = PresentationTheme.current.colors.cellDetailTextColor
        label.minimumScaleFactor = 0.2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subDescriptionStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 3
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let descriptionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let separatorLabel = UILabel()

    override var media: VLCMLObject? {
        didSet {
            if let media = media as? VLCMLMedia {
                if media.subtype() == .albumTrack {
                    update(audioTrack: media)
                }
            } else if let album = media as? VLCMLAlbum {
                update(album:album)
            } else if let artist = media as? VLCMLArtist {
                update(artist: artist)
            } else if let playlist = media as? VLCMLPlaylist {
                update(playlist: playlist)
            } else if let genre = media as? VLCMLGenre {
                update(genre: genre)
            } else if let mediaGroup = media as? VLCMLMediaGroup {
                update(mediaGroup: mediaGroup)
            } else {
                assertionFailure("MediaGridCollectionCell: media: Needs to be of a supported Type.")
            }
        }
    }


    override var checkImageView: UIImageView? {
        return checkboxImageView
    }

    override var selectionViewOverlay: UIView? {
        return selectionOverlay
    }

    override var descriptionSeparatorLabel: UILabel? {
          return separatorLabel
      }

    override var secondDescriptionLabelView: UILabel? {
         return sizeLabel
     }

    override var isSelected: Bool {
        didSet {
            checkboxImageView.image = isSelected ? UIImage(named: "checkboxSelected")
                : UIImage(named: "checkboxEmpty")
        }
    }

    private var enableMarquee: Bool {
       return !userDefaults.bool(forKey: kVLCSettingEnableMediaCellTextScrolling)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupUI()
        setupNotificationObservers()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 11.0, *) {
            thumbnailView.accessibilityIgnoresInvertColors = true
        }
        clipsToBounds = true
        layer.cornerRadius = 2
        titleLabel.labelize = enableMarquee
        descriptionLabel.labelize = enableMarquee
        separatorLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        separatorLabel.setContentHuggingPriority(.required, for: .horizontal)
        sizeLabel.setContentHuggingPriority(.required, for: .horizontal)
        separatorLabel.font = sizeLabel.font
        separatorLabel.isHidden = true
        themeDidChange()
    }

    private func setupUI() {
        var guide: LayoutAnchorContainer = self
        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        thumbnailView.addSubview(checkboxImageView)
        addSubview(contentStackView)
        addSubview(selectionOverlay)
        addSubview(separatorLabel)

        contentStackView.addArrangedSubview(thumbnailView)
        descriptionStackView.addArrangedSubview(newLabel)
        subDescriptionStack.addArrangedSubview(sizeLabel)
        subDescriptionStack.addArrangedSubview(separatorLabel)
        subDescriptionStack.addArrangedSubview(descriptionLabel)
        descriptionStackView.addArrangedSubview(titleLabel)
        descriptionStackView.addArrangedSubview(subDescriptionStack)
        contentStackView.addArrangedSubview(descriptionStackView)


        NSLayoutConstraint.activate([
            thumbnailView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),
            thumbnailView.heightAnchor.constraint(equalTo: thumbnailView.widthAnchor),
            checkboxImageView.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -5),
            checkboxImageView.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -5),
            contentStackView.topAnchor.constraint(equalTo: guide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            selectionOverlay.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor),
            selectionOverlay.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor),
            selectionOverlay.topAnchor.constraint(equalTo: thumbnailView.topAnchor),
            selectionOverlay.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor),
        ])
        selectionOverlay.isHidden = true
        sizeLabel.isHidden = true 
        separatorLabel.isHidden = true
    }

    private func setupNotificationObservers() {
        notificationCenter.addObserver(self,
                                       selector: #selector(themeDidChange),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
    }

    @objc private func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        titleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        descriptionLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        configureShadows()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureShadows()
    }

// MARK: - Media Update Functions

    private func update(audioTrack: VLCMLMedia) {
        titleLabel.text = audioTrack.title()
        accessibilityLabel = audioTrack.accessibilityText(editing: false)
        var descriptionText = audioTrack.albumTrackArtistName()
        if let albumTitle = audioTrack.albumTrack?.album?.title, !albumTitle.isEmpty {
            descriptionText += " - " + albumTitle
        }
        descriptionLabel.text = descriptionText
        newLabel.isHidden = !audioTrack.isNew
        thumbnailView.image = audioTrack.thumbnailImage()
        sizeLabel.text = audioTrack.formatSize()
        sizeLabel.isHidden = true
        separatorLabel.text = "·"
        separatorLabel.isHidden = true
    }

    func update(album: VLCMLAlbum) {
        newLabel.isHidden = true
        titleLabel.text = album.albumName()
        accessibilityLabel = album.accessibilityText(editing: false)
        descriptionLabel.text = album.albumArtistName()
        thumbnailView.image = album.thumbnail()
    }

    private func update(artist: VLCMLArtist) {
        newLabel.isHidden = true
        titleLabel.text = artist.artistName()
        accessibilityLabel = artist.accessibilityText()
        descriptionLabel.text = artist.numberOfTracksString()
        thumbnailView.image = artist.thumbnail()
    }

    func update(playlist: VLCMLPlaylist) {
        newLabel.isHidden = true
        titleLabel.text = playlist.name
        accessibilityLabel = playlist.accessibilityText()
        descriptionLabel.text = playlist.numberOfTracksString()
        thumbnailView.image = playlist.thumbnail()
    }

    func update(mediaGroup: VLCMLMediaGroup) {
        newLabel.isHidden = true
        titleLabel.text = mediaGroup.title()
        accessibilityLabel = mediaGroup.accessibilityText()
        descriptionLabel.text = mediaGroup.numberOfTracksString()
        thumbnailView.image = mediaGroup.thumbnail()
    }

    func update(genre: VLCMLGenre) {
        newLabel.isHidden = true
        titleLabel.text = genre.name
        accessibilityLabel = genre.accessibilityText()
        thumbnailView.image = genre.thumbnail()
        descriptionLabel.text = genre.numberOfTracksString()
    }

    private func configureShadows() {
        if PresentationTheme.current.colors.isDark {
            clearShadow()
        } else {
            setShadow()
        }
    }

    private func setShadow() {
        thumbnailView.layer.shadowColor = PresentationTheme.current.colors.cellDetailTextColor.cgColor
        thumbnailView.layer.shadowOpacity = 0.7
        thumbnailView.layer.shadowOffset = .zero
        thumbnailView.layer.shadowRadius = 8
    }

    private func clearShadow() {
        thumbnailView.layer.shadowColor = UIColor.clear.cgColor
        thumbnailView.layer.shadowOpacity = 0
        thumbnailView.layer.shadowOffset = .zero
        thumbnailView.layer.shadowRadius = 0
    }


    override class func numberOfColumns(for width: CGFloat) -> CGFloat {
        if width <= DeviceWidth.iPhonePortrait.rawValue {
            return 2
        } else if width <= DeviceWidth.iPhoneLandscape.rawValue {
            return 3
        } else if width <= DeviceWidth.iPadLandscape.rawValue {
            return 4
        } else {
            return 5
        }
    }

    override class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        let numberOfCells: CGFloat = numberOfColumns(for: width)
        let aspectRatio: CGFloat = 1.0
        let overallWidth = width - (2 * edgePadding)
        let overallCellWidthWithoutPadding = overallWidth - (numberOfCells + 1) * interItemPadding
        let cellWidth = floor(overallCellWidthWithoutPadding / numberOfCells)

        // 16 * 2 for title, 14 for new + duration
        return CGSize(width: cellWidth, height: cellWidth * aspectRatio + (16 * 2) + 14 + (3 * 3))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        accessibilityLabel = ""
        descriptionLabel.text = ""
        titleLabel.labelize = enableMarquee
        descriptionLabel.labelize = enableMarquee
        thumbnailView.contentMode = .scaleAspectFit
        thumbnailView.image = nil
        descriptionLabel.isHidden = false
        newLabel.isHidden = true
        checkboxImageView.isHidden = true
        selectionOverlay.isHidden = true
        sizeLabel.isHidden = true
        separatorLabel.isHidden = true
        clearShadow()
    }
}
