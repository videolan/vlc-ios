/*****************************************************************************
 * UIDevice+VLC.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc extension UIDevice {
    @objc(VLCFreeDiskSpace)
    var freeDiskSpace: NSNumber {
        if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last {
            do {
                let dictionary = try FileManager.default.attributesOfFileSystem(forPath: path)
                if let totalSpace = dictionary[FileAttributeKey.systemSize] as? Int64,
                    let totalFreeSpace = dictionary[FileAttributeKey.systemFreeSize] as? Int64 {
                    let totalSize = ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
                    let totalFreeSize = ByteCountFormatter.string(fromByteCount: totalFreeSpace, countStyle: .file)
                    APLog("Memory Capacity of \(totalSize) with \(totalFreeSize) Free memory available.")
                    return NSNumber(value: totalFreeSpace)
                }
            } catch let error as NSError {
                APLog("Error Obtaining System Memory Info: Domain = \(error.domain), Code = \(error.code)")
            }
        }
        return 0
    }

    @objc(VLCHasExternalDisplay)
    var hasExternalDisplay: Bool {
        return UIScreen.screens.count > 1
    }

    @objc(VLCDeviceHasSafeArea)
    static var hasSafeArea: Bool {
        if #available(iOS 11.0, *) {
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            return keyWindow?.safeAreaInsets.bottom ?? 0 > 0
        }
        return false
    }

    static var hasNotch: Bool {
        return hasSafeArea
    }
}
