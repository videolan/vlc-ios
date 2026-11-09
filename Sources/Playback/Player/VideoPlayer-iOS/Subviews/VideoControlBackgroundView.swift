/*****************************************************************************
 * VideoControlBackgroundView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

/// A glass capsule with dark blur or solid fill fallbacks.
final class VideoControlBackgroundView: UIVisualEffectView {
    private static let legacyMaterialInset: CGFloat = 6

    private let isInteractive: Bool
    private var visibleEffect: UIVisualEffect?
    private var isVisible = true
    private let legacyMaterialMask: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()

    init(isInteractive: Bool = false) {
        self.isInteractive = isInteractive
        super.init(effect: nil)
        clipsToBounds = true
#if !os(visionOS)
        if #available(iOS 26.0, *) {
            cornerConfiguration = .capsule()
        }
#endif
        updateBackgroundStyle()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateBackgroundStyle),
                                               name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
#if !os(visionOS)
        if #available(iOS 26.0, *) {
            return
        }
#endif
        let materialFrame = bounds.insetBy(dx: Self.legacyMaterialInset, dy: Self.legacyMaterialInset)
        legacyMaterialMask.frame = materialFrame
        legacyMaterialMask.layer.cornerRadius = min(materialFrame.width, materialFrame.height) / 2
        mask = legacyMaterialMask
    }

    @objc private func updateBackgroundStyle() {
        visibleEffect = UIAccessibility.isReduceTransparencyEnabled ? nil
            : Self.glassEffect(isInteractive: isInteractive) ?? UIBlurEffect(style: .systemChromeMaterialDark)
        setVisible(isVisible)
    }

    private static func glassEffect(isInteractive: Bool) -> UIVisualEffect? {
#if !os(visionOS)
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            glassEffect.isInteractive = isInteractive
            // Keep white icons legible over bright video.
            glassEffect.tintColor = PresentationTheme.current.colors.transparentDarkBackgroundColor
            return glassEffect
        }
#endif
        return nil
    }

    /// Call inside an animation block; keep this view and its ancestors at alpha 1.
    func setVisible(_ visible: Bool) {
        isVisible = visible
        effect = visible ? visibleEffect : nil
        backgroundColor = visible && UIAccessibility.isReduceTransparencyEnabled
            ? PresentationTheme.currentExcludingWhite.colors.background : .clear
    }
}
