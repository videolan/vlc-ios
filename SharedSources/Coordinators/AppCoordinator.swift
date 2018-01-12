//
//  AppCoordinator.swift
//  VLC-iOS
//
//  Created by Carola Nitz on 11/30/17.
//  Copyright © 2017 VideoLAN. All rights reserved.
//

import Foundation

@objc class AppCoordinator : NSObject, Coordinator {
    let services: Services
    var childCoordinators: [Coordinator] = []

    var rootViewController: UIViewController {
        return self.tabbarController
    }

    /// Window to manage
    let window: UIWindow

    private lazy var tabbarController:VLCTabbarController = {
        let tabBarController = VLCTabbarController()
        return tabBarController
    }()

    @objc public init(window: UIWindow) {
        self.services = Services()
        self.window = window
        super.init()
        self.window.rootViewController = self.rootViewController
        self.window.makeKeyAndVisible()
    }
    @objc public func start() {
    }
}
