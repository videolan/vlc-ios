/*****************************************************************************
* URL+isHidden.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2020 VideoLAN. All rights reserved.
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

/*
 * This extension adds helpers to manage whether a file is hidden in Files.app or not.
*/

extension URL {
    func isHidden() -> Bool {
        let isHidden = try? resourceValues(forKeys:[URLResourceKey.isHiddenKey])

        return isHidden?.isHidden ?? false
    }

    mutating func setHidden(_ hidden: Bool, recursive: Bool = false, onlyFirstLevel: Bool = false, _ completion: (() -> Void)? = nil) {
        var recursive = recursive

        if let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            var resourceValue = URLResourceValues()

            resourceValue.isHidden = hidden
            if path != documentPath
                && lastPathComponent != NSLocalizedString("MEDIALIBRARY_FILES_PLACEHOLDER", comment: "")
                && lastPathComponent != NSLocalizedString("MEDIALIBRARY_ADDING_PLACEHOLDER", comment: "") {
                // Hiding Documents folder is a nonsense, therefore we hide its content.
                // Do not hide MEDIALIBRARY_ files, this one should always be shown so VLC directory will appear
                // in Files.app and show feedback there.
                do {
                    try setResourceValues(resourceValue)
                } catch let error {
                    NSLog("URL+isHidden: \(error.localizedDescription)")
                }
            }
        }
        if recursive {
            if onlyFirstLevel && hidden {
                recursive = false
            }
            do {
                let content = try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [])
                for var element in content {
                    element.setHidden(hidden, recursive: recursive)
                }
            } catch let error as CocoaError where error.code == .fileReadUnknown
                && (error.underlying as? POSIXError)?.code == .ENOTDIR {
                // If self is not a directory, do nothing
            } catch let error {
                NSLog("URL+isHidden: \(error.localizedDescription)")
            }
        }
        completion?()
    }

}

@objc extension NSURL {
    @objc func isHidden() -> Bool {
        if let path = path {
            let url = URL(fileURLWithPath: path)
            return url.isHidden()
        }
        return false
    }

    @objc func setHidden(_ hidden: Bool, recursive: Bool = false, onlyFirstLevel: Bool = false, _ completion: (() -> Void)? = nil) {
        if let path = path {
            var url = URL(fileURLWithPath: path)
            url.setHidden(hidden, recursive: recursive, onlyFirstLevel: onlyFirstLevel, completion)
        }
    }
}
