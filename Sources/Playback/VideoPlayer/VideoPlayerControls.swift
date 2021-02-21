/*****************************************************************************
 * VideoPlayerControls.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2020 VideoLAN. All rights reserved.
 * Copyright © 2020 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
*****************************************************************************/

@objc (VLCVideoPlayerControlsDelgate)
protocol VideoPlayerControlsDelgate: AnyObject {
    // MARK: - Left Controls

    func videoPlayerControlsDelgateDidTapSubtitle(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelgateDidTapDVD(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelgateDidTapRotationLock(_ videoPlayerControls: VideoPlayerControls)

    // MARK: - Main Controls

    func videoPlayerControlsDelgateDidTapBackward(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelgateDidTapPreviousMedia(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelgateDidTapPlayPause(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelgateDidTapNextMedia(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelgateDidTapForeward(_ videoPlayerControls: VideoPlayerControls)

    // MARK: - Right Controls

    func videoPlayerControlsDelgateDidTapAspectRatio(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelgateDidMoreActions(_ videoPlayerControls: VideoPlayerControls)
}


class VideoPlayerControls: UIView {

    // MARK: - IB properties

    // MARK: - Left Controls

    @IBOutlet weak var subtitleButton: UIButton!
    
    @IBOutlet weak var dvdButton: UIButton!

    @IBOutlet weak var rotationLockButton: UIButton!

    // MARK: - Main Controls

    @IBOutlet weak var backwardButton: UIButton!

    @IBOutlet weak var previousMediaButton: UIButton!

    @IBOutlet weak var playPauseButton: UIButton!

    @IBOutlet weak var nextMediaButton: UIButton!

    @IBOutlet weak var forwardButton: UIButton!

    // MARK: - Right Controls

    @IBOutlet weak var aspectRatioButton: UIButton!

    @IBOutlet weak var moreActionsButton: UIButton!

    // MARK: -

    weak var delegate: VideoPlayerControlsDelgate?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setupAccessibility() {
        subtitleButton.accessibilityLabel = NSLocalizedString("SUBTITLE_AND_TRACK_BUTTON",
                                                              comment: "")
        subtitleButton.accessibilityHint = NSLocalizedString("SUBTITLE_AND_TRACK_HINT",
                                                             comment: "")

        dvdButton.accessibilityLabel = NSLocalizedString("DVD_BUTTON",
                                                         comment: "")
        dvdButton.accessibilityHint = NSLocalizedString("DVD_HINT",
                                                        comment: "")

        rotationLockButton.accessibilityLabel = NSLocalizedString("ROTATION_LOCK_BUTTON",
                                                                  comment: "")
        rotationLockButton.accessibilityHint = NSLocalizedString("ROTATION_LOCK_HINT",
                                                                 comment: "")

        backwardButton.accessibilityLabel = NSLocalizedString("BACKWARD_BUTTON",
                                                              comment: "")
        backwardButton.accessibilityHint = NSLocalizedString("BACKWARD_HINT",
                                                             comment: "")

        previousMediaButton.accessibilityLabel = NSLocalizedString("PREVIOUS_BUTTON",
                                                                   comment: "")
        previousMediaButton.accessibilityHint = NSLocalizedString("PREVIOUS_HINT",
                                                                  comment: "")

        playPauseButton.accessibilityLabel = NSLocalizedString("PLAY_PAUSE_BUTTON",
                                                               comment: "")
        playPauseButton.accessibilityHint = NSLocalizedString("PLAY_PAUSE_HINT",
                                                              comment: "")

        nextMediaButton.accessibilityLabel = NSLocalizedString("NEXT_BUTTON",
                                                               comment: "")
        nextMediaButton.accessibilityHint = NSLocalizedString("NEXT_HINT",
                                                              comment: "")

        forwardButton.accessibilityLabel = NSLocalizedString("FORWARD_BUTTON",
                                                             comment: "")
        forwardButton.accessibilityHint = NSLocalizedString("FORWARD_HINT",
                                                            comment: "")

        aspectRatioButton.accessibilityLabel = NSLocalizedString("VIDEO_ASPECT_RATIO_BUTTON",
                                                                 comment: "")
        aspectRatioButton.accessibilityHint = NSLocalizedString("VIDEO_ASPECT_RATIO_HINT",
                                                                comment: "")

        moreActionsButton.accessibilityLabel = NSLocalizedString("MORE_OPTIONS_BUTTON",
                                                                 comment: "")
        moreActionsButton.accessibilityHint = NSLocalizedString("MORE_OPTIONS_HINT",
                                                                comment: "")
    }

    func updatePlayPauseButton(toState isPlaying: Bool) {
        let imageName = isPlaying ? "pause-circle" : "play-circle"
        playPauseButton.setImage(UIImage(named: imageName), for: .normal)
    }
}

// MARK: - IB Actions

// MARK: - Left Controls

extension VideoPlayerControls {
    @IBAction func handleSubtitleButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelgateDidTapSubtitle(self)
    }

    @IBAction func handleDVDButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelgateDidTapDVD(self)
    }

    @IBAction func handleRotationLockButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelgateDidTapRotationLock(self)
    }
}

// MARK: - Main Controls

extension VideoPlayerControls {
    @IBAction func handleBackwardButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelgateDidTapBackward(self)
    }

    @IBAction func handlePreviousButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelgateDidTapPreviousMedia(self)
    }

    @IBAction func handlePlayPauseButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelgateDidTapPlayPause(self)
    }

    @IBAction func handleNextButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelgateDidTapNextMedia(self)
    }

    @IBAction func handleForwardButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelgateDidTapForeward(self)
    }
}

// MARK: - Right Controls

extension VideoPlayerControls {
    @IBAction func handleAspectRatioButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelgateDidTapAspectRatio(self)
    }

    @IBAction func handleMoreActionsButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelgateDidMoreActions(self)
    }
}
