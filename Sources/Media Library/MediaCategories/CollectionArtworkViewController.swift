/*****************************************************************************
 * CollectionArtworkViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@available(iOS 27.1, visionOS 27.1, *)
class CollectionArtworkViewController: UIViewController {
    private static let margin: CGFloat = 20.0
    private static let spacing: CGFloat = 16.0
    private static let buttonSpacing: CGFloat = 12.0
    private static let minimumButtonHeight: CGFloat = 50.0

    private let model: CollectionModel
    private let imageView = VLCArtworkImageView()
    private let titleLabel = UILabel()
    private let playAllButton = UIButton(type: .system)
    private let playShuffleButton = UIButton(type: .system)
    private lazy var artworkAspectRatioConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)

    init(model: CollectionModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12.0
        imageView.layer.cornerCurve = .continuous
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2).bolded
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 3
        titleLabel.textAlignment = .center
        titleLabel.accessibilityTraits = .header
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        setupButton(playAllButton,
                    title: NSLocalizedString("PLAY_BUTTON", comment: ""),
                    hint: NSLocalizedString("PLAY_ALL_HINT", comment: ""),
                    image: UIImage(named: "iconPlay"),
                    action: #selector(handlePlayAll))
        setupButton(playShuffleButton,
                    title: NSLocalizedString("SHUFFLE", comment: ""),
                    hint: NSLocalizedString("SHUFFLE_HINT", comment: ""),
                    image: UIImage(named: "shuffle"),
                    action: #selector(handlePlayAllShuffle))

        setupConstraints()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
        themeDidChange()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    func reloadData() {
        guard isViewLoaded else {
            return
        }

        if let album = model.mediaCollection as? VLCMLAlbum {
            imageView.setImage(album.thumbnail(), placeholderName: album.placeholderName())
            titleLabel.text = album.albumName()
        } else if let playlist = model.mediaCollection as? VLCMLPlaylist {
            imageView.setImage(playlist.thumbnailImage(), placeholderName: playlist.placeholderName())
            titleLabel.text = playlist.title()
        }

        let hasFiles = !model.files.isEmpty
        playAllButton.isEnabled = hasFiles
        playShuffleButton.isEnabled = hasFiles

        updateArtworkAspectRatio()
    }

    private func updateArtworkAspectRatio() {
        var multiplier: CGFloat = 1.0
        if let size = imageView.image?.size, size.width > 0, size.height > 0 {
            multiplier = size.height / size.width
        }

        guard artworkAspectRatioConstraint.multiplier != multiplier else {
            return
        }

        artworkAspectRatioConstraint.isActive = false
        artworkAspectRatioConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: multiplier)
        artworkAspectRatioConstraint.isActive = true
    }

    private func setupButton(_ button: UIButton, title: String, hint: String, image: UIImage?, action: Selector) {
#if os(visionOS)
        var configuration = UIButton.Configuration.filled()
#else
        var configuration = UIButton.Configuration.prominentGlass()
#endif
        configuration.baseBackgroundColor = PresentationTheme.current.colors.orangeUI
        configuration.baseForegroundColor = .white
        configuration.title = title
        configuration.image = image?.withRenderingMode(.alwaysTemplate)
        configuration.imagePadding = 8.0
        configuration.cornerStyle = .capsule
        button.configuration = configuration
        button.accessibilityHint = hint
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
    }

    private func setupConstraints() {
        let margin = CollectionArtworkViewController.margin
        let spacing = CollectionArtworkViewController.spacing
        let safeArea = view.safeAreaLayoutGuide

        let contentGuide = UILayoutGuide()
        view.addLayoutGuide(contentGuide)

        let preferredArtworkWidth = imageView.widthAnchor.constraint(equalTo: contentGuide.widthAnchor)
        preferredArtworkWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            contentGuide.topAnchor.constraint(greaterThanOrEqualTo: safeArea.topAnchor, constant: margin),
            contentGuide.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor, constant: -margin),
            contentGuide.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            contentGuide.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: margin),
            contentGuide.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -margin),

            imageView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentGuide.centerXAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: contentGuide.widthAnchor),
            preferredArtworkWidth,
            artworkAspectRatioConstraint,

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: spacing),
            titleLabel.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),

            playAllButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: spacing),
            playAllButton.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            playAllButton.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            playAllButton.heightAnchor.constraint(greaterThanOrEqualToConstant: CollectionArtworkViewController.minimumButtonHeight),

            playShuffleButton.leadingAnchor.constraint(equalTo: playAllButton.trailingAnchor,
                                                       constant: CollectionArtworkViewController.buttonSpacing),
            playShuffleButton.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            playShuffleButton.topAnchor.constraint(equalTo: playAllButton.topAnchor),
            playShuffleButton.bottomAnchor.constraint(equalTo: playAllButton.bottomAnchor),
            playShuffleButton.widthAnchor.constraint(equalTo: playAllButton.widthAnchor)
        ])
    }

    private func playAll(shuffle: Bool) {
        let playbackService = PlaybackService.sharedInstance()

        if let album = model.mediaCollection as? VLCMLAlbum {
            playbackService.isShuffleMode = shuffle
            playbackService.playCollection(album.tracks)
        } else if let playlist = model.mediaCollection as? VLCMLPlaylist {
            let sortModel = model.sortModel
            playbackService.isShuffleMode = shuffle
            playbackService.playCollection(playlist.files(with: sortModel.currentSort, desc: sortModel.desc))
        }
    }

    @objc private func themeDidChange() {
        let colors = PresentationTheme.current.colors
        view.backgroundColor = colors.background
        titleLabel.textColor = colors.cellTextColor
    }

    @objc private func handlePlayAll() {
        playAll(shuffle: false)
    }

    @objc private func handlePlayAllShuffle() {
        playAll(shuffle: true)
    }
}
