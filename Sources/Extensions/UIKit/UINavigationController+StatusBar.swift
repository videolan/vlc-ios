/*****************************************************************************
 * UINavigationController+StatusBar.swift
 *
 * Copyright © 2023 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

extension UINavigationController {
    func setStatusBarColor(barView: UIView, backgroundColor: UIColor) {
        if #available(iOS 13.0, *) {
            let isLandscape = UIDevice.current.orientation.isLandscape
            if !isLandscape {
                barView.frame = view.window?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
            } else {
                barView.frame = .zero
            }

            barView.backgroundColor = backgroundColor
            view.addSubview(barView)
        } else {
            let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
            statusBar?.backgroundColor = backgroundColor
        }
    }
}
