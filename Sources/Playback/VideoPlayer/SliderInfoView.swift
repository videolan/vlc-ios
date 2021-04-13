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

class CustomSlider: UISlider {

     override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var bounds: CGRect = self.bounds
        bounds = bounds.insetBy(dx: -30, dy: 30)
        return bounds.contains(point)
     }
}

class SliderInfoView: UIView {

    var iconNames: [String] = []

    let levelSlider: CustomSlider = {
        let levelSlider = CustomSlider()
        levelSlider.tintColor = .white
        levelSlider.translatesAutoresizingMaskIntoConstraints = false
        return levelSlider
    }()

    var levelImageView: UIImageView = {
        let soundLevelImageView = UIImageView()
        soundLevelImageView.translatesAutoresizingMaskIntoConstraints = false
        return soundLevelImageView
    }()

    func updateVolumeLevel(level: Float) {
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

        NSLayoutConstraint.activate([
            levelImageView.heightAnchor.constraint(equalToConstant: 25),
            levelImageView.widthAnchor.constraint(equalToConstant: 25),
            levelImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            levelImageView.rightAnchor.constraint(equalTo: rightAnchor, constant: 40)
        ])

        NSLayoutConstraint.activate([
            levelSlider.heightAnchor.constraint(equalToConstant: 5),
            levelSlider.widthAnchor.constraint(equalToConstant: bounds.width),
            levelSlider.centerYAnchor.constraint(equalTo: centerYAnchor),
            levelSlider.centerXAnchor.constraint(equalTo: centerXAnchor),
            levelSlider.rightAnchor.constraint(equalTo: rightAnchor, constant: 1),
            levelSlider.leftAnchor.constraint(equalTo: levelImageView.rightAnchor, constant: 0)
        ])
    }

    private func rotateSliderView() {
        self.transform = CGAffineTransform(rotationAngle: .pi * -0.5)
        self.levelImageView.transform = CGAffineTransform(rotationAngle: .pi/2)
    }
}

class VolumeControlView: SliderInfoView {

    init() {
        super.init(frame: .zero)
        self.levelSlider.value = AVAudioSession.sharedInstance().outputVolume
        levelSlider.setThumbImage(UIImage(), for: .normal)
        self.iconNames = ["noSound", "lowSound", "mediumSound", "hightSound"]
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class BrightnessControlView: SliderInfoView {

    init() {
        super.init(frame: .zero)
        levelSlider.setThumbImage(UIImage(), for: .normal)
        self.levelSlider.addTarget(self, action: #selector(BrightnessControlView.onLuminosityChange), for: UIControl.Event.valueChanged)
        self.levelSlider.value = Float(UIScreen.main.brightness)
        self.iconNames = ["brightnessLow", "brightnessLow", "brightnessMedium", "brightnessHigh"]
    }

    @objc func onLuminosityChange() {
        UIScreen.main.brightness = CGFloat(self.levelSlider.value)
        self.updateVolumeLevel(level: self.levelSlider.value)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
