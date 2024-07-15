//
//  VLCPCloudViewController.swift
//  VLC-iOS
//
//  Created by Eshan Singh on 13/07/24.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import Foundation
import PCloudSDKSwift

class VLCPCloudViewController: VLCCloudStorageTableViewController {

    var pcloudController = VLCPCloudController.pCloudInstance
    var currentFile: Content?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.titleView = UIImageView(image: UIImage(named: "pCloud"))

        self.cloudStorageLogo.image = UIImage(named: "pCloud")
        self.cloudStorageLogo.sizeToFit()
        self.cloudStorageLogo.center = self.view.center

        self.currentPath = String(pcloudController.folderID)

        self.controller = self.pcloudController
        self.controller.delegate = self

        pcloudController.setupData()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.updateViewAfterSessionChange()
        super.viewWillAppear(animated)
    }

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

    override func goBack() {
        if !self.controller.isAuthorized {
            self.navigationController?.popViewController(animated: true)
            return
        }


        if self.currentPath == String(Folder.root) {
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
}

extension VLCPCloudViewController: VLCCloudStorageTableViewCellProtocol {
    func triggerDownload(for cell: VLCCloudStorageTableViewCell!) {
        let indexPath = tableView.indexPath(for: cell)
        let file = controller.currentListFiles[indexPath!.row] as! Content
        pcloudController.downloadFileToDocumentFolder(file: file)
    }
}
