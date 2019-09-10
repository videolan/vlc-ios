/*****************************************************************************
 * AudioMiniPlayer.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc(VLCAudioMiniPlayer)
class AudioMiniPlayer: UIView, MiniPlayer {
    var visible: Bool = false
    var contentHeight: Float {
        return 72.0
    }

    @IBOutlet private weak var audioMiniPlayer: UIView!
    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!
    @IBOutlet private weak var progressBarView: UIProgressView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var previousButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!

    private var mediaService: MediaLibraryService
    private lazy var playbackController = PlaybackService.sharedInstance()

    @objc init(service: MediaLibraryService) {
        self.mediaService = service
        super.init(frame: .zero)
        initView()
        setupConstraint()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updatePlayPauseButton() {
        let imageName = playbackController.isPlaying ? "MiniPause" : "MiniPlay"
        playPauseButton.imageView?.image = UIImage(named: imageName)
    }
}

// MARK: - Private initializers

private extension AudioMiniPlayer {
    private func initView() {
        Bundle.main.loadNibNamed("AudioMiniPlayer", owner: self, options: nil)
        addSubview(audioMiniPlayer)

        audioMiniPlayer.clipsToBounds = true
        audioMiniPlayer.layer.cornerRadius = 4

        progressBarView.clipsToBounds = true
        progressBarView.layer.cornerRadius = 1

        if #available(iOS 11.0, *) {
            artworkImageView.accessibilityIgnoresInvertColors = true
        }
        artworkImageView.clipsToBounds = true
        artworkImageView.layer.cornerRadius = 2

        playPauseButton.accessibilityLabel = NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")
        nextButton.accessibilityLabel = NSLocalizedString("NEXT_BUTTON", comment: "")
        previousButton.accessibilityLabel = NSLocalizedString("PREV_BUTTON", comment: "")
    }

    private func setupConstraint() {
        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        audioMiniPlayer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([audioMiniPlayer.leadingAnchor.constraint(equalTo: guide.leadingAnchor,
                                                                              constant: 8),
                                     audioMiniPlayer.trailingAnchor.constraint(equalTo: guide.trailingAnchor,
                                                                               constant: -8),
                                     audioMiniPlayer.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                                             constant: -8),
                                     ])
    }
}

// MARK: - VLCPlaybackServiceDelegate

extension AudioMiniPlayer {
    func prepare(forMediaPlayback playbackService: PlaybackService) {
        updatePlayPauseButton()
        playbackService.delegate = self
        playbackService.recoverDisplayedMetadata()
        // For now, AudioMiniPlayer will be used for all media
        playbackService.videoOutputView = artworkImageView
    }

    func mediaPlayerStateChanged(_ currentState: VLCMediaPlayerState,
                                 isPlaying: Bool,
                                 currentMediaHasTrackToChooseFrom: Bool,
                                 currentMediaHasChapters: Bool,
                                 for playbackService: PlaybackService) {
        updatePlayPauseButton()
    }

    func displayMetadata(for playbackService: PlaybackService, metadata: VLCMetaData) {
        setMediaInfo(metadata)
    }

    func playbackPositionUpdated(_ playbackService: PlaybackService) {
        progressBarView.progress = playbackService.playbackPosition
    }

    func savePlaybackState(_ playbackService: PlaybackService) {
        mediaService.savePlaybackState(from: playbackService)
    }

    func media(forPlaying media: VLCMedia?) -> VLCMLMedia? {
        guard let media = media else {
            return nil
        }

        return mediaService.fetchMedia(with: media.url)
    }
}

// MARK: - UI Receivers

private extension AudioMiniPlayer {
    @IBAction private func handlePrevious(_ sender: UIButton) {
        playbackController.previous()
    }

    @IBAction private func handlePlayPause(_ sender: UIButton) {
        playbackController.playPause()
    }

    @IBAction private func handleNext(_ sender: UIButton) {
        playbackController.next()
    }

    @IBAction private func handleFullScreen(_ sender: Any) {
        UIApplication.shared.sendAction(#selector(VLCPlayerDisplayController.showFullscreenPlayback),
                                        to: nil,
                                        from: self,
                                        for: nil)
    }

    @IBAction private func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case .right:
            playbackController.previous()
        case .left:
            playbackController.next()
        default:
            break
        }
    }

    @IBAction private func handleLongPressPlayPause(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        // case .began:
        // In the case of .began we could a an icon like the old miniplayer
        case .ended:
            playbackController.stopPlayback()
        case .cancelled, .failed:
            playbackController.playPause()
            updatePlayPauseButton()
        default:
            break
        }
    }

    @IBAction private func handleDismiss(_ sender: UISwipeGestureRecognizer) {
        playbackController.stopPlayback()
    }
}

// MARK: - Setters

private extension AudioMiniPlayer {
    private func setMediaInfo(_ metadata: VLCMetaData) {
        titleLabel.text = metadata.title
        artistLabel.text = metadata.artist
        if metadata.isAudioOnly {
            artworkImageView.image = metadata.artworkImage ?? UIImage(named: "no-artwork")
        }
    }
}
