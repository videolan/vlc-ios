/*****************************************************************************
 * MediaNavigationBarLayout.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

final class MediaNavigationBarLayout {
    enum Placement {
        case regular
        case tabletop
        case besideCamera
        case besideStatusBar
    }

    private(set) var placement = Placement.regular

    private let topPadding: CGFloat
    private let regularConstraints: [NSLayoutConstraint]
    private let tabletopTopConstraint: NSLayoutConstraint
    private let tabletopConstraints: [NSLayoutConstraint]
    private let besideCameraCenterYConstraint: NSLayoutConstraint
    private let besideCameraLeftConstraint: NSLayoutConstraint
    private let besideCameraConstraints: [NSLayoutConstraint]
    private let besideStatusBarCenterYConstraint: NSLayoutConstraint
    private let besideStatusBarRightConstraint: NSLayoutConstraint
    private let besideStatusBarConstraints: [NSLayoutConstraint]

    init(navigationBar: UIView,
         container: UIView,
         leftAnchor: NSLayoutXAxisAnchor,
         rightAnchor: NSLayoutXAxisAnchor,
         horizontalInset: CGFloat,
         topPadding: CGFloat) {
        self.topPadding = topPadding

        let leftConstraint = navigationBar.leftAnchor.constraint(equalTo: leftAnchor, constant: horizontalInset)
        let rightConstraint = navigationBar.rightAnchor.constraint(equalTo: rightAnchor, constant: -horizontalInset)

        regularConstraints = [
            navigationBar.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: topPadding),
            leftConstraint,
            rightConstraint,
        ]

        tabletopTopConstraint = navigationBar.topAnchor.constraint(equalTo: container.topAnchor)
        tabletopConstraints = [
            tabletopTopConstraint,
            leftConstraint,
            rightConstraint,
        ]

        besideCameraCenterYConstraint = navigationBar.centerYAnchor.constraint(equalTo: container.topAnchor)
        besideCameraCenterYConstraint.priority = .required - 1
        besideCameraLeftConstraint = navigationBar.leftAnchor.constraint(equalTo: container.leftAnchor)
        besideCameraConstraints = [
            besideCameraCenterYConstraint,
            navigationBar.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
            besideCameraLeftConstraint,
            rightConstraint,
        ]

        besideStatusBarCenterYConstraint = navigationBar.centerYAnchor.constraint(equalTo: container.topAnchor)
        besideStatusBarRightConstraint = navigationBar.rightAnchor.constraint(equalTo: container.leftAnchor)
        besideStatusBarConstraints = [
            besideStatusBarCenterYConstraint,
            leftConstraint,
            besideStatusBarRightConstraint,
        ]
    }

    func activate() {
        NSLayoutConstraint.activate(constraints(for: placement))
    }

    func update(tabletopFold: CGRect?,
                camera: (frame: CGRect, margins: UIEdgeInsets)?,
                statusBar: (frame: CGRect, margins: UIEdgeInsets)?,
                statusBarCenterY: CGFloat?) -> Bool {
        let newPlacement: Placement
        if let tabletopFold {
            setConstant(tabletopFold.maxY + topPadding, of: tabletopTopConstraint)
            newPlacement = .tabletop
        } else if let camera {
            setConstant(camera.frame.inset(by: camera.margins).midY, of: besideCameraCenterYConstraint)
            setConstant(camera.frame.maxX, of: besideCameraLeftConstraint)
            newPlacement = .besideCamera
        } else if let statusBar {
            setConstant(statusBarCenterY ?? statusBar.frame.inset(by: statusBar.margins).midY,
                        of: besideStatusBarCenterYConstraint)
            setConstant(statusBar.frame.minX, of: besideStatusBarRightConstraint)
            newPlacement = .besideStatusBar
        } else {
            newPlacement = .regular
        }

        guard newPlacement != placement else {
            return false
        }

        NSLayoutConstraint.deactivate(constraints(for: placement))
        placement = newPlacement
        NSLayoutConstraint.activate(constraints(for: newPlacement))
        return true
    }

    private func constraints(for placement: Placement) -> [NSLayoutConstraint] {
        switch placement {
        case .regular:
            return regularConstraints
        case .tabletop:
            return tabletopConstraints
        case .besideCamera:
            return besideCameraConstraints
        case .besideStatusBar:
            return besideStatusBarConstraints
        }
    }

    private func setConstant(_ constant: CGFloat, of constraint: NSLayoutConstraint) {
        if constraint.constant != constant {
            constraint.constant = constant
        }
    }
}
