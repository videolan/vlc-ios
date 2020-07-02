/*****************************************************************************
* URL+isExcludedFromBackup.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2019 VideoLAN. All rights reserved.
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

/*
 * This extension adds helpers to manage exclusion from device backup (QA1719)
*/

extension URL {
    func isExcludedFromBackup() -> Bool {
        let isExcludedFromBackup = try? resourceValues(forKeys:[URLResourceKey.isExcludedFromBackupKey])

        return isExcludedFromBackup?.isExcludedFromBackup ?? false
    }

    mutating func setExcludedFromBackup(_ excluded: Bool, recursive: Bool = false, onlyFirstLevel: Bool = false, _ completion: (() -> Void)? = nil) {
        var recursive = recursive

        if let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            var resourceValue = URLResourceValues()

            resourceValue.isExcludedFromBackup = excluded
            if path == documentPath {
                // iOS 11+ : Never exclude the Documents folder from backup, it makes iOS Files app hide VLC.
                // iOS 9 / 10 : usually not powerful old devices, the Files app is not available.
                // Exclude Documents anyway, do not exclude its content though, it would be useless.
                if #available(iOS 11.0, *) {
                    resourceValue.isExcludedFromBackup = false
                } else if excluded {
                    // If we have an iOS 9 / 10 device and want to exclude from backup, no need to be recursive,
                    // excluding the Documents folder will be enough.
                    // If we are including into the backup, we will stay recursive, all files get reincluded, as
                    // older VLC iOS versions used per-file exclusion.
                    recursive = false
                }
            }
            do {
                try setResourceValues(resourceValue)
            } catch let error {
                NSLog("URL+isExcludedFromBackup: \(error.localizedDescription)")
            }
        }
        if recursive {
            // As older VLC versions excluded the library on a per-file basis, the new exclusion system
            // may only be applied to exclusion.
            if onlyFirstLevel && excluded {
                recursive = false
            }
            do {
                let content = try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [])
                for var element in content {
                    element.setExcludedFromBackup(excluded, recursive: recursive)
                }
            } catch let error as CocoaError where error.code == .fileReadUnknown
                && (error.underlying as? POSIXError)?.code == .ENOTDIR {
                // If self is not a directory, do nothing
            } catch let error {
                NSLog("URL+isExcludedFromBackup: \(error.localizedDescription)")
            }
        }
        completion?()
    }

}

@objc extension NSURL {
    @objc func isExcludedFromBackup() -> Bool {
        if let path = path {
            let url = URL(fileURLWithPath: path)
            return url.isExcludedFromBackup()
        }
        return false
    }

    @objc func setExcludedFromBackup(_ excluded: Bool, recursive: Bool = false, onlyFirstLevel: Bool = false, _ completion: (() -> Void)? = nil) {
        if let path = path {
            var url = URL(fileURLWithPath: path)
            url.setExcludedFromBackup(excluded, recursive: recursive, onlyFirstLevel: onlyFirstLevel, completion)
        }
    }
}
