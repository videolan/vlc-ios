/*****************************************************************************
 * UIView+ModernUI.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 *
 * Authors: Antigravity AI
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

extension UIView {
    func applyModernCardStyle(theme: PresentationTheme = .current) {
        self.layer.cornerRadius = 16
        self.layer.shadowColor = theme.colors.cardShadowColor.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowOpacity = theme.colors.cardShadowOpacity
        self.layer.shadowRadius = theme.colors.cardShadowRadius
        self.layer.masksToBounds = false
    }

    func applyPrimaryGradient(theme: PresentationTheme = .current) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = theme.colors.primaryGradient.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = self.bounds
        gradientLayer.name = "primaryGradientLayer"
        
        // Remove existing gradient if any
        self.layer.sublayers?.filter { $0.name == "primaryGradientLayer" }.forEach { $0.removeFromSuperlayer() }
        
        self.layer.insertSublayer(gradientLayer, at: 0)
    }

    func applyGlassEffect(theme: PresentationTheme = .current) {
        let blurEffect = UIBlurEffect(style: theme.colors.glassEffectStyle)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.layer.cornerRadius = self.layer.cornerRadius
        blurEffectView.clipsToBounds = true
        
        self.addSubview(blurEffectView)
        self.sendSubviewToBack(blurEffectView)
    }
}
