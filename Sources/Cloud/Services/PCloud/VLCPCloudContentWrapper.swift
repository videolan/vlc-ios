//
//  VLCPCloudCellContentWrapper.swift
//  VLC-iOS
//
//  Created by Eshan Singh on 14/07/24.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import Foundation
import PCloudSDKSwift

@objc class VLCPCloudCellContentWrapper: NSObject {

    let content: Content

    @objc var folderID: NSNumber?
    @objc var fileID: NSNumber?
    @objc var fileSize: NSNumber?
    @objc var parent: NSNumber?
    @objc var name: String?
    @objc var isDirectory: Bool

    init(content: Content) {
        self.content = content

        if content.isFolder {
            self.folderID = content.folderMetadata?.id as? NSNumber
            self.parent = content.folderMetadata?.parentFolderId as? NSNumber
            self.name = content.folderMetadata?.name
            self.isDirectory = true
        } else {
            self.fileID = content.fileMetadata?.id as? NSNumber
            self.parent = content.fileMetadata?.parentFolderId as? NSNumber
            self.name = content.fileMetadata?.name
            self.fileSize = content.fileMetadata?.size as? NSNumber
            self.isDirectory = false
        }
    }
}
