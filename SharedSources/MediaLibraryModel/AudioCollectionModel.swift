/*****************************************************************************
* AudioCollectionModel.swift
*
* Copyright © 2019 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import Foundation

protocol AudioCollectionModel: MLBaseModel { }

extension AudioCollectionModel {
    func delete(_ items: [VLCMLObject]) {
        do {
            for case let item as MediaCollectionModel in items {
                if let tracks = item.files() {
                    for track in tracks {
                        if let mainFile = track.mainFile() {
                            try FileManager.default.removeItem(atPath: mainFile.mrl.path)
                        }
                    }
                    let folderPaths = Set(tracks.map {
                        $0.mainFile()?.mrl.deletingLastPathComponent()
                    })
                    for path in folderPaths {
                        if let path = path {
                            try FileManager.default.deleteMediaFolder(name: item.title(), at: path)
                        }
                    }
                }
            }
            filterFilesFromDeletion(of: items)
            medialibrary.reload()
        }
        catch let error as NSError {
            assertionFailure("AudioCollectionModel: Delete failed: \(error.localizedDescription)")
        }
    }
}
