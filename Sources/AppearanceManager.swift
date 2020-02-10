/*****************************************************************************
 * AppearanceManager.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
import UIKit

@objc(VLCApperanceManager)
class AppearanceManager: NSObject {

    @objc class func setupAppearance(theme: PresentationTheme = PresentationTheme.current) {
        if #available(iOS 13.0, *) {
            if UserDefaults.standard.integer(forKey: kVLCSettingAppTheme) == kVLCSettingAppThemeSystem {
                UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .unspecified
            } else {
                UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = theme == PresentationTheme.darkTheme ? .dark : .light
            }
        }
        // Change the keyboard for UISearchBar
        UITextField.appearance().keyboardAppearance = theme == PresentationTheme.darkTheme ? .dark : .light
        // For the cursor
        UITextField.appearance().tintColor = theme.colors.orangeUI

        // Don't override the 'Cancel' button color in the search bar with the previous UITextField call. Use the default blue color
        let attributes = [NSAttributedString.Key.foregroundColor: theme.colors.orangeUI]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)

        UINavigationBar.appearance().barTintColor = theme.colors.navigationbarColor
        UINavigationBar.appearance(whenContainedInInstancesOf: [VLCPlaybackNavigationController.self]).barTintColor = nil
        UINavigationBar.appearance().tintColor = theme.colors.orangeUI
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: theme.colors.navigationbarTextColor]

        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().prefersLargeTitles = true
            UINavigationBar.appearance(whenContainedInInstancesOf: [VLCPlaybackNavigationController.self]).prefersLargeTitles = false
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: theme.colors.navigationbarTextColor]
        }

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = theme.colors.mediaCategorySeparatorColor
        UITableViewCell.appearance().selectedBackgroundView = selectedBackgroundView

        // For the edit selection indicators
        UITableView.appearance().tintColor = theme.colors.orangeUI
        UISegmentedControl.appearance().tintColor = theme.colors.orangeUI
        UISwitch.appearance().onTintColor = theme.colors.orangeUI
        UISearchBar.appearance().barTintColor = .white

        UITabBar.appearance().tintColor = theme.colors.orangeUI
        if #available(iOS 10.0, *) {
            UITabBar.appearance().unselectedItemTintColor = theme.colors.cellDetailTextColor
        }

        UIPageControl.appearance().backgroundColor = theme.colors.background
        UIPageControl.appearance().pageIndicatorTintColor = .lightGray
        UIPageControl.appearance().currentPageIndicatorTintColor = theme.colors.orangeUI
    }

    @available(iOS 13.0, *)
    @objc class func navigationbarAppearance() -> UINavigationBarAppearance {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.backgroundColor = PresentationTheme.current.colors.navigationbarColor
        navBarAppearance.titleTextAttributes = [.foregroundColor: PresentationTheme.current.colors.navigationbarTextColor]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: PresentationTheme.current.colors.navigationbarTextColor]
        return navBarAppearance
    }
}

//extensions so that preferredStatusBarStyle is called on all childViewControllers otherwise this is not forwarded
extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    override open var childForStatusBarStyle: UIViewController? {
        return self.topViewController
    }
}
