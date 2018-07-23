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

class VLCMovieCategoryViewController: VLCMediaCategoryViewController<MLFile> {
    init(_ services: Services) {
        super.init(services: services, subcategory: VLCMediaSubcategories.movies)
    }
}

class VLCShowEpisodeCategoryViewController: VLCMediaCategoryViewController<MLShowEpisode> {
    init(_ services: Services) {
        super.init(services: services, subcategory: VLCMediaSubcategories.episodes)
    }
}

class VLCVideoPlaylistCategoryViewController: VLCMediaCategoryViewController<MLLabel> {
    init(_ services: Services) {
        super.init(services: services, subcategory: VLCMediaSubcategories.videoPlaylists)
    }
}

class VLCTrackCategoryViewController: VLCMediaCategoryViewController<MLFile> {
    init(_ services: Services) {
        super.init(services: services, subcategory: VLCMediaSubcategories.tracks)
    }
}

class VLCGenreCategoryViewController: VLCMediaCategoryViewController<String> {
    init(_ services: Services) {
        super.init(services: services, subcategory: VLCMediaSubcategories.genres)
    }
}

class VLCArtistCategoryViewController: VLCMediaCategoryViewController<String> {
    init(_ services: Services) {
        super.init(services: services, subcategory: VLCMediaSubcategories.artists)
    }
}

class VLCAlbumCategoryViewController: VLCMediaCategoryViewController<MLAlbum> {
    init(_ services: Services) {
        super.init(services: services, subcategory: VLCMediaSubcategories.albums)
    }
}

class VLCAudioPlaylistCategoryViewController: VLCMediaCategoryViewController<MLLabel> {
    init(_ services: Services) {
        super.init(services: services, subcategory: VLCMediaSubcategories.audioPlaylists)
    }
}
