/*****************************************************************************
 * MediaPlaybackControlToolbar.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

// MARK: Protocol definition
@objc (VLCMediaPlaybackControlToolbarDelegate)
protocol MediaPlaybackControlToolbarDelegate: class {
    func mediaPlaybackControlDidTogglePlayPause(_ mediaPlaybackControlToolbar: MediaPlaybackControlToolbar)
    func mediaPlaybackControlDidSkipForward(_ mediaPlaybackControlToolbar: MediaPlaybackControlToolbar)
    func mediaPlaybackControlDidSkipBackward(_ mediaPlaybackControlToolbar: MediaPlaybackControlToolbar)
    func mediaPlaybackControlDidSkipToNextMedia(_ mediaPlaybackControlToolbar: MediaPlaybackControlToolbar)
    func mediaPlaybackControlDidSkipToPreviousMedia(_ mediaPlaybackControlToolbar: MediaPlaybackControlToolbar)
}

@objc (VLCMediaPlaybackControlToolbar)
@objcMembers class MediaPlaybackControlToolbar: UIStackView {
    
    // MARK: Instance Variables
    weak var delegate: MediaPlaybackControlToolbarDelegate?
    
    lazy var playPauseButton: UIButton = {
        var playBtn = UIButton(type: .system)
        playBtn.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        playBtn.setImage(UIImage(named: "iconPause"), for: .normal)
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
        bwdButton.setImage(UIImage(named: "iconSkipBackward"), for: .normal)
        bwdButton.addTarget(self, action: #selector(skipBackward), for: .touchUpInside)
        bwdButton.tintColor = .white
        return bwdButton
    }()
    
    lazy var skipToPreviousMediaButton: UIButton = {
        var previousMediaButton = UIButton(type: .system)
        previousMediaButton.setImage(UIImage(named: "iconSkipToPrevious"), for: .normal)
        previousMediaButton.addTarget(self, action: #selector(skipForward), for: .touchUpInside)
        previousMediaButton.tintColor = .white
        return previousMediaButton
    }()
    
    lazy var skipToNextMediaButton: UIButton = {
        var nextMediaButton = UIButton(type: .system)
        nextMediaButton.setImage(UIImage(named: "iconSkipToNext"), for: .normal)
        nextMediaButton.addTarget(self, action: #selector(skipForward), for: .touchUpInside)
        nextMediaButton.tintColor = .white
        return nextMediaButton
    }()
    
    var isPlaying: Bool {
        didSet {
            if isPlaying {
                playPauseButton.setImage(UIImage(named: "iconPause"), for: .normal)
            } else {
                playPauseButton.setImage(UIImage(named: "iconPlay"), for: .normal)
            }
        }
    }
    
    // MARK: Initializers
    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override init(frame: CGRect) {
        isPlaying = true
        super.init(frame: frame)
        axis = .horizontal
        addArrangedSubview(skipBackwardButton)
        addArrangedSubview(skipToPreviousMediaButton)
        addArrangedSubview(playPauseButton)
        addArrangedSubview(skipToNextMediaButton)
        addArrangedSubview(skipForwardButton)
    }
    
    // MARK: Button Action Methods
    func togglePlayPause() {
        assert(delegate != nil, "Delegate for MediaPlaybackControlToolBar not set.")
        delegate?.mediaPlaybackControlDidTogglePlayPause(self)
    }
    
    func skipForward() {
        assert(delegate != nil, "Delegate for MediaPlaybackControlToolBar not set.")
        delegate?.mediaPlaybackControlDidSkipForward(self)
    }
    
    func skipBackward() {
        assert(delegate != nil, "Delegate for MediaPlaybackControlToolBar not set.")
        delegate?.mediaPlaybackControlDidSkipBackward(self)
    }
    
    func skipToPreviousMedia() {
        assert(delegate != nil, "Delegate for MediaPlaybackControlToolBar not set.")
        delegate?.mediaPlaybackControlDidSkipToPreviousMedia(self)
    }
    
    func skipToNextMedia() {
        assert(delegate != nil, "Delegate for MediaPlaybackControlToolBar not set.")
        delegate?.mediaPlaybackControlDidSkipToNextMedia(self)
    }
}
