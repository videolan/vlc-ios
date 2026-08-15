/*****************************************************************************
 * RadioStation.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: David Neacsu <neacsudavid287 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import VLCKit

struct RadioStation: Identifiable {
    let id: String
    let title: String
    let imageURL: URL?
    let media: VLCMedia
    
    var isDirectory: Bool {
        media.mediaType == .directory
    }
}

struct RadioStationStorage: Codable, Identifiable {
    let id: String
    let title: String
    let imageURL: URL?
    let mediaURL: URL?
}

struct SavedStations: Codable {
    var recents: [RadioStationStorage]
    var favorites: [RadioStationStorage]
}

extension RadioStation {
    var record: RadioStationStorage {
        RadioStationStorage(id: id, title: title, imageURL: imageURL, mediaURL: media.url)
    }
    
    init?(record: RadioStationStorage) {
        guard let mediaURL = record.mediaURL, let media = VLCMedia(url: mediaURL) else {
            return nil
        }
                             
        self.init(id: record.id, title: record.title, imageURL: record.imageURL, media: media)
    }
}
