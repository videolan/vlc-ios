/*****************************************************************************
 * AppCoordinator.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
import Foundation

@objc(VLCService)
public class Services:NSObject {
    @objc let mediaDataSource = VLCMediaDataSource()
}

@objc class AppCoordinator : NSObject {

    var childCoordinators: [NSObject] = []
    private var tabBarController:UITabBarController
    private var services = Services()

    @objc public init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        super.init()
    }

    @objc public func start() {
        let tabbarCoordinator = VLCTabbarCooordinator(tabBarController: self.tabBarController, services:services)
        tabbarCoordinator.start()
        childCoordinators.append(tabbarCoordinator)
    }
}
