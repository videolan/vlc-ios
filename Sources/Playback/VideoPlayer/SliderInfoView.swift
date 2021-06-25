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
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}

class SliderInfoView: UIView {

    var iconNames: [String] = []

    let levelSlider: UISlider = {
        let levelSlider = UISlider()
        levelSlider.tintColor = .white
        levelSlider.minimumValue = 0
        levelSlider.maximumValue = 1
        levelSlider.isContinuous = true
        levelSlider.translatesAutoresizingMaskIntoConstraints = false
        return levelSlider
    }()

    var levelImageView: UIImageView = {
        let levelImageView = UIImageView()
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

    override func layoutSubviews() {
        rotateSliderView()
        addSubview(levelImageView)
        addSubview(levelSlider)
        bringSubviewToFront(levelSlider)
        self.isUserInteractionEnabled = true
        NSLayoutConstraint.activate([
            levelImageView.heightAnchor.constraint(equalToConstant: 25),
            levelImageView.widthAnchor.constraint(equalToConstant: 25),
            levelImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            levelImageView.rightAnchor.constraint(equalTo: rightAnchor, constant: 40)
        ])

        NSLayoutConstraint.activate([
            levelSlider.heightAnchor.constraint(equalToConstant: 30),
            levelSlider.widthAnchor.constraint(equalToConstant: 170),
            levelSlider.centerYAnchor.constraint(equalTo: centerYAnchor),
            levelSlider.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    private func rotateSliderView() {
        self.transform = CGAffineTransform(rotationAngle: .pi * -0.5)
        self.levelImageView.transform = CGAffineTransform(rotationAngle: .pi/2)
    }
}

class BrightnessControlView: SliderInfoView {

    init() {
        super.init(frame: .zero)
        if  !UIAccessibility.isVoiceOverRunning {
            levelSlider.setThumbImage(UIImage(), for: .normal)
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
        UIScreen.main.brightness = CGFloat(self.levelSlider.value)
        updateIcon(level: Float(CGFloat(self.levelSlider.value)))
    }

    private func rotateSliderView() {
        self.transform = CGAffineTransform(rotationAngle: .pi * -0.5)
    }
}

class VolumeControlView: SliderInfoView {

    init() {
        super.init(frame: .zero)
        self.levelSlider.value = AVAudioSession.sharedInstance().outputVolume
        if  !UIAccessibility.isVoiceOverRunning {
            levelSlider.setThumbImage(UIImage(), for: .normal)
        }

        levelSlider.addTarget(self, action: #selector(self.onVolumeChange), for: .valueChanged)
        self.iconNames = ["noSound", "lowSound", "mediumSound", "hightSound"]

        levelSlider.accessibilityLabel = NSLocalizedString("VOLUME_SLIDER", comment: "")
        levelSlider.accessibilityHint = NSLocalizedString("VOLUME_HINT", comment: "")
        levelSlider.accessibilityTraits = .adjustable
    }

    @objc func onVolumeChange() {
        MPVolumeView.setVolume(Float(self.levelSlider.value))
        updateIcon(level: Float(self.levelSlider.value))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
