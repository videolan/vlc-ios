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
    var delegate: SliderInfoViewDelegate?

    var iconNames: [String] = []

    let levelSlider: VerticalSliderControl = {
        let levelSlider = VerticalSliderControl()
        levelSlider.minimumTrackLayerColor = UIColor.white.cgColor
        levelSlider.maximumTrackLayerColor = UIColor(white: 1, alpha: 0.2).cgColor
        levelSlider.trackWidth = 4
        levelSlider.range = 0...1
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

    func setupView() {
        addSubview(levelImageView)
        addSubview(levelSlider)
        bringSubviewToFront(levelSlider)

        isUserInteractionEnabled = true
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            levelImageView.topAnchor.constraint(equalTo: topAnchor),
            levelImageView.heightAnchor.constraint(equalToConstant: 25),
            levelImageView.widthAnchor.constraint(equalToConstant: 25),

            levelSlider.topAnchor.constraint(equalTo: levelImageView.bottomAnchor, constant: 10),
            levelSlider.bottomAnchor.constraint(equalTo: bottomAnchor),
            levelSlider.widthAnchor.constraint(equalToConstant: 30),
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

        update(level: Float(UIScreen.main.brightness))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onLuminosityChange() {
        UIScreen.main.brightness = CGFloat(levelSlider.value)
        update(level: levelSlider.value)
    }

    override func setupView() {
        super.setupView()

        NSLayoutConstraint.activate([
            levelImageView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }
#endif
}

class VolumeControlView: SliderInfoView {
    private let volumeView: MPVolumeView?
    private(set) var isBeingTouched: Bool = false
    init(volumeView: MPVolumeView?) {
        self.volumeView = volumeView
        super.init(frame: .zero)

        setupView()

        self.levelSlider.setValue(AVAudioSession.sharedInstance().outputVolume, animated: false)
        if  !UIAccessibility.isVoiceOverRunning {
            levelSlider.thumbImage = UIImage()
        }

        levelSlider.addTarget(self, action: #selector(self.onVolumeChange), for: .valueChanged)
        levelSlider.addTarget(self, action: #selector(self.onTouchStarted), for: .touchDown)
        levelSlider.addTarget(self, action: #selector(self.onTouchEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])
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
        volumeView?.setVolume(levelSlider.value)
        update(level: levelSlider.value)
    }

    @objc func onTouchStarted() {
        isBeingTouched = true
    }

    @objc func onTouchEnded() {
        isBeingTouched = false
    }

    override func setupView() {
        super.setupView()

        NSLayoutConstraint.activate([
            levelImageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
