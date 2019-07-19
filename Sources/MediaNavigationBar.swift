/*****************************************************************************
 * MediaNavigationBar.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon # gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import AVKit

@objc (VLCMediaNavigationBarDelegate)
protocol MediaNavigationBarDelegate {
    func mediaNavigationBarDidTapMinimize(_ mediaNavigationBar: MediaNavigationBar)
    func mediaNavigationBarDidLongPressMinimize(_ mediaNavigationBar: MediaNavigationBar)
    func mediaNavigationBarDidToggleChromeCast(_ mediaNavigationBar: MediaNavigationBar)
}

@objc (VLCMediaNavigationBar)
@objcMembers class MediaNavigationBar: UIStackView {
    
    // MARK: Instance Variables
    weak var delegate: MediaNavigationBarDelegate?
    private var buttonSize: CGFloat = 24
    
    lazy var minimizePlaybackButton: UIButton = {
        var minButton = UIButton(type: .system)
        let longPressGesture = UILongPressGestureRecognizer(target: self,
                                action: #selector(handleMinimizeLongPress))
        minButton.addGestureRecognizer(longPressGesture)
        minButton.addTarget(self, action: #selector(handleMinimizeTap), for: .touchUpInside)
        minButton.setImage(UIImage(named: "iconChevron"), for: .normal)
        minButton.tintColor = .white
        minButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return minButton
    }()
    
    lazy var mediaTitleTextLabel: UILabel = {
        var label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.textColor = .white
        label.font = UIFont(name: "SFProDisplay-Medium", size: 17)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    lazy var chromeCastButton: UIButton = {
        var chromeButton = UIButton(type: .system)
        chromeButton.addTarget(self, action: #selector(toggleChromeCast), for: .touchUpInside)
        chromeButton.setImage(UIImage(named: "renderer"), for: .normal)
        chromeButton.tintColor = .white
        // disable until a chromecast device is found
        chromeButton.isHidden = true
        chromeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return chromeButton
    }()
    
    @available(iOS 11.0, *)
    lazy var airplayRoutePickerView: AVRoutePickerView = {
        var airPlayRoutePicker = AVRoutePickerView()
        airPlayRoutePicker.activeTintColor = .orange
        airPlayRoutePicker.tintColor = .white
        return airPlayRoutePicker
    }()
    
    lazy var airplayVolumeView: MPVolumeView = {
        var airplayVolumeView = MPVolumeView()
        airplayVolumeView.tintColor = .white
        airplayVolumeView.showsVolumeSlider = false
        airplayVolumeView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return airplayVolumeView
    }()
    
    // MARK: Initializers
    required init(coder: NSCoder) {
        fatalError("init(coder: NSCoder) not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    // MARK: Instance Methods
    func setMediaTitleLabelText(_ titleText: String) {
        mediaTitleTextLabel.text = titleText
    }
    
    private func setupViews() {
        spacing = 20.0
        distribution = .fill
        translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(minimizePlaybackButton)
        addArrangedSubview(mediaTitleTextLabel)
        addArrangedSubview(chromeCastButton)
        if #available(iOS 11.0, *) {
            addArrangedSubview(airplayRoutePickerView)
        } else {
            addArrangedSubview(airplayVolumeView)
        }
    }
    
    // MARK: Button Actions
    func handleMinimizeTap() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidTapMinimize(self)
    }
    
    func handleMinimizeLongPress() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidLongPressMinimize(self)
    }
    
    func toggleChromeCast() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidToggleChromeCast(self)
    }
}

