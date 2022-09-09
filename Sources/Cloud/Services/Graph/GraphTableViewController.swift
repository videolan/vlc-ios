/*****************************************************************************
 * GraphTableViewController.swift
 *
 * Copyright © 2022 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import MSGraphClientModels

@objc (VLCGraphTableViewController)
class GraphTableViewController: VLCCloudStorageTableViewController {
    // MARK: - Properties
    private lazy var graphViewController: GraphViewController = {
        let graphViewController = GraphViewController.sharedObject
        graphViewController.setPresentingViewController(with: self)
        graphViewController.delegate = self
        return graphViewController
    }()

    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()

        prepareMSGraphControllerIfNeeded()

        navigationItem.titleView = UIImageView(image: UIImage(named: "OneDriveWhite"))
        cloudStorageLogo.image = UIImage(named: "OneDriveWhite")
        cloudStorageLogo.sizeToFit()
        cloudStorageLogo.center = view.center
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }

        updateViewAfterSessionChange()
        authorizationInProgress = false
        prepareMSGraphControllerIfNeeded()
        tableView.dataSource = self
    }

    // MARK: - Overriding methods
    override func goBack() {
        let currentItemID = graphViewController.currentItem?.entityId

        if let currentItemID = currentItemID,
           let rootItemID = graphViewController.getRootItemID(),
           currentItemID != rootItemID {
            if graphViewController.parentItem == nil
                || rootItemID == graphViewController.parentItem?.entityId {
                graphViewController.currentItem = nil
            } else {
                graphViewController.currentItem = graphViewController.parentItem
                graphViewController.loadParentItem()
            }

            if let itemName = graphViewController.currentItem?.name {
                title = itemName
            }

            activityIndicator.startAnimating()
            graphViewController.loadCurrentItem()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    override func playAllAction(_ sender: Any!) {
        let mediaList = createMediaList()
        streamMediaList(mediaList: mediaList)
    }

    override func loginAction(_ sender: Any!) {
        if !graphViewController.isAuthorized {
            authorizationInProgress = true
            graphViewController.loginWithViewController(presentingViewController: self)
        } else {
            graphViewController.logout()
        }
    }

    override func sessionWasUpdated() {
        DispatchQueue.main.async {
            self.updateViewAfterSessionChange()
            self.mediaListUpdated()
        }
    }

    override func operationWithProgressInformationStarted() {
        super.operationWithProgressInformationStarted()
    }

    override func operationWithProgressInformationStopped() {
        super.operationWithProgressInformationStopped()
    }

    override func currentProgressInformation(_ progress: CGFloat) {
        super.currentProgressInformation(progress)
    }

    override func updateProgressLabel(_ mediaName: String!) {
        super.updateProgressLabel(mediaName)
    }

    // MARK: - Private helpers
    private func prepareMSGraphControllerIfNeeded() {
        if controller == nil {
            controller = graphViewController
        }
    }

    private func streamMediaList(mediaList: VLCMediaList) {
///        Chunk of code to replace when the .isEmpty property will be available on VLCKit.
//        if mediaList.isEmpty {
        if mediaList.count < 1 {
            return
        }

        let vpc: PlaybackService = PlaybackService.sharedInstance()
        vpc.playMediaList(mediaList, firstIndex: 0, subtitlesFilePath: nil)
    }

    private func addMedia(to mediaList: VLCMediaList, itemName: String?, downloadUrl: String) {
        let url = URL(string: downloadUrl)
        if let url = url {
            let media: VLCMedia = graphViewController.setMediaNameMetadata(VLCMedia(url: url), withName: itemName)
            mediaList.add(media)
        }
    }

    private func createMediaListWithMSGraphDriveItem(item: MSGraphDriveItem? = nil) -> VLCMediaList {
        let folderItems = graphViewController.getCurrentListFiles()
        let mediaList: VLCMediaList = VLCMediaList()
        let downloadUrlDictionary = graphViewController.getDownloadUrlDictionary()

        if let item = item,
           let downloadUrl = downloadUrlDictionary[item] {
            addMedia(to: mediaList, itemName: item.name, downloadUrl: downloadUrl)
        }

        for folderItem in folderItems {
            if folderItem.folder != nil || folderItem == item {
                continue
            }

            if let downloadUrl = downloadUrlDictionary[folderItem] {
                addMedia(to: mediaList, itemName: folderItem.name, downloadUrl: downloadUrl)
            }
        }

        return mediaList
    }

    private func createMediaList() -> VLCMediaList {
        return createMediaListWithMSGraphDriveItem()
    }
}

// MARK: - VLCCloudStorageTableViewCellProtocol
extension GraphTableViewController: VLCCloudStorageTableViewCellProtocol {
    func triggerDownload(for cell: VLCCloudStorageTableViewCell!) {
        let indexPath: IndexPath? = tableView.indexPath(for: cell)
        let currentItems: [MSGraphDriveItem] = graphViewController.getCurrentListFiles()

        guard let indexPath = indexPath,
              indexPath.row < currentItems.count else {
            preconditionFailure("GraphTableViewController: Invalid range.")
        }

        let selectedItem: MSGraphDriveItem = currentItems[indexPath.row]
        var selectedItemName: String = ""
        if let name = selectedItem.name {
            selectedItemName = name
        }

        if selectedItem.size < UIDevice.current.freeDiskSpace.int64Value {
            let alertController = UIAlertController(title: NSLocalizedString("DROPBOX_DOWNLOAD", comment: ""),
                                                    message: String(format: NSLocalizedString("DROPBOX_DL_LONG", comment: ""),
                                                                    selectedItemName, UIDevice.current.model),
                                                    preferredStyle: .alert)

            let downloadAction = UIAlertAction(title: NSLocalizedString("BUTTON_DOWNLOAD", comment: ""),
                                               style: .default,
                                               handler: { _ in
                self.graphViewController.startDownloadingDriveItem(item: selectedItem)
            })

            let cancelAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                             style: .cancel,
                                             handler: nil)

            alertController.addAction(downloadAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true)
        } else {
            let alertController = UIAlertController(title: NSLocalizedString("DISK_FULL", comment: ""),
                                                    message: String(format: NSLocalizedString("DISK_FULL_FORMAT", comment: ""),
                                                                    selectedItemName, UIDevice.current.model),
                                                    preferredStyle: .alert)

            let okAction = UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""),
                                         style: .cancel,
                                         handler: nil)

            alertController.addAction(okAction)
            present(alertController, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension GraphTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return graphViewController.getCurrentListFiles().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "OneDriveCell"

        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)

        if cell == nil {
            cell = VLCCloudStorageTableViewCell(reuseIdentifier: cellIdentifier)
        }

        if let cell = cell as? VLCCloudStorageTableViewCell,
           indexPath.row < graphViewController.getCurrentListFiles().count {
            cell.delegate = self
            cell.oneDriveFile = graphViewController.getCurrentListFiles()[indexPath.row]
            cell.titleLabel.text = graphViewController.getCurrentListFiles()[indexPath.row].name
            return cell
        }

        return VLCCloudStorageTableViewCell(reuseIdentifier: cellIdentifier)
    }
}

// MARK: - UITableViewDelegate
extension GraphTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentItems = graphViewController.getCurrentListFiles()
        let row = indexPath.row

        guard row < currentItems.count else {
            return
        }

        let selectedItem: MSGraphDriveItem = currentItems[row]

        if selectedItem.folder != nil {
            self.activityIndicator.startAnimating()
            graphViewController.parentItem = graphViewController.currentItem
            graphViewController.currentItem = selectedItem
            graphViewController.loadCurrentItem()
            self.title = selectedItem.name
            tableView.reloadData()
        } else {
            let downloadUrlDictionary = graphViewController.getDownloadUrlDictionary()
            if let downloadUrl = downloadUrlDictionary[selectedItem] {
                var mediaList: VLCMediaList
                let url = URL(string: downloadUrl)
                var mediaToPlay: VLCMedia = VLCMedia(url: url!)
                mediaToPlay = graphViewController.setMediaNameMetadata(mediaToPlay, withName: selectedItem.name)

                if !UserDefaults.standard.bool(forKey: kVLCAutomaticallyPlayNextItem) {
                    mediaList = VLCMediaList(array: [mediaToPlay])
                } else {
                    mediaList = createMediaListWithMSGraphDriveItem(item: selectedItem)
                }
                streamMediaList(mediaList: mediaList)
            } else {
                let alertController = UIAlertController(title: NSLocalizedString("ERROR", comment: ""),
                                                        message: NSLocalizedString("ONEDRIVE_MEDIA_WITHOUT_URL", comment: ""),
                                                        preferredStyle: .alert)

                let okAction = UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""),
                                             style: .cancel,
                                             handler: nil)

                alertController.addAction(okAction)
                present(alertController, animated: true)
            }
        }

        self.tableView.deselectRow(at: indexPath, animated: false)
    }
}
