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
    func mediaNavigationBarDidMinimizePlayback(_ navigationBar: MediaNavigationBar)
    func mediaNavigationBarDidToggleChromeCast(_ navigationBar: MediaNavigationBar)
}

@objc (VLCMediaNavigationBar)
@objcMembers class MediaNavigationBar: UIView {
    
    // MARK: Instance Variables
    weak var delegate: MediaNavigationBarDelegate?
    
    lazy var minimizePlaybackButton: UIButton = {
        var minButton = UIButton(type: .system)
        minButton.addTarget(self, action: #selector(minimizePlayback), for: .touchUpInside)
        minButton.setImage(UIImage(named: "iconChevron"), for: .normal)
        minButton.tintColor = .white
        minButton.translatesAutoresizingMaskIntoConstraints = false
        return minButton
    }()
    
    private var mediaTitleTextLabel: UILabel = {
        var label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .white
        label.font = UIFont(name: "SFProDisplay-Medium", size: 17)
        label.text = NSLocalizedString("TITLE", comment: "Video Title")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var chromeCastButton: UIButton = {
        var chromeButton = UIButton(type: .system)
        chromeButton.addTarget(self, action: #selector(toggleChromeCast), for: .touchUpInside)
        chromeButton.setImage(UIImage(named: "renderer"), for: .normal)
        chromeButton.tintColor = .white
        chromeButton.translatesAutoresizingMaskIntoConstraints = false
        return chromeButton
    }()
    
    @available(iOS 11.0, *)
    lazy var airplayRoutePickerView: AVRoutePickerView = {
        var airPlayRoutePicker = AVRoutePickerView(frame: .zero)
        airPlayRoutePicker.activeTintColor = .orange
        airPlayRoutePicker.tintColor = .white
        airPlayRoutePicker.translatesAutoresizingMaskIntoConstraints = false
        return airPlayRoutePicker
    }()
    
    lazy var airplayVolumeView: MPVolumeView = {
        var airplayVolumeView = MPVolumeView()
        airplayVolumeView.tintColor = .white
        airplayVolumeView.translatesAutoresizingMaskIntoConstraints = false
        airplayVolumeView.showsVolumeSlider = false
        return airplayVolumeView
    }()
    
    // MARK: Initializers
    required init(coder: NSCoder) {
        fatalError("init(coder: NSCoder) not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    // MARK: Instance Methods
    func setMediaTitleLabelText(_ titleText: String) {
        mediaTitleTextLabel.text = titleText
    }
    
    private func setupConstraints() {
        let margin: CGFloat = 35.0
        var airplayView: UIView
        
        if #available(iOS 11.0, *) {
            airplayView = airplayRoutePickerView
        } else {
            airplayView = airplayVolumeView
        }
        
        let constraints: [NSLayoutConstraint] = [
            minimizePlaybackButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            minimizePlaybackButton.topAnchor.constraint(equalTo: topAnchor),
            minimizePlaybackButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            mediaTitleTextLabel.leadingAnchor.constraint(equalTo: minimizePlaybackButton.trailingAnchor, constant: margin),
            mediaTitleTextLabel.topAnchor.constraint(equalTo: topAnchor),
            mediaTitleTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: chromeCastButton.leadingAnchor, constant: margin),
            chromeCastButton.topAnchor.constraint(equalTo: topAnchor),
            chromeCastButton.trailingAnchor.constraint(equalTo: airplayView.leadingAnchor, constant: margin),
            airplayView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: margin),
            airplayView.topAnchor.constraint(equalTo: topAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupViews() {
        addSubview(minimizePlaybackButton)
        addSubview(mediaTitleTextLabel)
        addSubview(chromeCastButton)
        if #available(iOS 11.0, *) {
            addSubview(airplayRoutePickerView)
        } else {
            addSubview(airplayVolumeView)
        }
    }
    
    // MARK: Button Actions
    func minimizePlayback() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidMinimizePlayback(self)
    }
    
    func toggleChromeCast() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidToggleChromeCast(self)
    }
}
