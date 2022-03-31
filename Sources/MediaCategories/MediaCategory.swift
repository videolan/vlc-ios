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
    init(_ services: Services) {
        let model = MediaGroupViewModel(medialibrary: services.medialibraryService)
        super.init(services: services, model: model)
        model.observable.addObserver(self)
    }
}

class ShowEpisodeCategoryViewController: MediaCategoryViewController {
    init(_ services: Services) {
        let model = ShowEpisodeModel(medialibrary: services.medialibraryService)
        super.init(services: services, model: model)
        model.observable.addObserver(self)
    }
}

class PlaylistCategoryViewController: MediaCategoryViewController {
    init(_ services: Services) {
        let model = PlaylistModel(medialibrary: services.medialibraryService)
        super.init(services: services, model: model)
        model.observable.addObserver(self)
    }
}

class TrackCategoryViewController: MediaCategoryViewController {
    init(_ services: Services) {
        let model = TrackModel(medialibrary: services.medialibraryService)
        super.init(services: services, model: model)
        model.observable.addObserver(self)
    }
}

class GenreCategoryViewController: MediaCategoryViewController {
    init(_ services: Services) {
        let model = GenreModel(medialibrary: services.medialibraryService)
        super.init(services: services, model: model)
        model.observable.addObserver(self)
    }
}

class ArtistCategoryViewController: MediaCategoryViewController {
    init(_ services: Services) {
        let model = ArtistModel(medialibrary: services.medialibraryService)
        super.init(services: services, model: model)
        model.observable.addObserver(self)
    }
}

class AlbumCategoryViewController: MediaCategoryViewController {
    init(_ services: Services) {
        let model = AlbumModel(medialibrary: services.medialibraryService)
        super.init(services: services, model: model)
        model.observable.addObserver(self)
    }
}

class ArtistAlbumCategoryViewController: MediaCategoryViewController {
    init(_ services: Services, mediaCollection: VLCMLArtist) {
        let model = AlbumModel(medialibrary: services.medialibraryService, artist: mediaCollection)
        super.init(services: services, model: model)
        model.observable.addObserver(self)
    }
}

class CollectionCategoryViewController: MediaCategoryViewController {
    init(_ services: Services, mediaCollection: MediaCollectionModel) {
        let model = CollectionModel(mediaService: services.medialibraryService, mediaCollection: mediaCollection)
        super.init(services: services, model: model)
        model.observable.addObserver(self)
    }
}
