/*****************************************************************************
 * PodcastEpisodeDownloader.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import VLCMediaLibraryKit

final class PodcastEpisodeDownloader {
    static let shared = PodcastEpisodeDownloader()

    private let downloader = VLCMediaDownloader()
    private let lock = NSLock()
    private var activeWorkers: [String: Worker] = [:]

    private init() {}

    func isDownloading(episodeId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return activeWorkers[episodeId] != nil
    }

    func download(media: VLCMLMedia, completion: @escaping (Bool) -> Void) {
        let episodeId = String(media.identifier())

        lock.lock()
        guard activeWorkers[episodeId] == nil else {
            lock.unlock()
            return
        }
        let worker = Worker(media: media)
        activeWorkers[episodeId] = worker
        lock.unlock()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let success = worker.run(downloader: self?.downloader ?? VLCMediaDownloader())
            DispatchQueue.main.async {
                self?.lock.lock()
                self?.activeWorkers.removeValue(forKey: episodeId)
                self?.lock.unlock()
                completion(success)
            }
        }
    }
}

// MARK: - Worker

private extension PodcastEpisodeDownloader {
    final class Worker: NSObject, VLCMediaDownloaderDelegate {
        private static let progressInterval: TimeInterval = 0.5

        private let media: VLCMLMedia
        private let destinationURL: URL
        private var fileHandle: FileHandle?
        private let completionSemaphore = DispatchSemaphore(value: 0)
        private var didSucceed = false
        private var transferToken: UInt = 0
        private var lastProgressReport: TimeInterval = 0

        init(media: VLCMLMedia) {
            self.media = media
            self.destinationURL = Worker.destinationURL(for: media)
        }

        func run(downloader: VLCMediaDownloader) -> Bool {
            guard let remoteMrl = media.mainFile()?.mrl else {
                return false
            }

            let fileManager = FileManager.default

            // addExternalMrl(_:fileType:) always adds a new File row rather than replacing one;
            // without this, re-downloading an episode (e.g. after deleting it) would accumulate
            // one Cache-type row per attempt instead of leaving a single, current one.
            for staleCacheFile in media.files.filter({ $0.type() == .cache }) {
                try? fileManager.removeItem(at: staleCacheFile.mrl)
                staleCacheFile.delete()
            }

            try? fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(),
                                              withIntermediateDirectories: true)
            guard fileManager.createFile(atPath: destinationURL.path, contents: nil),
                  let fileHandle = FileHandle(forWritingAtPath: destinationURL.path),
                  let vlcMedia = VLCMedia(url: remoteMrl) else {
                return false
            }
            self.fileHandle = fileHandle

            let transferController = VLCAppCoordinator.sharedInstance().transferController
            transferToken = transferController.startExternalDownload(withName: media.title)

            guard downloader.downloadMedia(vlcMedia, delegate: self) != nil else {
                fileHandle.closeFile()
                try? fileManager.removeItem(at: destinationURL)
                transferController.failExternalDownload(transferToken, errorDescription: nil)
                return false
            }

            completionSemaphore.wait()
            fileHandle.closeFile()

            if didSucceed {
                transferController.finishExternalDownload(transferToken, filePath: destinationURL.path)
                _ = media.addExternalMrl(destinationURL, fileType: .cache)
            } else {
                try? fileManager.removeItem(at: destinationURL)
                transferController.failExternalDownload(transferToken, errorDescription: nil)
            }
            return didSucceed
        }

        private static func destinationURL(for media: VLCMLMedia) -> URL {
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let directory = cachesDirectory.appendingPathComponent("PodcastDownloads", isDirectory: true)
            let remoteExtension = media.mainFile()?.mrl.pathExtension
            let fileExtension = (remoteExtension?.isEmpty == false) ? remoteExtension! : "mp3"
            return directory.appendingPathComponent(String(media.identifier())).appendingPathExtension(fileExtension)
        }

        // MARK: - VLCMediaDownloaderDelegate

        func mediaDownloadTask(_ task: VLCMediaDownloadTask,
                                didReceive data: Data,
                                position: UInt64,
                                total: UInt64) -> Int {
            fileHandle?.write(data)
            reportProgress(received: position, expected: total)
            return data.count
        }

        func mediaDownloadTask(_ task: VLCMediaDownloadTask, didUpdate status: VLCMediaDownloadStatus) {
            switch status {
            case .pending, .running, .paused:
                return
            case .finished:
                didSucceed = true
            case .cancelled, .error:
                didSucceed = false
            @unknown default:
                didSucceed = false
            }
            completionSemaphore.signal()
        }

        func mediaDownloadTask(_ task: VLCMediaDownloadTask, didReceiveSubitems subitems: VLCMediaList) {
            // A feed that resolves to a playlist cannot be cached as a single file.
            task.cancel()
        }

        private func reportProgress(received: UInt64, expected: UInt64) {
            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastProgressReport >= Worker.progressInterval else {
                return
            }
            lastProgressReport = now
            VLCAppCoordinator.sharedInstance().transferController.updateExternalDownload(
                transferToken, receivedBytes: Int64(received), expectedBytes: Int64(expected))
        }
    }
}
