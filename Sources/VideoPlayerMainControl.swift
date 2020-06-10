/*****************************************************************************
 * VideoPlayerMainControl.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc (VLCVideoPlayerMainControl)
@objcMembers class VideoPlayerMainControl: UIStackView {
    
    // MARK: Instance Variables
    private let playbackController = PlaybackService.sharedInstance()
    private let JUMP_DURATION: Int32 = 10
    
    lazy var playPauseButton: UIButton = {
        var playBtn = UIButton(type: .system)
        playBtn.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        playBtn.setImage(UIImage(named: "iconPauseLarge"), for: .normal)
        playBtn.tintColor = .white
        return playBtn
    }()
    
    lazy var skipForwardButton: UIButton = {
        var fwdButton = UIButton(type: .system)
        fwdButton.setImage(UIImage(named: "iconSkipForward"), for: .normal)
        fwdButton.addTarget(self, action: #selector(skipForward), for: .touchUpInside)
        fwdButton.tintColor = .white
        return fwdButton
    }()
    
    lazy var skipBackwardButton: UIButton = {
        var bwdButton = UIButton(type: .system)
        bwdButton.setImage(UIImage(named: "iconSkipBack"), for: .normal)
        bwdButton.addTarget(self, action: #selector(skipBackward), for: .touchUpInside)
        bwdButton.tintColor = .white
        return bwdButton
    }()
    
    lazy var skipToPreviousMediaButton: UIButton = {
        var previousMediaButton = UIButton(type: .system)
        previousMediaButton.setImage(UIImage(named: "iconPreviousVideo"), for: .normal)
        previousMediaButton.addTarget(self, action: #selector(skipToPreviousMedia), for: .touchUpInside)
        previousMediaButton.tintColor = .white
        return previousMediaButton
    }()
    
    lazy var skipToNextMediaButton: UIButton = {
        var nextMediaButton = UIButton(type: .system)
        nextMediaButton.setImage(UIImage(named: "iconNextVideo"), for: .normal)
        nextMediaButton.addTarget(self, action: #selector(skipToNextMedia), for: .touchUpInside)
        nextMediaButton.tintColor = .white
        return nextMediaButton
    }()
    
    // MARK: Initializers
    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addObsersers()
        setupViews()
    }

    // MARK: Methods
    private func setupViews() {
        spacing = 20
        distribution = .equalCentering
        addArrangedSubview(skipBackwardButton)
        addArrangedSubview(skipToPreviousMediaButton)
        addArrangedSubview(playPauseButton)
        addArrangedSubview(skipToNextMediaButton)
        addArrangedSubview(skipForwardButton)
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func addObsersers() {
        let resumeNotification = Notification.Name(rawValue: VLCPlaybackServicePlaybackDidResume)
        let pauseNotification = Notification.Name(rawValue: VLCPlaybackServicePlaybackDidPause)
        let playbackStartNotification = Notification.Name(rawValue: VLCPlaybackServicePlaybackDidStart)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNotification(_:)),
                                               name: resumeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNotification(_:)),
                                               name: pauseNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNotification(_:)),
                                               name: playbackStartNotification,
                                               object: nil)
    }

    @objc private func handleNotification(_ notification: Notification) {
        var isPlaying = notification.name.rawValue == VLCPlaybackServicePlaybackDidResume
        isPlaying = isPlaying || notification.name.rawValue == VLCPlaybackServicePlaybackDidStart
        let image = isPlaying ? UIImage(named: "iconPauseLarge") : UIImage(named: "iconPlayLarge")
        playPauseButton.setImage(image, for: .normal)
    }
    
    // MARK: Button Action Methods
    func togglePlayPause() {
        playbackController.playPause()
    }
    
    func skipForward() {
        playbackController.jumpForward(JUMP_DURATION)
    }
    
    func skipBackward() {
        playbackController.jumpBackward(JUMP_DURATION)
    }
    
    func skipToPreviousMedia() {
        playbackController.next()
    }
    
    func skipToNextMedia() {
        playbackController.previous()
    }
}
