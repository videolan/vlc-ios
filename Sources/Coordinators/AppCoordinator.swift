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
    private var viewController: UIViewController
    private var playerController: VLCPlayerDisplayController
    private var tabBarController: UITabBarController
    private var services = Services()

    @objc init(viewController: UIViewController) {
        self.viewController = viewController
        self.playerController = VLCPlayerDisplayController(services: services)
        self.tabBarController = UITabBarController()
        super.init()
        setupChildViewControllers()

        // Init the HTTP Server and clean its cache
        // FIXME: VLCHTTPUploaderController should perhaps be a service?
        VLCHTTPUploaderController.sharedInstance().cleanCache()
    }

    private func setupChildViewControllers() {
        viewController.addChildViewController(tabBarController)
        viewController.view.addSubview(tabBarController.view)
        tabBarController.view.frame = viewController.view.frame
        tabBarController.didMove(toParentViewController: viewController)

        viewController.addChildViewController(playerController)
        viewController.view.addSubview(playerController.view)
        playerController.view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: tabBarController.tabBar.frame.size.height, right: 0)
        playerController.realBottomAnchor = tabBarController.tabBar.topAnchor
        playerController.didMove(toParentViewController: viewController)
    }

    @objc func start() {

        let tabbarCoordinator = VLCTabBarCoordinator(tabBarController: tabBarController, services: services)
        childCoordinators.append(tabbarCoordinator)
    }
}
