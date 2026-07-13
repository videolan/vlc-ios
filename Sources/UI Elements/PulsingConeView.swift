/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@objc(VLCPulsingConeView)
class PulsingConeView: UIView {

    private let coneImageView: UIImageView = {
        let cone = UIImage(named: "LaunchCone") ?? UIImage(named: "cone")
        let coneImageView = UIImageView(image: cone?.withRenderingMode(.alwaysTemplate))
        coneImageView.contentMode = .scaleAspectFit
        coneImageView.translatesAutoresizingMaskIntoConstraints = false
        return coneImageView
    }()

    private let appearanceDelay: TimeInterval = 1.0
    private var delayTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        isUserInteractionEnabled = false
        alpha = 0.0
        addSubview(coneImageView)
        NSLayoutConstraint.activate([
            coneImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            coneImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            coneImageView.widthAnchor.constraint(equalToConstant: 80),
            coneImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    @objc func startAnimating() {
        if delayTimer != nil || coneImageView.layer.animation(forKey: "pulse") != nil {
            return
        }
        delayTimer = Timer.scheduledTimer(timeInterval: appearanceDelay,
                                          target: self,
                                          selector: #selector(beginPulsing),
                                          userInfo: nil,
                                          repeats: false)
    }

    @objc private func beginPulsing() {
        delayTimer = nil
        coneImageView.tintColor = PresentationTheme.current.colors.orangeDarkAccent
        alpha = 1.0

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.8
        scale.toValue = 1.2

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0.4
        opacity.toValue = 1.0

        let pulse = CAAnimationGroup()
        pulse.animations = [scale, opacity]
        pulse.duration = 0.8
        pulse.autoreverses = true
        pulse.repeatCount = .greatestFiniteMagnitude
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        coneImageView.layer.add(pulse, forKey: "pulse")
    }

    @objc func stopAnimating() {
        delayTimer?.invalidate()
        delayTimer = nil
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        coneImageView.layer.removeAnimation(forKey: "pulse")
        alpha = 0.0
        CATransaction.commit()
    }
}
