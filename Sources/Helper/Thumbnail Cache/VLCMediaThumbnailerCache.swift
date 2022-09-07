/*****************************************************************************
 * VLCMediaThumbnailerCache.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@objc class VLCMediaThumbnailerCache: NSObject, VLCMediaThumbnailerDelegate {

    @objc func getVideoThumbnail(_ videoURL: NSString) {
        if getThumbnailURL(videoURL) != nil {
            return
        }

        let media = VLCMedia(url: URL(fileURLWithPath: videoURL.removingPercentEncoding!))

        let thumbnailer = VLCMediaThumbnailer(media: media, andDelegate: self)

        let thumbSize = CGSize(width: 800, height: 600)
        thumbnailer.thumbnailWidth = thumbSize.width
        thumbnailer.thumbnailHeight = thumbSize.height

        thumbnailer.fetchThumbnail()
    }

    // MARK: - VLCMediaThumbnailer data source
    func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer, didFinishThumbnail thumbnail: CGImage) {
        let thumbnailImage: UIImage? = UIImage.init(cgImage: thumbnail)
        if thumbnailImage != nil {
            guard let mediaURL = mediaThumbnailer.media.url else {
                return
            }
            saveThumbnail(thumbnailImage!, mediaURL: mediaURL)
            NotificationCenter.default.post(name: Notification.Name("thumbnailIComplete"), object: nil)
        }
    }

    func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer) {
        print("Time out : \(String(describing: mediaThumbnailer.media.url))")
    }

    // MARK: - 
    private func getThumbnailDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
        let thumbnailDirectory = paths.appendingPathComponent("thumbnail")
        return thumbnailDirectory.removingPercentEncoding! as NSString
    }

    @objc func getThumbnailURL(_ mediaPath: NSString) -> URL? {
        let thumbnailDir = getThumbnailDirectory()
        let thumbnailPath = String(format: "%@/%@.%@", thumbnailDir, (mediaPath.lastPathComponent as NSString).deletingPathExtension.removingPercentEncoding!, "png")

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: thumbnailPath) {
            return URL.init(fileURLWithPath: thumbnailPath)
        }
        return nil
    }

    @objc func removeThumbnail(_ mediaPath: NSString? = nil) {
        var thumbnailPath = getThumbnailDirectory()

        if mediaPath != nil {
            thumbnailPath = NSString(format: "%@/%@.%@", thumbnailPath, (mediaPath!.lastPathComponent as NSString ).deletingPathExtension.removingPercentEncoding!, "png")
        }

        let fileManager = FileManager.default
        var isDir = ObjCBool(false)
        if fileManager.fileExists(atPath: thumbnailPath as String, isDirectory: &isDir) {
            do {
                try fileManager.removeItem(atPath: thumbnailPath as String)
                //print("removed : \(String(describing: thumbnailPath))")
            }
            catch let error as NSError {
                print("error remove : \(error)")
            }
        }
    }

    func saveThumbnail(_ thumbnail: UIImage, mediaURL: URL) {
        let imageData = thumbnail.pngData()
        
        let pngSize: Int = imageData?.count ?? 0
        if pngSize > getFreeDiskSpace() ?? 0 {
            return
        }

        let thumbnailDir = getThumbnailDirectory()
        let thumbnailPath = NSString(format: "%@/%@.%@", thumbnailDir, ((mediaURL.relativePath.removingPercentEncoding! as NSString).lastPathComponent as NSString).deletingPathExtension, "png")

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: thumbnailDir as String) {
            do {
                try fileManager.createDirectory(atPath: thumbnailDir as String, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError {
                print("error creating directory: \(error)")
            }
        }
        if !fileManager.fileExists(atPath: thumbnailPath as String) {
            do {
                try imageData?.write(to: URL(fileURLWithPath: thumbnailPath.standardizingPath, relativeTo: nil))
            } catch let error as NSError {
                print("error writing thumbnail : \(error)")
            }
        }
    }

    func getFreeDiskSpace() -> Int? {
        let fileURL = URL(fileURLWithPath:"/")
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let capacity = values.volumeAvailableCapacity {
                //print("Available capacity for important usage: \(capacity)")
                return capacity
            } else {
                print("Capacity is unavailable")
            }
        } catch {
            print("Error retrieving capacity")
        }
        return nil
    }

}
