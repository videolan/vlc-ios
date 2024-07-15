//
//  VLCPCloudController.swift
//  VLC-iOS
//
//  Created by Eshan Singh on 13/07/24.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import Foundation
import PCloudSDKSwift

class VLCPCloudController: VLCCloudStorageController {

    @objc static let pCloudInstance: VLCPCloudController = VLCPCloudController()

    var folderID: UInt64 = Folder.root
    var folderFiles: [Content] = []
    var pCloudInstance: PCloudClient?

    // Download
    var downloadQueue: [Content]?
    var isDownloading = false
    var averageSpeed: CGFloat = 0.0
    var startDL: TimeInterval = 0.0
    var lastStatsUpdate: TimeInterval = 0.0

    override var currentListFiles: [Any] {
        return self.folderFiles
    }

    override func startSession() {
        if let client = PCloud.sharedClient {
            pCloudInstance = client
        } else {
            PCloud.setUp(withAppKey: "")
            pCloudInstance = PCloud.sharedClient
        }
        self.isAuthorized = pCloudInstance != nil
    }

    func setupData() {
        if self.isAuthorized {
            fetchFolderMetaData(folderID: self.folderID)
        }
    }

    override func requestDirectoryListing(atPath path: String!) {
        guard let path = path, let folderID = UInt64(path), folderID != self.folderID else {
            return
        }

        self.folderFiles = []

        self.folderID = folderID
        self.fetchFolderMetaData(folderID: folderID)
    }

    private func fetchFolderMetaData(folderID: UInt64) {
        var listFolderTask: CallTask<PCloudAPI.ListFolder>?
        if let pCloudInstance = pCloudInstance {
            listFolderTask = pCloudInstance.listFolder(folderID, recursively: false)
            listFolderTask!.addCompletionBlock { [self] result in
                switch result {
                case .success(let folderMetadata):
                    self.folderFiles = folderMetadata.contents
                    filterContent()
                    self.delegate.mediaListUpdated()
                case .failure(let error):
                    print(error)
                }
            }
            .start()
        }
    }

    func filterContent() {
        for (index, file) in folderFiles.enumerated().reversed() {
            if file.isFile {
                if let fileMetadata = file.fileMetadata {
                    if fileMetadata.isDocument || fileMetadata.isImage {
                        folderFiles.remove(at: index)
                    }
                }
            }
        }
    }

    func playfile(file: Content) {
        if let fileMetadata = file.fileMetadata {
            getFileURL(id: fileMetadata.id, completion: { url in
                if let fileURL = url {
                    let vpc = PlaybackService.sharedInstance()
                    let media = VLCMedia(url: fileURL)
                    let medialist = VLCMediaList()
                    medialist.add(media!)
                    vpc.playMediaList(medialist, firstIndex: 0, subtitlesFilePath: nil)
                }
            })
        }
    }

    private func getFileURL(id: UInt64, completion: @escaping (URL?) -> Void) {
        let fileFetchingTask = pCloudInstance?.getFileLink(forFile: id)
        fileFetchingTask?.addCompletionBlock({ result in
            switch result {
            case .success(let meta):
                if let url = meta.first?.address {
                    completion(url)
                } else {
                    completion(nil)
                }
            case .failure(let error):
                print(error)
                completion(nil)
            }
        }).start()
    }

    func downloadFileToDocumentFolder(file: Content) {
        if self.downloadQueue == nil {
            downloadQueue = []
        }
        self.downloadQueue?.append(file)
        self.delegate.numberOfFilesWaitingToBeDownloadedChanged?()
        self.triggerNextDownload()
    }

    func triggerNextDownload() {
        if !self.downloadQueue!.isEmpty && !self.isDownloading {
            reallyDownloadFileToDocumentFolder(file: downloadQueue![0])
            self.downloadQueue?.remove(at: 0)
            self.delegate.numberOfFilesWaitingToBeDownloadedChanged?()
        } else {
            print(false)
        }
    }

    func reallyDownloadFileToDocumentFolder(file: Content) {
        let searchPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectory = searchPaths[0]
        if let meta = file.fileMetadata {
            let filePath = documentDirectory.appending("/\(meta.name)")
            getFileURL(id: file.fileMetadata!.id, completion: { [self] url in
                if let fileURL = url {
                    downloadFile(path: fileURL, destination: filePath)
                }
            })
            self.startDL = Date.timeIntervalSinceReferenceDate
            delegate.operationWithProgressInformationStarted?()
            self.isDownloading = true
        }
    }

    func downloadFile(path: URL, destination: String) {

        let destination = self.createPotentialPath(from: destination)

        if var destination = destination {
            destination = destination.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!

            let destinationClosure: (URL) throws -> URL = { tempURL in
                let destinationURL = URL(fileURLWithPath: destination)
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                return destinationURL
            }

            let task = pCloudInstance?.downloadFile(from: path, to: destinationClosure)
            task?.start()
            task!.addCompletionBlock { [weak self] result in
                guard let self = self else { return }

                self.delegate?.operationWithProgressInformationStopped!()

                #if os(iOS)
                NotificationCenter.default.post(name: .VLCNewFileAddedNotification, object: self)
                #endif

                self.isDownloading = false
                self.triggerNextDownload()

                switch result {
                case .failure(let error):
                    print("downloadFile failed with network error \(error.localizedDescription)")
                case .success(let destinationURL):
                    print("File downloaded to: \(destinationURL)")
                }
            }

            task?.addProgressBlock { [weak self] bytesWritten, totalBytesExpectedToWrite in
                guard let self = self else { return }

                if (self.lastStatsUpdate > 0 && (Date.timeIntervalSinceReferenceDate - self.lastStatsUpdate > 0.5)) || self.lastStatsUpdate <= 0 {
                    self.calculateRemainingTime(receivedDataSize: CGFloat(bytesWritten), expectedDownloadSize: CGFloat(totalBytesExpectedToWrite))
                    self.lastStatsUpdate = Date.timeIntervalSinceReferenceDate
                }

                self.delegate?.currentProgressInformation!(CGFloat(bytesWritten) / CGFloat(totalBytesExpectedToWrite))
            }
        }
    }

    func calculateRemainingTime(receivedDataSize: CGFloat, expectedDownloadSize: CGFloat) {
            let lastSpeed = receivedDataSize / CGFloat(Date.timeIntervalSinceReferenceDate - self.startDL)
            let smoothingFactor: CGFloat = 0.005
            self.averageSpeed = self.averageSpeed.isNaN ? lastSpeed : smoothingFactor * lastSpeed + (1 - smoothingFactor) * self.averageSpeed

            let remainingInSeconds = (expectedDownloadSize - receivedDataSize) / self.averageSpeed

            let date = Date(timeIntervalSince1970: TimeInterval(remainingInSeconds))
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            let remainingTime = formatter.string(from: date)
            self.delegate?.updateRemainingTime!(remainingTime)
    }

    override func logout() {
        PCloud.unlinkAllUsers()
        folderFiles = []
        self.isAuthorized = false
        delegate.mediaListUpdated()
    }
}
