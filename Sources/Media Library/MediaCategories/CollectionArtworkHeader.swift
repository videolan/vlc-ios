/*****************************************************************************
 * CollectionArtworkHeader.swift
 *
 * Copyright © 2022 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class CollectionArtworkHeader: UICollectionReusableView {
    // MARK: - Properties

    static var headerID = "headerID"

    private weak var parentView: UIView?

    private var imageView = UIImageView()

    private var titleLabel = UILabel()

    var collection: VLCMLObject?

    var sortModel: SortModel?

    private var playAllButton = UIButton(type: .custom)

    private var playShuffleButton = UIButton(type: .custom)

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PresentationTheme.current.colors.background
        setupImageView()
        setupTitleLabel()
        setupPlayAllButton()
        setupShuffleButton()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods

    private func setupImageView() {
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
    }

    private func setupTitleLabel() {
        addSubview(titleLabel)
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title3).bolded
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        updateTitleColor()
    }

    private func updateTitleColor() {
        // Over the dark gradient of the artwork a light color is needed, without
        // artwork the plain background requires the regular one.
        let colors = imageView.image != nil ? PresentationTheme.darkTheme.colors
                                            : PresentationTheme.current.colors
        titleLabel.textColor = colors.cellTextColor
    }

    private func setupPlayAllButton() {
        addSubview(playAllButton)
        let buttonSize: CGFloat = 50.0
        playAllButton.tag = 0
        playAllButton.translatesAutoresizingMaskIntoConstraints = false
        applyGlassStyle(to: playAllButton,
                        image: UIImage(named: "iconPlay")?.withRenderingMode(.alwaysTemplate),
                        size: buttonSize)
        playAllButton.addTarget(self, action: #selector(handlePlayAll(sender:)), for: .touchUpInside)
    }

    private func setupShuffleButton() {
        addSubview(playShuffleButton)
        let buttonSize: CGFloat = 50.0
        playShuffleButton.tag = 1
        playShuffleButton.translatesAutoresizingMaskIntoConstraints = false
        applyGlassStyle(to: playShuffleButton,
                        image: UIImage(named: "shuffle"),
                        size: buttonSize)
        playShuffleButton.addTarget(self, action: #selector(handlePlayAllShuffle(sender:)), for: .touchUpInside)
    }

    private func applyGlassStyle(to button: UIButton, image: UIImage?, size: CGFloat) {
#if !os(visionOS)
        if #available(iOS 26.0, *) {
            var config: UIButton.Configuration = .prominentGlass()
            config.baseBackgroundColor = PresentationTheme.current.colors.orangeUI
            config.baseForegroundColor = .white
            config.image = image
            config.cornerStyle = .capsule
            button.configuration = config
            return
        }
#endif
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 0.5 * size
        button.clipsToBounds = true
        button.backgroundColor = PresentationTheme.current.colors.orangeUI
    }

    private func setupConstraints() {
        let buttonSize: CGFloat = 50.0
        let playShuffleTrailingAnchor: NSLayoutConstraint
        let titleLeadingAnchor: NSLayoutConstraint
        if let parentView {
            playShuffleTrailingAnchor = playShuffleButton.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor, constant: -20)
            titleLeadingAnchor = titleLabel.leadingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        } else {
            playShuffleTrailingAnchor = playShuffleButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
            titleLeadingAnchor = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
        }

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLeadingAnchor,
            titleLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),

            playAllButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 10),
            playAllButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),
            playAllButton.heightAnchor.constraint(equalToConstant: buttonSize),
            playAllButton.widthAnchor.constraint(equalTo: playAllButton.heightAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: playAllButton.centerYAnchor),

            playShuffleButton.leadingAnchor.constraint(equalTo: playAllButton.trailingAnchor, constant: 10),
            playShuffleButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),
            playShuffleTrailingAnchor,
            playShuffleButton.heightAnchor.constraint(equalToConstant: buttonSize),
            playShuffleButton.widthAnchor.constraint(equalTo: playShuffleButton.heightAnchor),
            playShuffleButton.centerYAnchor.constraint(equalTo: playAllButton.centerYAnchor)
        ])
    }

    private func playAll(shuffle: Bool) {
        let playbackService = PlaybackService.sharedInstance()

        if let album = collection as? VLCMLAlbum {
            playbackService.isShuffleMode = shuffle
            playbackService.playCollection(album.tracks)
        } else if let playlist = collection as? VLCMLPlaylist, let sortModel = sortModel {
            playbackService.isShuffleMode = shuffle
            playbackService.playCollection(playlist.files(with: sortModel.currentSort, desc: sortModel.desc))
        }
    }

    // MARK: - Methods

    func updateImage(with image: UIImage?) {
        imageView.image = image?.imageWithGradient()
        updateTitleColor()
    }

    func updateThumbnailTitle(_ title: String) {
        titleLabel.text = title
    }

    func shouldDisablePlayButtons(_ disable: Bool) {
        playAllButton.isEnabled = !disable
        playShuffleButton.isEnabled = !disable
    }

    func updateParentView(parent: UIView) {
        parentView = parent
        removeConstraints(self.constraints)
        setupConstraints()
    }

    func updateTheme() {
        backgroundColor = PresentationTheme.current.colors.background
        updateTitleColor()
    }

    // MARK: - Actions

    @objc func handlePlayAll(sender: UIButton) {
        playAll(shuffle: false)
    }

    @objc func handlePlayAllShuffle(sender: UIButton) {
        playAll(shuffle: true)
    }
}
