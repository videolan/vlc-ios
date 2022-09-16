/*****************************************************************************
 * SliderInfoView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2021 VideoLAN. All rights reserved.
 * Copyright © 2021 Videolabs
 *
 * Authors: Malek BARKAOUI <malek.professional # gmail.com>
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

class SliderInfoView: UIView {

    var iconNames: [String] = []

    let levelSlider: VerticalSlider = {
        let levelSlider = VerticalSlider()
        levelSlider.tintColor = .white
        levelSlider.minimumValue = 0
        levelSlider.maximumValue = 1
        levelSlider.isContinuous = true
        levelSlider.translatesAutoresizingMaskIntoConstraints = false
        return levelSlider
    }()

    var levelImageView: UIImageView = {
        let levelImageView = UIImageView()
        levelImageView.tintColor = .white
        levelImageView.translatesAutoresizingMaskIntoConstraints = false
        return levelImageView
    }()

    func updateIcon(level: Float) {
        guard iconNames.count == 4 else {
            assertionFailure("SliderInfo: icons names not set")
            return
        }

        self.levelSlider.value = level
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

    override func layoutSubviews() {
        addSubview(levelImageView)
        addSubview(levelSlider)
        bringSubviewToFront(levelSlider)
        isUserInteractionEnabled = true
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            levelImageView.topAnchor.constraint(equalTo: topAnchor),
            levelImageView.heightAnchor.constraint(equalToConstant: 25),
            levelImageView.widthAnchor.constraint(equalToConstant: 25),
            levelImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        NSLayoutConstraint.activate([
            levelSlider.topAnchor.constraint(equalTo: levelImageView.bottomAnchor, constant: 10),
            levelSlider.bottomAnchor.constraint(equalTo: bottomAnchor),
            levelSlider.widthAnchor.constraint(equalToConstant: 30),
            levelSlider.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}

class BrightnessControlView: SliderInfoView {

    init() {
        super.init(frame: .zero)
        if  !UIAccessibility.isVoiceOverRunning {
            levelSlider.setThumbImage(image: UIImage(), for: .normal)
        }
        self.iconNames = ["brightnessLow", "brightnessLow", "brightnessMedium", "brightnessHigh"]
        levelSlider.addTarget(self, action: #selector(self.onLuminosityChange), for: .valueChanged)
        levelSlider.accessibilityLabel = NSLocalizedString("BRIGHTNESS_SLIDER", comment: "")
        levelSlider.accessibilityHint = NSLocalizedString("BRIGHTNESS_HINT", comment: "")
        levelSlider.accessibilityTraits = .adjustable

        updateIcon(level: Float(UIScreen.main.brightness))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onLuminosityChange() {
        UIScreen.main.brightness = CGFloat(levelSlider.value)
        updateIcon(level: levelSlider.value)
    }
}

class VolumeControlView: SliderInfoView {
    private let volumeView: MPVolumeView?
    private(set) var isBeingTouched: Bool = false
    init(volumeView: MPVolumeView?) {
        self.volumeView = volumeView
        super.init(frame: .zero)

        self.levelSlider.value = AVAudioSession.sharedInstance().outputVolume
        if  !UIAccessibility.isVoiceOverRunning {
            levelSlider.setThumbImage(image: UIImage(), for: .normal)
        }

        levelSlider.addTarget(self, action: #selector(self.onVolumeChange), for: .valueChanged)
        levelSlider.addTarget(self, action: #selector(self.onTouchStarted), for: .touchDown)
        levelSlider.addTarget(self, action: #selector(self.onTouchEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        self.iconNames = ["noSound", "lowSound", "mediumSound", "highSound"]

        levelSlider.accessibilityLabel = NSLocalizedString("VOLUME_SLIDER", comment: "")
        levelSlider.accessibilityHint = NSLocalizedString("VOLUME_HINT", comment: "")
        levelSlider.accessibilityTraits = .adjustable
    }

    @objc func onVolumeChange() {
        volumeView?.setVolume(levelSlider.value)
        updateIcon(level: levelSlider.value)
    }

    @objc func onTouchStarted() {
        isBeingTouched = true
    }

    @objc func onTouchEnded() {
        isBeingTouched = false
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
