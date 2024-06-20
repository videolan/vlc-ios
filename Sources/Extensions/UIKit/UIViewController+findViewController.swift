//
//  UIViewController+findViewController.swift
//  VLC-iOS
//
//  Created by İbrahim Çetin on 20.06.2024.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import UIKit

extension UIViewController {
    /// Finds child view controller of given type
    func findViewController<T: UIViewController>(ofType type: T.Type) -> T? {
        if let matchingVC = self as? T {
            return matchingVC
        }

        if let navController = self as? UINavigationController {
            for vc in navController.viewControllers {
                if let matchingVC = vc.findViewController(ofType: type) {
                    return matchingVC
                }
            }
        }

        if let tabController = self as? UITabBarController {
            for vc in tabController.viewControllers ?? [] {
                if let matchingVC = vc.findViewController(ofType: type) {
                    return matchingVC
                }
            }
        }

        return self.presentedViewController?.findViewController(ofType: type)
    }
}
