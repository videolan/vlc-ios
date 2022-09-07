/*****************************************************************************
* VLCMarqueeLabel.swift
*
* Copyright © 2020 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import MarqueeLabel

@IBDesignable

open class VLCMarqueeLabel: MarqueeLabel {
    override public init(frame: CGRect, rate: CGFloat, fadeLength fade: CGFloat) {
        super.init(frame: frame, rate: rate, fadeLength: fade)
        setup()
    }

    override public init(frame: CGRect, duration: CGFloat, fadeLength fade: CGFloat) {
        super.init(frame: frame, duration: duration, fadeLength: fade)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        self.speed = .rate(30)
        self.animationDelay = 2.0
        self.trailingBuffer = 40
        self.fadeLength = 20.0
    }
}
