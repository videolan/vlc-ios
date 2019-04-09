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
    @objc let medialibraryService = MediaLibraryService()
    @objc let rendererDiscovererManager = VLCRendererDiscovererManager(presentingViewController: nil)
}

@objc class AppCoordinator: NSObject {
    private var childCoordinators: [NSObject] = []
    private var playerController: VLCPlayerDisplayController
    private var tabBarController: UITabBarController
    private var services = Services()
    private var migrationViewController = VLCMigrationViewController(nibName: String(describing: VLCMigrationViewController.self),
                                                                     bundle: nil)

    @objc init(tabBarController: UITabBarController) {
        self.playerController = VLCPlayerDisplayController(services: services)
        self.tabBarController = tabBarController
        super.init()
        setupChildViewControllers()

        // Init the HTTP Server and clean its cache
        // FIXME: VLCHTTPUploaderController should perhaps be a service?
        VLCHTTPUploaderController.sharedInstance().cleanCache()
        VLCHTTPUploaderController.sharedInstance().medialibrary = services.medialibraryService
        services.medialibraryService.migrationDelegate = self
    }

    private func setupChildViewControllers() {
        self.tabBarController.addChild(playerController)
        self.tabBarController.view.addSubview(playerController.view)
        playerController.view.layoutMargins = UIEdgeInsets(top: 0,
                                                           left: 0,
                                                           bottom: tabBarController.tabBar.frame.size.height,
                                                           right: 0)
        playerController.realBottomAnchor = tabBarController.tabBar.topAnchor
        playerController.didMove(toParent: self.tabBarController)
    }

    @objc func start() {

        let tabbarCoordinator = VLCTabBarCoordinator(tabBarController: tabBarController, services: services)
        childCoordinators.append(tabbarCoordinator)
    }
}

extension AppCoordinator: MediaLibraryMigrationDelegate {
    func medialibraryDidStartMigration(_ medialibrary: MediaLibraryService) {
        DispatchQueue.main.async {
            [tabBarController, migrationViewController] in
            tabBarController.present(migrationViewController, animated: true, completion: nil)
        }
    }

    func medialibraryDidFinishMigration(_ medialibrary: MediaLibraryService) {
        DispatchQueue.main.async {
            [migrationViewController] in
            migrationViewController.dismiss(animated: true, completion: nil)
        }
    }

    func medialibraryDidStopMigration(_ medialibrary: MediaLibraryService) {
        if tabBarController.presentedViewController === migrationViewController {
            DispatchQueue.main.async {
                [tabBarController] in
                tabBarController.dismiss(animated: true, completion: nil)
            }
        }
    }
}
