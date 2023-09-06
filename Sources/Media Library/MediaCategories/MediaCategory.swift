/*****************************************************************************
 * MediaCategory.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class MovieCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = MediaGroupViewModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

class ShowEpisodeCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = ShowEpisodeModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

class PlaylistCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = PlaylistModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

class TrackCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = TrackModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

class GenreCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = GenreModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

class ArtistCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = ArtistModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

class AlbumCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = AlbumModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

class ArtistAlbumCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService, mediaCollection: VLCMLArtist) {
        let model = AlbumModel(medialibrary: mediaLibraryService, artist: mediaCollection)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

class HistoryCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService, mediaType: VLCMLMediaType) {
        let model = HistoryModel(medialibrary: mediaLibraryService, mediaType: mediaType)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

class CollectionCategoryViewController: MediaCategoryViewController {
    private lazy var playAllButton: UIBarButtonItem = {
        let playAllButton = UIBarButtonItem(image: UIImage(named: "iconPlay"), style: .plain, target: self, action: #selector(handlePlayAll))
        playAllButton.accessibilityLabel = NSLocalizedString("PLAY_ALL_BUTTON", comment: "")
        playAllButton.accessibilityHint = NSLocalizedString("PLAY_ALL_HINT", comment: "")
        return playAllButton
    }()

    init(_ mediaLibraryService: MediaLibraryService, mediaCollection: MediaCollectionModel) {
        let model = CollectionModel(mediaService: mediaLibraryService, mediaCollection: mediaCollection)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }

    func getPlayAllButton() -> UIBarButtonItem {
        return playAllButton
    }

    @objc private func handlePlayAll() {
        if let model = model as? CollectionModel,
           let collection = model.mediaCollection as? VLCMLArtist {
            let playbackService = PlaybackService.sharedInstance()
            playbackService.playCollection(collection.tracks())
        }
    }
}
