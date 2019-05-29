/*****************************************************************************
 * VideoOptionsControlBar.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc (VideoOptionsControlBarDelegate)
protocol VideoOptionsControlBarDelegate: class {
    func didToggleFullScreen(_ optionsBar: VideoOptionsControlBar)
    func didToggleRepeat(_ optionsBar: VideoOptionsControlBar)
    func didSelectSubtitle(_ optionsBar: VideoOptionsControlBar)
    func didSelectMoreOptions(_ optionsBar: VideoOptionsControlBar)
    func didToggleOrientationLock(_ optionsBar: VideoOptionsControlBar)
}

@objc (VLCVideoOptionsControlBar)
@objcMembers class VideoOptionsControlBar: UIStackView {
    
    // MARK: Instance variables
    weak var delegate: VideoOptionsControlBarDelegate?
    
    lazy var toggleFullScreenButton: UIButton = {
        var toggle = UIButton(type: .system)
        toggle.addTarget(self, action: #selector(toggleFullscreen), for: .touchUpInside)
        toggle.setImage(UIImage(named: "fullscreenIcon-new"), for: .normal)
        toggle.tintColor = .orange
        //TODO: add accessability options for fullScreenButton
        return toggle
    }()
    
    lazy var selectSubtitleButton: UIButton = {
        var subbutton = UIButton(type: .system)
        subbutton.addTarget(self, action: #selector(selectSubtitle), for: .touchUpInside)
        subbutton.setImage(UIImage(named: "subtitleIcon-new"), for: .normal)
        subbutton.tintColor = .orange
        //TODO: add accessability options for selectingSubtitleButton
        return subbutton
    }()
    
    lazy var repeatButton: UIButton = {
        var rptButton = UIButton(type: .system)
        rptButton.addTarget(self, action: #selector(toggleRepeat), for: .touchUpInside)
        rptButton.setImage(UIImage(named: "repeatOne-new"), for: .normal)
        rptButton.tintColor = .orange
        //TODO: add accessability options for repeatButton
        return rptButton
    }()
    
    lazy var orientationLockButton: UIButton = {
        var orientLockButton = UIButton(type: .system)
        orientLockButton.addTarget(self, action: #selector(toggleOrientation), for: .touchUpInside)
        orientLockButton.setImage(UIImage(named: "lockIcon-new"), for: .normal)
        orientLockButton.tintColor = .orange
        //TODO: add accessability options for orientationLockButton
        return orientLockButton
    }()
    
    lazy var moreOptionsButton: UIButton = {
        var moreOptionsButton = UIButton(type: .system)
        moreOptionsButton.addTarget(self, action: #selector(selectMoreOptions), for: .touchUpInside)
        moreOptionsButton.setImage(UIImage(named: "moreWhite-new"), for: .normal)
        moreOptionsButton.tintColor = .orange
        //TODO: add accessability options for moreOptionsButton
        return moreOptionsButton
    }()
    
    // MARK: Class Initializers
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addArrangedSubview(toggleFullScreenButton)
        addArrangedSubview(selectSubtitleButton)
        addArrangedSubview(repeatButton)
        addArrangedSubview(orientationLockButton)
        addArrangedSubview(moreOptionsButton)
    }
    
    // MARK: Button Action Buttons
    func toggleFullscreen() {
        delegate?.didToggleFullScreen(self)
    }
    
    func selectSubtitle() {
        delegate?.didSelectSubtitle(self)
    }
    
    func selectMoreOptions() {
        delegate?.didSelectMoreOptions(self)
    }
    
    func toggleRepeat() {
        delegate?.didToggleRepeat(self)
    }
    
    func toggleOrientation() {
        delegate?.didToggleOrientationLock(self)
    }
}


