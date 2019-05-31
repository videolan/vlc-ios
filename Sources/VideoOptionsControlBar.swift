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
@objcMembers class VideoOptionsControlBar: UIStackView {
    
    // MARK: Instance variables
    weak var delegate: VideoOptionsControlBarDelegate?
    
    var repeatMode: VLCRepeatMode {
        didSet {
            switch repeatMode {
            case .repeatCurrentItem:
                repeatButton.setImage(UIImage(named: "repeatOne-new"), for: .normal)
            case .repeatAllItems:
                repeatButton.setImage(UIImage(named: "repeat-new"), for: .normal)
            case .doNotRepeat:
                repeatButton.setImage(UIImage(named: "no-repeat-new"), for: .normal)
            default:
                assertionFailure("unhandled repeatmode")
            }
        }
    }
    
    lazy var toggleFullScreenButton: UIButton = {
        var toggle = UIButton(type: .system)
        toggle.setImage(UIImage(named: "fullscreenIcon-new"), for: .normal)
        toggle.addTarget(self, action: #selector(toggleFullscreen), for: .touchUpInside)
        toggle.tintColor = .white
        toggle.accessibilityLabel = NSLocalizedString("VIDEO_ASPECT_RATIO_BUTTON", comment: "")
        toggle.accessibilityHint = NSLocalizedString("VIDEO_ASPECT_RATIO_HINT", comment: "")
        return toggle
    }()
    
    lazy var selectSubtitleButton: UIButton = {
        var subbutton = UIButton(type: .system)
        subbutton.setImage(UIImage(named: "subtitlesIcon-new"), for: .normal)
        subbutton.addTarget(self, action: #selector(selectSubtitle), for: .touchUpInside)
        subbutton.tintColor = .white
        subbutton.accessibilityHint = NSLocalizedString("CHOOSE_SUBTITLE_TRACK", comment: "")
        subbutton.accessibilityLabel = NSLocalizedString("SUBTITLES", comment: "")
        return subbutton
    }()
    
    lazy var repeatButton: UIButton = {
        var rptButton = UIButton(type: .system)
        rptButton.addTarget(self, action: #selector(toggleRepeat), for: .touchUpInside)
        rptButton.setImage(UIImage(named: "no-repeat-new"), for: .normal)
        rptButton.tintColor = .white
        rptButton.accessibilityHint = NSLocalizedString("REPEAT_MODE", comment: "")
        rptButton.accessibilityLabel = NSLocalizedString("REPEAT_MODE_HINT", comment: "")
        return rptButton
    }()
    
    lazy var interfaceLockButton: UIButton = {
        var interfaceLockButton = UIButton(type: .system)
        interfaceLockButton.setImage(UIImage(named: "lock-new"), for: .normal)
        interfaceLockButton.addTarget(self, action: #selector(toggleInterfaceLock), for: .touchUpInside)
        interfaceLockButton.tintColor = .white
        interfaceLockButton.accessibilityHint = NSLocalizedString("INTERFACE_LOCK_HINT", comment: "")
        interfaceLockButton.accessibilityLabel = NSLocalizedString("INTERFACE_LOCK_BUTTON", comment: "")
        return interfaceLockButton
    }()
    
    lazy var moreOptionsButton: UIButton = {
        var moreOptionsButton = UIButton(type: .system)
        moreOptionsButton.setImage(UIImage(named: "moreWhite-new"), for: .normal)
        moreOptionsButton.addTarget(self, action: #selector(selectMoreOptions), for: .touchUpInside)
        moreOptionsButton.tintColor = .white
        moreOptionsButton.accessibilityHint = NSLocalizedString("MORE_OPTIONS_HINT", comment: "")
        moreOptionsButton.accessibilityLabel = NSLocalizedString("MORE_OPTIONS_BUTTON", comment: "")
        return moreOptionsButton
    }()
    
    // MARK: Class Initializers
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder aDecoder: NSCoder) not implemented")
    }
    
    override init(frame: CGRect) {
        repeatMode = .doNotRepeat
        super.init(frame: frame)
        addArrangedSubview(toggleFullScreenButton)
        addArrangedSubview(selectSubtitleButton)
        addArrangedSubview(repeatButton)
        addArrangedSubview(interfaceLockButton)
        addArrangedSubview(moreOptionsButton)
        axis = .horizontal
        translatesAutoresizingMaskIntoConstraints = false
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
    
    func toggleInterfaceLock() {
        delegate?.didToggleInterfaceLock(self)
    }
}


