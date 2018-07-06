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

@objc(VLCService)
class Services: NSObject {
    @objc let medialibraryManager = VLCMediaLibraryManager()
    @objc let rendererDiscovererManager = VLCRendererDiscovererManager(presentingViewController: nil)
}

@objc class AppCoordinator: NSObject {
    private var childCoordinators: [NSObject] = []
    private var tabBarController: UITabBarController
    private var playerController: VLCPlayerDisplayController
    private var services = Services()

    @objc init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        self.playerController = VLCPlayerDisplayController(services: services)
        super.init()
        setupPlayerController()
    }

    private func setupPlayerController() {
        tabBarController.addChildViewController(playerController)
        tabBarController.view.addSubview(playerController.view)
        playerController.view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: tabBarController.tabBar.frame.size.height, right: 0)
        playerController.didMove(toParentViewController: tabBarController)
    }

    @objc func start() {
        let tabbarCoordinator = VLCTabBarCoordinator(tabBarController: tabBarController, services: services)
        childCoordinators.append(tabbarCoordinator)
    }
}
