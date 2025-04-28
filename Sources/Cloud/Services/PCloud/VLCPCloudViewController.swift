/*****************************************************************************
 * VLCPCloudViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2025 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Eshan Singh <eeeshan789@icloud.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import PCloudSDKSwift

class VLCPCloudViewController: VLCCloudStorageTableViewController {
    //MARK: - Properties

    var pcloudController = VLCPCloudController.pCloudInstance
    var currentFile: Content?
    var favMode: Bool = false
    var intialFavpath = ""

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()

        let imageView = UIImageView(image: UIImage(named: "pCloud"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        self.navigationItem.titleView = imageView

        cloudStorageLogo.image = UIImage(named: "pCloud")
        cloudStorageLogo.contentMode = .scaleAspectFit
        cloudStorageLogo.clipsToBounds = true
        cloudStorageLogo.sizeToFit()
        cloudStorageLogo.center = self.view.center

        if self.currentPath == nil {
            self.currentPath = String(pcloudController.folderID)
        } else {
            pcloudController.folderID = UInt64(self.currentPath)!
            favMode = true
            intialFavpath = self.currentPath
        }

        controller = pcloudController
        controller.delegate = self

        pcloudController.setupData()
        self.requestInformationForCurrentPath()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.updateViewAfterSessionChange()
        super.viewWillAppear(animated)
        controller = pcloudController
        controller.delegate = self
        pcloudController.setupData()
    }

    // MARK: - Helpers

    override func goBack() {
        // Check authorization status
        if !controller.isAuthorized {
            self.navigationController?.popViewController(animated: true)
            return
        }

        // Determine the appropriate action based on the mode and current path
        let isAtRoot = self.currentPath == String(Folder.root)
        let isInitialFavPath = self.currentPath == intialFavpath

        if favMode && isInitialFavPath {
            pcloudController.folderID = Folder.root
            self.navigationController?.popViewController(animated: true)
        } else if isAtRoot || favMode && isAtRoot {
            self.navigationController?.popViewController(animated: true)
        } else if let previous = currentFile?.folderMetadata?.parentFolderId {
            self.currentPath = String(describing: previous)
            self.requestInformationForCurrentPath()
        }
    }

    override func loginAction(_ sender: Any!) {
        self.authorizationInProgress = true
        PCloud.authorize(with: self) { result in
              if case .success(_) = result {
                  self.pcloudController.startSession()
                  self.requestInformationForCurrentPath()
                  self.updateViewAfterSessionChange()
              }
          }
    }

    override func mediaListUpdated() {
        super.mediaListUpdated()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "PCloudCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? VLCCloudStorageTableViewCell

        if cell == nil {
            cell = VLCCloudStorageTableViewCell(reuseIdentifier: cellIdentifier)
        }

        let pCloudFile = VLCPCloudCellContentWrapper(content: controller.currentListFiles[indexPath.row] as! Content)
        cell?.pcloudFile = pCloudFile
        cell?.delegate = self
        return cell!
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView!, didSelectRowAt indexPath: IndexPath!) {
        tableView.deselectRow(at: indexPath, animated: true)

        let file = controller.currentListFiles[indexPath.row] as! Content
        if file.isFolder {
            // Dive into Sub Directory
            if let folderId = file.folderMetadata?.id {
                let folderIdString = String(folderId)
                print(folderIdString)
                self.currentPath = folderIdString
                self.currentFile = file
                self.requestInformationForCurrentPath()
            } else {
                print("Folder ID is nil")
                return
            }
        } else {
            // Play the media file
            self.pcloudController.playfile(file: file)
        }
    }
}

// MARK: - VLCCloudStorageTableViewCellProtocol
extension VLCPCloudViewController: VLCCloudStorageTableViewCellProtocol {
    func triggerFavorite(for cell: VLCCloudStorageTableViewCell!) {
        if let indexPath = self.tableView.indexPath(for: cell) {
            let service = VLCAppCoordinator.sharedInstance().favoriteService
            let pCloudFile = VLCPCloudCellContentWrapper(content: controller.currentListFiles[indexPath.row] as! Content)
            let favorite = VLCFavorite()

            if let userName = pCloudFile.name {
                favorite.userVisibleName = userName
                if let folderId = pCloudFile.content.folderMetadata?.id {
                   let folderIdString = String(folderId)
                   let urlString = "file://PCloud/\(folderIdString)"
                    if let url = URL(string: urlString) {
                        favorite.url = url
                    }
                }
            }

            if cell.isFavourite {
               service.add(favorite)
            } else {
               service.remove(favorite)
            }
        }
    }

    func triggerDownload(for cell: VLCCloudStorageTableViewCell!) {
        let indexPath = tableView.indexPath(for: cell)
        let file = controller.currentListFiles[indexPath!.row] as! Content
        pcloudController.downloadFileToDocumentFolder(file: file)
    }
}
