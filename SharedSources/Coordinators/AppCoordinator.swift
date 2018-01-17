//
//  AppCoordinator.swift
//  VLC-iOS
//
//  Created by Carola Nitz on 11/30/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

import Foundation

@objc class AppCoordinator : NSObject, VLCTabbarCooordinatorDelegate {
    var childCoordinators: [NSObject] = []

    private var tabBarController:UITabBarController

    @objc public init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        super.init()
    }

    @objc public func start() {
        let tabbarCoordinator = VLCTabbarCooordinator(tabBarController: self.tabBarController)
        tabbarCoordinator.delegate = self
        tabbarCoordinator.start()
        childCoordinators.append(tabbarCoordinator)
    }
}
