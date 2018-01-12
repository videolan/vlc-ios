/*****************************************************************************
 * VLCTabbarController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


class VLCTabbarController:UITabBarController
{
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
    }

    func setupViewControllers() {

        //The title needs to be set on the VC here because otherwise it won't appear in the tabbar on first start
        // video
        let videoVC = VLCVideoViewController(collectionViewLayout: UICollectionViewFlowLayout())
        //this should probably not be the delegate
        videoVC.delegate = VLCPlayerDisplayController.sharedInstance()
        videoVC.title = NSLocalizedString("Video",comment: "")
        videoVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Video",comment: ""),
            image: UIImage(named: "TVShowsIcon"),
            selectedImage: UIImage(named: "TVShowsIcon"))

        // Audio
        let audioVC = VLCVideoViewController(collectionViewLayout: UICollectionViewFlowLayout())
        //this should probably not be the delegate
        audioVC.delegate = VLCPlayerDisplayController.sharedInstance()
        audioVC.title = NSLocalizedString("Audio",comment: "")
        audioVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Audio",comment: ""),
            image: UIImage(named: "MusicAlbums"),
            selectedImage:UIImage(named: "MusicAlbums"))

        //Serverlist
        let serverVC = VLCServerListViewController()
        serverVC.title = NSLocalizedString("LOCAL_NETWORK", comment: "");
        serverVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("LOCAL_NETWORK",comment: ""),
            image: UIImage(named: "Local"),
            selectedImage: UIImage(named: "Local"))

        //CloudServices
        let cloudVC = VLCCloudServicesTableViewController(nibName: "VLCCloudServicesTableViewController", bundle: Bundle.main)
        cloudVC.title = NSLocalizedString("CLOUD_SERVICES",comment: "")
        cloudVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("CLOUD_SERVICES",comment: ""),
            image: UIImage(named: "iCloudIcon"),
            selectedImage: UIImage(named: "iCloudIcon"))

        //Settings
        let settingsVC = VLCSettingsController()
        settingsVC.title = NSLocalizedString("Settings",comment: "")
        settingsVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Settings",comment: ""),
            image: UIImage(named: "Settings"),
            selectedImage: UIImage(named: "Settings"))

        //Download
        let downloadVC = VLCDownloadViewController()
        downloadVC.title = NSLocalizedString("DOWNLOAD_FROM_HTTP", comment:"")
        downloadVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("DOWNLOAD_FROM_HTTP",comment: ""),
            image: UIImage(named: "Downloads"),
            selectedImage:  UIImage(named: "Downloads"))

        //Streaming
        let streamVC = VLCOpenNetworkStreamViewController(nibName: "VLCOpenNetworkStreamViewController", bundle: Bundle.main)
        streamVC.title = NSLocalizedString("OPEN_NETWORK", comment: "")
        streamVC.tabBarItem = UITabBarItem(
            title:  NSLocalizedString("OPEN_NETWORK", comment: ""),
            image: UIImage(named: "OpenNetStream"),
            selectedImage: UIImage(named: "OpenNetStream"))

        //About
        let aboutVC = VLCAboutViewController()
        aboutVC.title = NSLocalizedString("ABOUT_APP",comment: "")
        aboutVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("ABOUT_APP",comment: ""),
            image: UIImage(named: "menuCone"),
            selectedImage: UIImage(named: "menuCone"))

        let controllers = [audioVC, serverVC, videoVC, settingsVC, cloudVC, downloadVC, streamVC, aboutVC]
        self.viewControllers = controllers.map { UINavigationController(rootViewController: $0)}
    }

}
