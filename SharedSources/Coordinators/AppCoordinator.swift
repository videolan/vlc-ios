//
//  AppCoordinator.swift
//  VLC-iOS
//
//  Created by Carola Nitz on 11/30/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

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
