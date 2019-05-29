/*****************************************************************************
 * VLCMediaViewEditCell.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol VLCVideoOptionsControlBarDelegate: class {
    func didToggleFullScreen(_ optionsBar: VLCVideoOptionsControlBar)
    func didToggleRepeat(_ optionsBar: VLCVideoOptionsControlBar)
    func didSelectSubtitle(_ optionsBar: VLCVideoOptionsControlBar)
    func didSelectMoreOptions(_ optionsBar: VLCVideoOptionsControlBar)
    func didToggleOrientationLock(_ optionsBar: VLCVideoOptionsControlBar)
}

class VLCVideoOptionsControlBar: UIStackView {
    
    // MARK: Instance variables
    private var delegate: VLCVideoOptionsControlBarDelegate?
    
    private var toggleFullScreenButton: UIButton = {
        var toggle = UIButton(type: .system)
        toggle.addTarget(self, action: #selector(toggleFullscreen), for: .touchUpInside)
        toggle.setImage(UIImage(named: "fullscreenIcon-new"), for: .normal)
        toggle.tintColor = .orange
        //TODO: add accessability options for fullScreenButton
        return toggle
    }()
    
    private var selectSubtitleButton: UIButton = {
        var subbutton = UIButton(type: .system)
        subbutton.addTarget(self, action: #selector(selectSubtitle), for: .touchUpInside)
        subbutton.setImage(UIImage(named: "subtitleIcon-new"), for: .normal)
        subbutton.tintColor = .orange
        //TODO: add accessability options for selectingSubtitleButton
        return subbutton
    }()
    
    private var repeatButton: UIButton = {
        var rptButton = UIButton(type: .system)
        rptButton.addTarget(self, action: #selector(toggleRepeat), for: .touchUpInside)
        rptButton.setImage(UIImage(named: "repeatOne-new"), for: .normal)
        rptButton.tintColor = .orange
        //TODO: add accessability options for repeatButton
        return rptButton
    }()
    
    private var orientationLockButton: UIButton = {
        var orientLockButton = UIButton(type: .system)
        orientLockButton.addTarget(self, action: #selector(toggleOrientation), for: .touchUpInside)
        orientLockButton.setImage(UIImage(named: "lockIcon-new"), for: .normal)
        orientLockButton.tintColor = .orange
        //TODO: add accessability options for orientationLockButton
        return orientLockButton
    }()
    
    private var moreOptionsButton: UIButton = {
        var moreOptionsButton = UIButton(type: .system)
        moreOptionsButton.addTarget(self, action: #selector(selectMoreOptions), for: .touchUpInside)
        moreOptionsButton.setImage(UIImage(named: "moreWhite-new"), for: .normal)
        moreOptionsButton.tintColor = .orange
        //TODO: add accessability options for moreOptionsButton
        return moreOptionsButton
    }()
    
    //MARK: Class Initializers
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
    
    //MARK: Button Action Buttons
    @objc func toggleFullscreen() {
        delegate?.didToggleFullScreen(self)
    }
    
    @objc func selectSubtitle() {
        delegate?.didSelectSubtitle(self)
    }
    
    @objc func selectMoreOptions() {
        delegate?.didSelectMoreOptions(self)
    }
    
    @objc func toggleRepeat() {
        delegate?.didToggleRepeat(self)
    }
    
    @objc func toggleOrientation() {
        delegate?.didToggleOrientationLock(self)
    }

}


