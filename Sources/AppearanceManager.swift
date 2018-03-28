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
class AppearanceManager:NSObject
{
    @objc class func setupAppearance(theme:PresentationTheme = PresentationTheme.current)
    {
        // Change the keyboard for UISearchBar
        UITextField.appearance().keyboardAppearance = theme == PresentationTheme.darkTheme ? .dark : .light
        // For the cursor
        UITextField.appearance().tintColor = theme.colors.orangeUI

        // Don't override the 'Cancel' button color in the search bar with the previous UITextField call. Use the default blue color
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)

        UINavigationBar.appearance().barTintColor = theme.colors.orangeUI
        UINavigationBar.appearance(whenContainedInInstancesOf: [VLCPlaybackNavigationController.self]).barTintColor = nil
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().titleTextAttributes = attributes

        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().prefersLargeTitles = true
            UINavigationBar.appearance(whenContainedInInstancesOf:[VLCPlaybackNavigationController.self]).prefersLargeTitles = false
            UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        }
        // For the edit selection indicators
        UITableView.appearance().tintColor = theme.colors.orangeUI
        UISegmentedControl.appearance().tintColor = theme.colors.orangeUI
        UISwitch.appearance().onTintColor = theme.colors.orangeUI
        UISearchBar.appearance().barTintColor = .white

        UITabBar.appearance().tintColor = theme.colors.orangeUI
        //customization of MoreViewController
        //Since there is no clean way to customize the Morecontroller appearance we're getting the class
        if let moreListControllerClass = NSClassFromString("UIMoreListController") as? UIAppearanceContainer.Type {
            UITableViewCell.appearance(whenContainedInInstancesOf: [moreListControllerClass.self]).backgroundColor = theme.colors.cellBackgroundA
            UITableViewCell.appearance(whenContainedInInstancesOf: [moreListControllerClass.self]).textLabel?.textColor = theme.colors.cellTextColor
            UITableView.appearance(whenContainedInInstancesOf: [moreListControllerClass.self]).backgroundColor = theme.colors.background
            UITableView.appearance(whenContainedInInstancesOf: [moreListControllerClass.self]).separatorColor = .lightGray
            UILabel.appearance(whenContainedInInstancesOf: [moreListControllerClass.self]).textColor = theme.colors.cellTextColor
        }
    }
}
