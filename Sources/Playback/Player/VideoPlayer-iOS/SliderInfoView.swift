/*****************************************************************************
 * SliderInfoView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2021 VideoLAN. All rights reserved.
 * Copyright © 2021 Videolabs
 *
 * Authors: Malek BARKAOUI <malek.professional # gmail.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import MediaPlayer

extension MPVolumeView {

    func setVolume(_ volume: Float) {
        try? AVAudioSession.sharedInstance().setActive(true)
        let slider = self.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}

protocol SliderInfoViewDelegate {
    func sliderInfoViewDidReceiveTouch(_ sliderInfoView: SliderInfoView)
}

class SliderInfoView: UIView {
    static let width: CGFloat = 44

    var delegate: SliderInfoViewDelegate?

    var iconNames: [String] = []

    let levelSlider: VerticalSliderControl = {
        let levelSlider = VerticalSliderControl()
        levelSlider.minimumTrackLayerColor = UIColor.white.cgColor
        levelSlider.maximumTrackLayerColor = UIColor(white: 1, alpha: 0.2).cgColor
        levelSlider.trackWidth = 4
        levelSlider.range = 0...1
        levelSlider.allowsDragFromAnywhere = true
        levelSlider.translatesAutoresizingMaskIntoConstraints = false
        return levelSlider
    }()

    var levelImageView: UIImageView = {
        let levelImageView = UIImageView()
        levelImageView.tintColor = .white
        levelImageView.translatesAutoresizingMaskIntoConstraints = false
        return levelImageView
    }()

    func update(level: Float) {
        delegate?.sliderInfoViewDidReceiveTouch(self)
        updateIcon(level: level)
    }

    func updateIcon(level: Float) {
        guard iconNames.count == 4 else {
            assertionFailure("SliderInfo: icons names not set")
            return
        }

        self.levelSlider.setValue(level, animated: false)

        if level == 0 {
            self.levelImageView.image = UIImage(named: iconNames[0])
        } else if (0...0.4).contains(level) {
            self.levelImageView.image = UIImage(named: iconNames[1])
        } else if (0.4...0.7).contains(level) {
            self.levelImageView.image = UIImage(named: iconNames[2])
        } else if level > 0.7 {
            self.levelImageView.image = UIImage(named: iconNames[3])
        }
    }

    func isEnabled(_ enabled: Bool) {
        levelSlider.isEnabled = enabled
    }

    private static let touchOutset: CGFloat = 16

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let outset = levelSlider.isEnabled ? Self.touchOutset : 0
        return bounds.insetBy(dx: -outset, dy: 0).contains(point)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Route the capsule's icon and padding to the slider too.
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        return levelSlider.isEnabled ? levelSlider : hitView
    }

    private let background = VideoControlBackgroundView(isInteractive: true)
    private(set) var isVisible = true

    /// Fades the effect and content separately to preserve glass rendering.
    func setVisible(_ visible: Bool) {
        isVisible = visible
        isUserInteractionEnabled = visible
        accessibilityElementsHidden = !visible
        background.setVisible(visible)
        levelImageView.alpha = visible ? 1 : 0
        levelSlider.alpha = visible ? 1 : 0
    }

    func setupView() {
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)
        // Interactive glass responds to touches inside contentView.
        let contentView = background.contentView
        contentView.addSubview(levelImageView)
        contentView.addSubview(levelSlider)

        isUserInteractionEnabled = true
        translatesAutoresizingMaskIntoConstraints = false

        // Allow padding to compress on short screens.
        let topPadding = levelImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        let bottomPadding = levelSlider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        topPadding.priority = .required - 1
        bottomPadding.priority = .required - 1

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),

            topPadding,
            levelImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            levelImageView.heightAnchor.constraint(equalToConstant: 25),
            levelImageView.widthAnchor.constraint(equalToConstant: 25),

            levelSlider.topAnchor.constraint(equalTo: levelImageView.bottomAnchor, constant: 10),
            bottomPadding,
            levelSlider.widthAnchor.constraint(equalTo: widthAnchor),
            levelSlider.centerXAnchor.constraint(equalTo: levelImageView.centerXAnchor)
        ])
    }
}

class BrightnessControlView: SliderInfoView {
#if os(iOS)
    init() {
        super.init(frame: .zero)

        setupView()

        if  !UIAccessibility.isVoiceOverRunning {
            levelSlider.thumbImage = UIImage()
        }
        self.iconNames = ["brightnessLow", "brightnessLow", "brightnessMedium", "brightnessHigh"]
        levelSlider.addTarget(self, action: #selector(self.onLuminosityChange), for: .valueChanged)

        levelSlider.isAccessibilityElement = true
        levelSlider.accessibilityLabel = NSLocalizedString("BRIGHTNESS_SLIDER", comment: "")
        levelSlider.accessibilityHint = NSLocalizedString("BRIGHTNESS_HINT", comment: "")

        // Avoid the temptation to put `adjustable` here; the system will add
        // accessibility controls that do not work.
        levelSlider.accessibilityTraits = []
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var currentScreen: UIScreen? {
        return window?.windowScene?.screen
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if let brightness = currentScreen?.brightness {
            update(level: Float(brightness))
        }
    }

    @objc func onLuminosityChange() {
        currentScreen?.brightness = CGFloat(levelSlider.value)
        update(level: levelSlider.value)
    }
#endif
}

class VolumeControlView: SliderInfoView {
    private let volumeView: MPVolumeView?
    private var lastSliderChange = Date.distantPast

    /// Extends the touch state to cover delayed system volume updates.
    var isBeingTouched: Bool {
        return levelSlider.isPanning || Date().timeIntervalSince(lastSliderChange) < 0.5
    }

    init(volumeView: MPVolumeView?) {
        self.volumeView = volumeView
        super.init(frame: .zero)

        setupView()

        self.levelSlider.setValue(AVAudioSession.sharedInstance().outputVolume, animated: false)
        if  !UIAccessibility.isVoiceOverRunning {
            levelSlider.thumbImage = UIImage()
        }

        levelSlider.addTarget(self, action: #selector(self.onVolumeChange), for: .valueChanged)
        self.iconNames = ["noSound", "lowSound", "mediumSound", "highSound"]

        levelSlider.isAccessibilityElement = true
        levelSlider.accessibilityLabel = NSLocalizedString("VOLUME_SLIDER", comment: "")
        levelSlider.accessibilityHint = NSLocalizedString("VOLUME_HINT", comment: "")

        // Avoid the temptation to put `adjustable` here; the system will add
        // accessibility controls that do not work.
        levelSlider.accessibilityTraits = []
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onVolumeChange() {
        lastSliderChange = Date()
        volumeView?.setVolume(levelSlider.value)
        update(level: levelSlider.value)
    }
}
