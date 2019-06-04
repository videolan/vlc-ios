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

@objc (VLCVideoOptionsControlBarDelegate)
protocol VideoOptionsControlBarDelegate: class {
    func didToggleFullScreen(_ optionsBar: VideoOptionsControlBar)
    func didToggleRepeat(_ optionsBar: VideoOptionsControlBar)
    func didSelectSubtitle(_ optionsBar: VideoOptionsControlBar)
    func didSelectMoreOptions(_ optionsBar: VideoOptionsControlBar)
    func didToggleInterfaceLock(_ optionsBar: VideoOptionsControlBar)
}

@objc (VLCVideoOptionsControlBar)
class VideoOptionsControlBar: UIStackView {
    
    // MARK: Instance variables
    @objc weak var delegate: VideoOptionsControlBarDelegate?
    private var rptMode: VLCRepeatMode = .doNotRepeat
    
    @objc var orientationAxis: NSLayoutConstraint.Axis {
        set {
            // rotate the control bar's orientation by switching it's height and width values and changing it's layout positioning
            axis = newValue
            let minX: CGFloat = frame.maxX - frame.size.height
            let minY: CGFloat = frame.maxY - frame.size.width
            frame = CGRect(x: minX, y: minY, width: frame.size.height, height:frame.size.width)
        }
        
        get {
            return axis
        }
    }
    
    @objc var repeatMode: VLCRepeatMode {
        set {
            rptMode = newValue
            switch newValue {
            case .repeatCurrentItem:
                repeatButton.setImage(UIImage(named: "repeatOne-new"), for: .normal)
                break
            case .repeatAllItems:
                repeatButton.setImage(UIImage(named: "repeat-new"), for: .normal)
                break
            default: // no repeat
                repeatButton.setImage(UIImage(named: "no-repeat-new"), for: .normal)
                break
            }
        }
        
        get {
            return rptMode
        }
    }
    
    @objc var toggleFullScreenButton: UIButton = {
        var toggle = UIButton(type: .system)
        toggle.setImage(UIImage(named: "fullscreenIcon-new"), for: .normal)
        toggle.tintColor = .white
        //TODO: add accessability options for fullScreenButton
        return toggle
    }()
    
    @objc var selectSubtitleButton: UIButton = {
        var subbutton = UIButton(type: .system)
        subbutton.setImage(UIImage(named: "subtitleIcon-new"), for: .normal)
        subbutton.tintColor = .white
        // TODO: add accessability options for selectingSubtitleButton
        return subbutton
    }()
    
    @objc var repeatButton: UIButton = {
        var rptButton = UIButton(type: .system)
        rptButton.setImage(UIImage(named: "no-repeat-new"), for: .normal)
        rptButton.tintColor = .white
        // TODO: add accessability options for repeatButton
        return rptButton
    }()
    
    @objc var interfaceLockButton: UIButton = {
        var interfaceLockButton = UIButton(type: .system)
        interfaceLockButton.setImage(UIImage(named: "lock-new"), for: .normal)
        interfaceLockButton.tintColor = .white
        // TODO: add accessability options for orientationLockButton
        return interfaceLockButton
    }()
    
    @objc var moreOptionsButton: UIButton = {
        var moreOptionsButton = UIButton(type: .system)
        moreOptionsButton.setImage(UIImage(named: "moreWhite-new"), for: .normal)
        moreOptionsButton.tintColor = .white
        // TODO: add accessability options for moreOptionsButton
        return moreOptionsButton
    }()
    
    // MARK: Class Initializers
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupButtonTargets() {
        toggleFullScreenButton.addTarget(self, action: #selector(toggleFullscreen), for: .touchUpInside)
        interfaceLockButton.addTarget(self, action: #selector(toggleInterfaceLock), for: .touchUpInside)
        repeatButton.addTarget(self, action: #selector(toggleRepeat), for: .touchUpInside)
        selectSubtitleButton.addTarget(self, action: #selector(selectSubtitle), for: .touchUpInside)
        moreOptionsButton.addTarget(self, action: #selector(selectMoreOptions), for: .touchUpInside)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtonTargets()
        self.addArrangedSubview(toggleFullScreenButton)
        self.addArrangedSubview(selectSubtitleButton)
        self.addArrangedSubview(repeatButton)
        self.addArrangedSubview(interfaceLockButton)
        self.addArrangedSubview(moreOptionsButton)
        axis = NSLayoutConstraint.Axis.vertical
    }
    
    // MARK: Button Action Functions
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
    
    @objc func toggleInterfaceLock() {
        delegate?.didToggleInterfaceLock(self)
    }
}
