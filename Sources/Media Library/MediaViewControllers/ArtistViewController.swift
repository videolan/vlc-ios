/*****************************************************************************
 * ArtistViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2022 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class ArtistViewController: MediaViewController {
    private var artist: VLCMLArtist? = nil

    init(mediaLibraryService: MediaLibraryService, mediaCollection: VLCMLArtist) {
        super.init(mediaLibraryService: mediaLibraryService)
        self.artist = mediaCollection
        setupTitle()
    }

    private func setupTitle() {
        guard let artist = artist else {
            return
        }

        title = artist.title()
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        guard let artist = artist else {
            return []
        }

        let albumCount = artist.albumsCount()
        if albumCount == 0 || albumCount == 1 {
            // Display only the tracks
            return [CollectionCategoryViewController(mediaLibraryService, mediaCollection: artist)]
        } else {
            return [
                ArtistAlbumCategoryViewController(mediaLibraryService, mediaCollection: artist),
                CollectionCategoryViewController(mediaLibraryService, mediaCollection: artist)
            ]
        }
    }

    func resetTitleView() {
        navigationItem.titleView = nil
    }
}
