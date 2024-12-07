//
//  UIScreen+Brightness.swift
//  VLC-iOS
//
//  Created by mohamed sliem on 10/11/2024.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import UIKit

extension UIScreen {

    func animateBrightnessChange(to value: CGFloat, duration: CGFloat = 1) {
        guard value != brightness else { return }

        var currentBrightness: CGFloat = UIScreen.main.brightness
        let isIncreasing: Bool = currentBrightness < value

        let tick: CGFloat = 1 / (duration * 1000)
        let brightnessDifference = abs(currentBrightness - value) / tick
        let numberOfTicks = Int(ceil(brightnessDifference))

        DispatchQueue.global(qos: .userInteractive).async {
            for _ in 0 ..< numberOfTicks {

                DispatchQueue.main.async {
                    currentBrightness += isIncreasing ? tick : -tick
                    self.brightness = currentBrightness
                }

                Thread.sleep(forTimeInterval: 1 / 1000)
            }
        }
    }
}
