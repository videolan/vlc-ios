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
    }
}

class VLCShowEpisodeCategoryViewController: VLCMediaCategoryViewController<MLShowEpisode, ShowEpisodeModel> {
    init(_ services: Services) {
        let model = ShowEpisodeModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
    }
}

class VLCVideoPlaylistCategoryViewController: VLCMediaCategoryViewController<MLLabel, VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
 }
}

class VLCTrackCategoryViewController: VLCMediaCategoryViewController<MLFile, VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
    }
}

class VLCGenreCategoryViewController: VLCMediaCategoryViewController<String, VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
    }
}

class VLCArtistCategoryViewController: VLCMediaCategoryViewController<String, VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
    }
}

class VLCAlbumCategoryViewController: VLCMediaCategoryViewController<MLAlbum, VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
    }
}

class VLCAudioPlaylistCategoryViewController: VLCMediaCategoryViewController<MLLabel, VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
    }
}
