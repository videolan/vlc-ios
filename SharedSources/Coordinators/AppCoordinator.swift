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
        return self.navigationController
    }

    /// Window to manage
    let window: UIWindow

    private lazy var navigationController: UINavigationController = {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        return navigationController
    }()

    @objc public init(window: UIWindow) {
        self.services = Services()
        self.window = window
        super.init()
        self.window.rootViewController = self.rootViewController
        self.window.makeKeyAndVisible()
    }

    @objc public func start() {
        showPlayerDisplayController()
    }

    private func showPlayerDisplayController() {
        if let playerDisplayController = VLCPlayerDisplayController.sharedInstance() {
            navigationController.setViewControllers([playerDisplayController], animated: true)
        }
    }
}
