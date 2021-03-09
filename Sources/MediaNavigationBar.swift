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
    func mediaNavigationBarDidTapClose(_ mediaNavigationBar: MediaNavigationBar)
    func mediaNavigationBarDidTapMinimize(_ mediaNavigationBar: MediaNavigationBar)
    func mediaNavigationBarDidToggleChromeCast(_ mediaNavigationBar: MediaNavigationBar)
}

@objc (VLCMediaNavigationBar)
@objcMembers class MediaNavigationBar: UIStackView {
    // MARK: Instance Variables
    weak var delegate: MediaNavigationBarDelegate?

    lazy var minimizePlaybackButton: UIButton = {
        var minButton = UIButton(type: .system)
        minButton.addTarget(self, action: #selector(handleMinimizeTap), for: .touchUpInside)
        minButton.setImage(UIImage(named: "minimize"), for: .normal)
        minButton.tintColor = .white
        minButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return minButton
    }()

    lazy var closePlaybackButton: UIButton = {
        var closeButton = UIButton(type: .system)
        closeButton.addTarget(self, action: #selector(handleCloseTap), for: .touchUpInside)
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.tintColor = .white
        closeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return closeButton
    }()

    lazy var mediaTitleTextLabel: VLCMarqueeLabel = {
        var label = VLCMarqueeLabel()
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
        setupContraints()
    }

    // MARK: Instance Methods
    func setMediaTitleLabelText(_ titleText: String) {
        mediaTitleTextLabel.text = titleText
    }

    private func setupContraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            closePlaybackButton.widthAnchor.constraint(equalTo: heightAnchor),
            minimizePlaybackButton.widthAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    private func setupViews() {
        distribution = .fill
        translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(closePlaybackButton)
        addArrangedSubview(minimizePlaybackButton)
        addArrangedSubview(mediaTitleTextLabel)
        if #available(iOS 11.0, *) {
            addArrangedSubview(airplayRoutePickerView)
        } else {
            addArrangedSubview(airplayVolumeView)
        }
    }

    func updateChromecastButton(with button: UIButton) {
        removeArrangedSubview(chromeCastButton)
        chromeCastButton = button
        addArrangedSubview(chromeCastButton)
        chromeCastButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    // MARK: Button Actions

    func handleCloseTap() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidTapClose(self)
    }

    func handleMinimizeTap() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidTapMinimize(self)
    }

    func toggleChromeCast() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidToggleChromeCast(self)
    }
}

