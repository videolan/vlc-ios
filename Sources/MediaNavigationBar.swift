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
import MediaPlayer

@objc (VLCMediaNavigationBarDelegate)
protocol MediaNavigationBarDelegate {
    func mediaNavigationBarDidTapClose(_ mediaNavigationBar: MediaNavigationBar)
    func mediaNavigationBarDidTapMinimize(_ mediaNavigationBar: MediaNavigationBar)
    func mediaNavigationBarDidToggleQueueView(_ mediaNavigationBar: MediaNavigationBar)
    func mediaNavigationBarDidToggleChromeCast(_ mediaNavigationBar: MediaNavigationBar)
}

@objc (VLCMediaNavigationBar)
@objcMembers class MediaNavigationBar: UIStackView {
    // MARK: Instance Variables
    weak var delegate: MediaNavigationBarDelegate?

    lazy var minimizePlaybackButton: UIButton = {
        var minButton = UIButton(type: .system)
        minButton.addTarget(self, action: #selector(handleMinimizeTap), for: .touchDown)
        minButton.setImage(UIImage(named: "minimize"), for: .normal)
        minButton.tintColor = .white
        minButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return minButton
    }()

    lazy var closePlaybackButton: UIButton = {
        var closeButton = UIButton(type: .system)
        closeButton.addTarget(self, action: #selector(handleCloseTap), for: .touchDown)
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
        label.font = UIFont.preferredCustomFont(forTextStyle: .headline)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    lazy var queueButton: UIButton = {
        var queueButton = UIButton(type: .system)
        queueButton.addTarget(self, action: #selector(toggleQueueView), for: .touchDown)
        queueButton.setImage(UIImage(named: "play-queue"), for: .normal)
        queueButton.tintColor = .white
        queueButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return queueButton
    }()

    lazy var chromeCastButton: UIButton = {
        var chromeButton = UIButton(type: .system)
        chromeButton.addTarget(self, action: #selector(toggleChromeCast), for: .touchDown)
        chromeButton.setImage(UIImage(named: "renderer"), for: .normal)
        chromeButton.tintColor = .white
        chromeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return chromeButton
    }()

    lazy var airplayRoutePickerView: UIView = {
        if #available(iOS 11.0, *) {
            var airPlayRoutePicker = AVRoutePickerView()
            airPlayRoutePicker.activeTintColor = .orange
            airPlayRoutePicker.tintColor = .white
            return airPlayRoutePicker
        } else {
            assertionFailure("airplay route picker view is unavailable to iOS 10 and earlier")
            return UIView()
        }
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
    func setMediaTitleLabelText(_ titleText: String?) {
        mediaTitleTextLabel.text = titleText
    }

    private func setupContraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            closePlaybackButton.widthAnchor.constraint(equalTo: heightAnchor),
            minimizePlaybackButton.widthAnchor.constraint(equalTo: heightAnchor),
            queueButton.widthAnchor.constraint(equalTo: heightAnchor)
        ])
        if #available(iOS 11.0, *) {
            airplayRoutePickerView.widthAnchor.constraint(equalTo: heightAnchor).isActive = true
        } else {
            airplayVolumeView.widthAnchor.constraint(equalTo: heightAnchor).isActive = true
        }
    }

    private func setupViews() {
        distribution = .fill
        semanticContentAttribute = .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(closePlaybackButton)
        addArrangedSubview(minimizePlaybackButton)
        addArrangedSubview(mediaTitleTextLabel)
        addArrangedSubview(queueButton)
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

    func toggleQueueView() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidToggleQueueView(self)
    }

    func toggleChromeCast() {
        assert(delegate != nil, "Delegate not set for MediaNavigationBar")
        delegate?.mediaNavigationBarDidToggleChromeCast(self)
    }
}

