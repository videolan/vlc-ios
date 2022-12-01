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

@objc (VLCVideoPlayerControlsDelegate)
protocol VideoPlayerControlsDelegate: AnyObject {
    // MARK: - Left Controls

    func videoPlayerControlsDelegateDidTapSubtitle(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapDVD(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapRotationLock(_ videoPlayerControls: VideoPlayerControls)

    // MARK: - Main Controls

    func videoPlayerControlsDelegateDidTapBackward(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapPreviousMedia(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapPlayPause(_ videoPlayerControls: VideoPlayerControls)
    @objc optional func videoPlayerControlsDelegateDidLongPressPlayPauseBegan(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidLongPressPlayPauseEnded(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapNextMedia(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidTapForeward(_ videoPlayerControls: VideoPlayerControls)

    // MARK: - Right Controls

    func videoPlayerControlsDelegateDidTapAspectRatio(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateDidMoreActions(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateShuffle(_ videoPlayerControls: VideoPlayerControls)
    func videoPlayerControlsDelegateRepeat(_ videoPlayerControls: VideoPlayerControls)
}


class VideoPlayerControls: UIView {

    // MARK: - IB properties

    // MARK: - Left Controls

    @IBOutlet weak var subtitleButton: UIButton!
    
    @IBOutlet weak var dvdButton: UIButton!

    @IBOutlet weak var rotationLockButton: UIButton!

    @IBOutlet weak var repeatButton: UIButton!
    // MARK: - Main Controls

    @IBOutlet weak var backwardButton: UIButton!

    @IBOutlet weak var previousMediaButton: UIButton!

    @IBOutlet weak var playPauseButton: UIButton!

    @IBOutlet weak var nextMediaButton: UIButton!

    @IBOutlet weak var forwardButton: UIButton!

    // MARK: - Right Controls

    @IBOutlet weak var aspectRatioButton: UIButton!

    @IBOutlet weak var moreActionsButton: UIButton!

    @IBOutlet weak var shuffleButton: UIButton!
    // MARK: -

    weak var delegate: VideoPlayerControlsDelegate?

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
        
        repeatButton.accessibilityLabel = NSLocalizedString("REPEAT_MODE",
                                                            comment: "")
        repeatButton.accessibilityHint = NSLocalizedString("REPEAT_HINT",
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

        shuffleButton.accessibilityLabel = NSLocalizedString("SHUFFLE",
                                                             comment: "")
        shuffleButton.accessibilityHint = NSLocalizedString("SHUFFLE_HINT",
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

    func shouldDisableControls(_ disable: Bool) {
        subtitleButton.isEnabled = !disable
        dvdButton.isEnabled = !disable
        rotationLockButton.isEnabled = !disable
        repeatButton.isEnabled = !disable
        backwardButton.isEnabled = !disable
        previousMediaButton.isEnabled = !disable
        nextMediaButton.isEnabled = !disable
        forwardButton.isEnabled = !disable
        aspectRatioButton.isEnabled = !disable
        moreActionsButton.isEnabled = !disable
        shuffleButton.isEnabled = !disable
    }
}

// MARK: - IB Actions

// MARK: - Left Controls

extension VideoPlayerControls {
    @IBAction func handleSubtitleButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapSubtitle(self)
    }

    @IBAction func handleDVDButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapDVD(self)
    }

    @IBAction func handleRotationLockButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapRotationLock(self)
    }
    @IBAction func handleRepeatButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateRepeat(self)
    }
}

// MARK: - Main Controls

extension VideoPlayerControls {
    @IBAction func handleBackwardButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapBackward(self)
    }

    @IBAction func handlePreviousButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapPreviousMedia(self)
    }

    @IBAction func handlePlayPauseButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapPlayPause(self)
    }

    @IBAction func handlePlayPauseLongPressButton(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            delegate?.videoPlayerControlsDelegateDidLongPressPlayPauseBegan?(self)
        case .ended:
            delegate?.videoPlayerControlsDelegateDidLongPressPlayPauseEnded(self)
        case .cancelled, .failed:
            delegate?.videoPlayerControlsDelegateDidTapPlayPause(self)
        default:
            break
        }
    }

    @IBAction func handleNextButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapNextMedia(self)
    }

    @IBAction func handleForwardButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapForeward(self)
    }
}

// MARK: - Right Controls

extension VideoPlayerControls {
    @IBAction func handleAspectRatioButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidTapAspectRatio(self)
    }

    @IBAction func handleMoreActionsButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateDidMoreActions(self)
    }

    @IBAction func handleShuffleButton(_ sender: Any) {
        delegate?.videoPlayerControlsDelegateShuffle(self)
    }
}
