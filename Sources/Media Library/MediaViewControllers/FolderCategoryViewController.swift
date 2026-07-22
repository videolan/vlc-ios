//
//  FolderCategoryViewController.swift
//  VLC-iOS
//
//  Created by Eshan Singh on 10/07/24.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import Foundation

class FolderCategoryViewController: MediaViewController {

    var medialib: MediaLibraryService
    var folder: VLCMLFolder
    var isAudio: Bool

    init(medialib: MediaLibraryService, folder: VLCMLFolder, isAudio: Bool) {
        self.medialib = medialib
        self.folder = folder
        self.isAudio = isAudio
        super.init(mediaLibraryService: medialib)
        title = folder.name
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [FolderViewController(medialib, isAudio: isAudio, folder: folder)]
    }
}
