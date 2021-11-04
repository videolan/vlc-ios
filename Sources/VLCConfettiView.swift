/*****************************************************************************
 * VLCConfettiView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import QuartzCore

public class VLCConfettiView: UIView {

    var emitter: CAEmitterLayer!
    public var intensity: Float!
    private var active: Bool!
    private var dots: [CGImage?]!

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    func setup() {
        intensity = 0.5
        active = false
        dots = [UIImage(named: "dot1")!.cgImage, UIImage(named: "dot2")!.cgImage, UIImage(named: "dot3")!.cgImage]
    }

    @objc public func startConfetti() {
        emitter = CAEmitterLayer()

        emitter.emitterPosition = CGPoint(x: frame.size.width / 2.0, y: 0)
        emitter.emitterShape = CAEmitterLayerEmitterShape.line
        emitter.emitterSize = CGSize(width: frame.size.width, height: 1)

        var cells = [CAEmitterCell]()
        cells.append(vlcConfetti())

        emitter.emitterCells = cells
        layer.addSublayer(emitter)
        active = true
    }

    @objc public func stopConfetti() {
        emitter?.birthRate = 0
        active = false
    }

    func vlcConfetti() -> CAEmitterCell {
        let confetti = CAEmitterCell()
        confetti.birthRate = 10.0 * intensity
        confetti.lifetime = 14.0 * intensity
        confetti.lifetimeRange = 0
        confetti.velocity = CGFloat(700.0 * intensity)
        confetti.velocityRange = CGFloat(100.0 * intensity)
        confetti.emissionLongitude = CGFloat(Double.pi)
        confetti.spin = CGFloat(3.5 * intensity)
        confetti.scale = 0.5
        confetti.spinRange = CGFloat(4.0 * intensity)
        confetti.scaleRange = CGFloat(intensity)
        confetti.scaleSpeed = CGFloat(-0.1 * intensity)
        confetti.contents = dots.randomElement()!
        return confetti
    }

    @objc public func isActive() -> Bool {
        return self.active
    }
}
