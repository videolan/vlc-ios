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

class VLCMovieCategoryViewController: VLCMediaCategoryViewController<VLCMLMedia, VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCShowEpisodeCategoryViewController: VLCMediaCategoryViewController<MLShowEpisode, ShowEpisodeModel> {
    init(_ services: Services) {
        let model = ShowEpisodeModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCVideoPlaylistCategoryViewController: VLCMediaCategoryViewController<MLLabel, VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCTrackCategoryViewController: VLCMediaCategoryViewController<VLCMLMedia, AudioModel> {
    init(_ services: Services) {
        let model = AudioModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCGenreCategoryViewController: VLCMediaCategoryViewController<String, GenreModel> {
    init(_ services: Services) {
        let model = GenreModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCArtistCategoryViewController: VLCMediaCategoryViewController<String, ArtistModel> {
    init(_ services: Services) {
        let model = ArtistModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCAlbumCategoryViewController: VLCMediaCategoryViewController<MLAlbum, AlbumModel> {
    init(_ services: Services) {
        let model = AlbumModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCAudioPlaylistCategoryViewController: VLCMediaCategoryViewController<MLLabel, VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}
