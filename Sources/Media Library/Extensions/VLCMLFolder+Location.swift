/*****************************************************************************
 * VLCMLFolder+Location.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

extension VLCMLFolder {
    enum Location {
        case device
        case externalDrive
        case iCloudDrive

        init?(url: URL) {
            guard let values = try? url.resourceValues(forKeys: [.isUbiquitousItemKey, .volumeIdentifierKey]) else {
                return nil
            }

            if values.isUbiquitousItem == true {
                self = .iCloudDrive
                return
            }

            guard let volume = values.volumeIdentifier,
                  let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                  let documentsVolume = try? documentsURL.resourceValues(forKeys: [.volumeIdentifierKey]).volumeIdentifier else {
                return nil
            }
            self = volume.isEqual(documentsVolume) ? .device : .externalDrive
        }

        var symbolName: String {
            switch self {
            case .device:
                return "internaldrive"
            case .externalDrive:
                return "externaldrive"
            case .iCloudDrive:
                return "icloud"
            }
        }

        var accessibilityValue: String {
            switch self {
            case .device:
                return NSLocalizedString("FOLDER_LOCATION_DEVICE", comment: "")
            case .externalDrive:
                return NSLocalizedString("FOLDER_LOCATION_EXTERNAL_DRIVE", comment: "")
            case .iCloudDrive:
                return NSLocalizedString("FOLDER_LOCATION_ICLOUD_DRIVE", comment: "")
            }
        }
    }

    var displayName: String? {
        if name == "com~apple~CloudDocs" {
            return NSLocalizedString("FOLDER_LOCATION_ICLOUD_DRIVE", comment: "")
        }
        return name
    }
}
