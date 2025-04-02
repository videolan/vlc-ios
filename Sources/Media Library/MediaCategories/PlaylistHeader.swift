/*****************************************************************************
 * PlaylistHeader.swift
 *
 * Copyright © 2025 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class PlaylistHeader: UICollectionReusableView {
    // MARK: - Properties

    static var headerID = "playlistHeaderID"
    var sortModel: SortModel?
    var collection: VLCMLPlaylist?

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    private lazy var buttonStackView: UIStackView = {
        let buttonStackView = UIStackView()
        buttonStackView.backgroundColor = PresentationTheme.current.colors.background
        buttonStackView.spacing = 20
        buttonStackView.distribution = .fillEqually
        buttonStackView.alignment = .center
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        return buttonStackView
    }()

    private lazy var playAllButton: UIButton = {
        let playAllButton = UIButton(type: .custom)
        playAllButton.tag = 0
        playAllButton.setImage(UIImage(named: "iconPlay")?.withRenderingMode(.alwaysTemplate), for: .normal)
        playAllButton.clipsToBounds = true
        playAllButton.tintColor = .white
        playAllButton.layer.cornerRadius = 5
        playAllButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        playAllButton.backgroundColor = PresentationTheme.current.colors.orangeUI
        playAllButton.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        playAllButton.translatesAutoresizingMaskIntoConstraints = false
        return playAllButton
    }()

    private lazy var playShuffleButton: UIButton = {
        let playShuffleButton = UIButton(type: .custom)
        playShuffleButton.tag = 1
        playShuffleButton.setImage(UIImage(named: "shuffle"), for: .normal)
        playShuffleButton.clipsToBounds = true
        playShuffleButton.tintColor = .white
        playShuffleButton.layer.cornerRadius = 5
        playShuffleButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        playShuffleButton.backgroundColor = PresentationTheme.current.colors.orangeUI
        playShuffleButton.addTarget(self, action: #selector(handlePlayAllShuffle), for: .touchUpInside)
        playShuffleButton.translatesAutoresizingMaskIntoConstraints = false
        return playShuffleButton
    }()

    private var playAllButtonWidthConstraint: NSLayoutConstraint?
    private var shuffleButtonWidthConstraint: NSLayoutConstraint?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PresentationTheme.current.colors.background

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(buttonStackView)

        buttonStackView.addArrangedSubview(playAllButton)
        buttonStackView.addArrangedSubview(playShuffleButton)

#if os(iOS)
        if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
            setupLandscapeConstraint()
        } else {
            setupConstraints()
        }
#else
        setupConstraints()
#endif

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods

    private func setupConstraints() {
        let buttonSize: CGFloat = 50.0

        playAllButton.setTitle(nil, for: .normal)
        playShuffleButton.setTitle(nil, for: .normal)

        playAllButtonWidthConstraint = playAllButton.widthAnchor.constraint(equalToConstant: buttonSize)
        shuffleButtonWidthConstraint = playShuffleButton.widthAnchor.constraint(equalToConstant: buttonSize)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),

            buttonStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            buttonStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: buttonSize),

            playAllButton.heightAnchor.constraint(equalToConstant: buttonSize),
            playAllButtonWidthConstraint!,

            playShuffleButton.heightAnchor.constraint(equalToConstant: buttonSize),
            shuffleButtonWidthConstraint!
        ])
    }

    private func setupLandscapeConstraint() {
        let buttonSize: CGFloat = 50.0

        playAllButton.setTitle(NSLocalizedString("PLAY_BUTTON", comment: ""), for: .normal)
        playShuffleButton.setTitle(NSLocalizedString("SHUFFLE", comment: ""), for: .normal)

        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 70),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),

            titleLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 50),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -80),

            buttonStackView.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: buttonSize),
            buttonStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),

            playAllButton.heightAnchor.constraint(equalToConstant: buttonSize),
            playShuffleButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }

    private func updateConstraintsAfterRotation() {
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(buttonStackView)

        buttonStackView.addArrangedSubview(playAllButton)
        buttonStackView.addArrangedSubview(playShuffleButton)

#if os(iOS)
        if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
            setupLandscapeConstraint()
        } else {
            setupConstraints()
        }
#else
        setupConstraints()
#endif
    }

    private func playAll(shuffle: Bool) {
        guard let playlist = collection,
              let sortModel = sortModel else {
            return
        }

        let playbackService = PlaybackService.sharedInstance()
        playbackService.isShuffleMode = shuffle

        let media = playlist.files(with: sortModel.currentSort, desc: sortModel.desc)
        playbackService.playCollection(media)
    }

    // MARK: - Methods

    static func getHeaderSize(with width: CGFloat) -> CGSize {
#if os(iOS)
        let isLandscape: Bool = UIDevice.current.orientation.isLandscape
        let headerHeight: CGFloat = isLandscape ? 250.0 : 370.0
#else
        let headerHeight: CGFloat = 350.0
#endif
        return CGSize(width: width, height: headerHeight)
    }

    func updateImage(with image: UIImage?) {
        guard let image = image else {
            return
        }

        imageView.image = image
    }

    func updateTitle(with title: String) {
        titleLabel.text = title
    }

    func updateAfterRotation() {
        playAllButton.removeFromSuperview()
        playShuffleButton.removeFromSuperview()
        imageView.removeFromSuperview()
        titleLabel.removeFromSuperview()
        buttonStackView.removeFromSuperview()

        if let playAllButtonWidthConstraint = playAllButtonWidthConstraint,
           let shuffleButtonWidthConstraint = shuffleButtonWidthConstraint {
            playAllButton.removeConstraint(playAllButtonWidthConstraint)
            playShuffleButton.removeConstraint(shuffleButtonWidthConstraint)
            self.playAllButtonWidthConstraint = nil
            self.shuffleButtonWidthConstraint = nil
        }

        updateConstraintsAfterRotation()
    }

    // MARK: - Actions

    @objc private func handlePlay() {
        playAll(shuffle: false)
    }

    @objc private func handlePlayAllShuffle() {
        playAll(shuffle: true)
    }

    @objc private func themeDidChange() {
        let colors = PresentationTheme.current.colors
        backgroundColor = colors.background
        titleLabel.textColor = colors.cellTextColor
        buttonStackView.backgroundColor = colors.background
    }
}
