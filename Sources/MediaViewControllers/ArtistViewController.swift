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

    init(services: Services, mediaCollection: VLCMLArtist) {
        super.init(services: services)
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

        if artist.albumsCount() == 0 {
            return [CollectionCategoryViewController(services, mediaCollection: artist)]
        } else {
            return [
                ArtistAlbumCategoryViewController(services, mediaCollection: artist),
                CollectionCategoryViewController(services, mediaCollection: artist)
            ]
        }
    }
}
