/*****************************************************************************
 * VLCMediaSubcategory.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
import Foundation

extension Notification.Name {
    static let VLCMoviesDidChangeNotification = Notification.Name("MoviesDidChangeNotfication")
    static let VLCEpisodesDidChangeNotification = Notification.Name("EpisodesDidChangeNotfication")
    static let VLCArtistsDidChangeNotification = Notification.Name("ArtistsDidChangeNotfication")
    static let VLCAlbumsDidChangeNotification = Notification.Name("AlbumsDidChangeNotfication")
    static let VLCTracksDidChangeNotification = Notification.Name("TracksDidChangeNotfication")
    static let VLCGenresDidChangeNotification = Notification.Name("GenresDidChangeNotfication")
    static let VLCAudioPlaylistsDidChangeNotification = Notification.Name("AudioPlaylistsDidChangeNotfication")
    static let VLCVideoPlaylistsDidChangeNotification = Notification.Name("VideoPlaylistsDidChangeNotfication")
    static let VLCVideosDidChangeNotification = Notification.Name("VideosDidChangeNotfication")
}

enum VLCDataUnit {
    case file(VLCMLMedia)
    case episode(MLShowEpisode)
    case album(MLAlbum)
    case label(MLLabel)
}

class VLCMediaSubcategoryModel<T>: NSObject {
    var files: [T]
    var indicatorInfoName: String
    var changeNotificationName: Notification.Name
    var includesFunc: (VLCDataUnit) -> Bool
    var appendFunc: (VLCDataUnit) -> Void

    var indicatorInfo: IndicatorInfo {
        return IndicatorInfo(title: indicatorInfoName)
    }

    init(files: [T],
         indicatorInfoName: String,
         notificationName: Notification.Name,
         includesFunc: @escaping (VLCDataUnit) -> Bool,
         appendFunc: @escaping (VLCDataUnit) -> Void) {
        self.files = files
        self.indicatorInfoName = indicatorInfoName
        self.changeNotificationName = notificationName
        self.includesFunc = includesFunc
        self.appendFunc = appendFunc
    }
}

struct VLCMediaSubcategories {
    static var movies = VLCMediaSubcategory<VLCMLMedia>(
        files: {
//            (MLFile.allFiles() as! [MLFile]).filter {
//            ($0 as MLFile).isKind(ofType: kMLFileTypeMovie) ||
//                ($0 as MLFile).isKind(ofType: kMLFileTypeTVShowEpisode) ||
//                ($0 as MLFile).isKind(ofType: kMLFileTypeClip)
//            }s

        //medialibrary.media(ofType: .video)
            VLCMediaLibraryManager.media(ofType: .video)
        }(),
        indicatorInfoName: NSLocalizedString("MOVIES", comment: ""),
        notificationName: .VLCVideosDidChangeNotification,
        includesFunc: { (dataUnit: VLCDataUnit) in
            if case .file(let f) = dataUnit {
//                return f.isMovie()
            }
            return false
        },
        appendFunc: { (dataUnit: VLCDataUnit) in

        })

    static var episodes = VLCMediaSubcategoryModel<MLShowEpisode>(
        files: MLShowEpisode.allEpisodes() as! [MLShowEpisode],
        indicatorInfoName: NSLocalizedString("EPISODES", comment: ""),
        notificationName: .VLCEpisodesDidChangeNotification,
        includesFunc: { (dataUnit: VLCDataUnit) in
            if case .episode(let f) = dataUnit {
                return true
            }
            return false
        },
        appendFunc: { (dataUnit: VLCDataUnit) in

        })

    static var artists = VLCMediaSubcategoryModel<String>(
        files: {
            let tracksWithArtist = (MLAlbumTrack.allTracks() as! [MLAlbumTrack]).filter { $0.artist != nil && $0.artist != "" }
            return tracksWithArtist.map { $0.artist } as! [String]
        }(),
        indicatorInfoName: NSLocalizedString("ARTISTS", comment: ""),
        notificationName: .VLCArtistsDidChangeNotification,
        includesFunc: { (dataUnit: VLCDataUnit) in
            if case .file(let f) = dataUnit {
//                return f.artist != nil
                return true
            }
            return false
        },
        appendFunc: { (dataUnit: VLCDataUnit) in

        })

    static var albums = VLCMediaSubcategoryModel<MLAlbum>(
        files: MLAlbum.allAlbums() as! [MLAlbum],
        indicatorInfoName: NSLocalizedString("ALBUMS", comment: ""),
        notificationName: .VLCAlbumsDidChangeNotification,
        includesFunc: { (dataUnit: VLCDataUnit) in
            if case .album(let f) = dataUnit {
                return true
            }
            return false
        },
        appendFunc: { (dataUnit: VLCDataUnit) in

        })

    static var tracks = VLCMediaSubcategoryModel<MLFile>(
        files: (MLFile.allFiles() as! [MLFile]).filter { $0.isSupportedAudioFile()},
        indicatorInfoName: NSLocalizedString("SONGS", comment: ""),
        notificationName: .VLCTracksDidChangeNotification,
        includesFunc: { (dataUnit: VLCDataUnit) in
            if case .file(let f) = dataUnit {
//                return f.isSupportedAudioFile()
                return true
            }
            return false
        },
        appendFunc: { (dataUnit: VLCDataUnit) in

        })

    static var genres = VLCMediaSubcategoryModel<String>(
        files: {
            let albumtracks = MLAlbumTrack.allTracks() as! [MLAlbumTrack]
            let tracksWithArtist = albumtracks.filter { $0.genre != nil && $0.genre != "" }
            return tracksWithArtist.map { $0.genre }
        }(),
        indicatorInfoName: NSLocalizedString("GENRES", comment: ""),
        notificationName: .VLCGenresDidChangeNotification ,
        includesFunc: { (dataUnit: VLCDataUnit) in
            if case .file(let f) = dataUnit {
//                return f.genre != nil
                return true
            }
            return false
        },
        appendFunc: { (dataUnit: VLCDataUnit) in

        })

    static var audioPlaylists = VLCMediaSubcategoryModel<MLLabel>(
        files: {
            let labels = MLLabel.allLabels() as! [MLLabel]
            let audioPlaylist = labels.filter {
                let audioFiles = $0.files.filter {
                    if let file = $0 as? MLFile {
                        return file.isSupportedAudioFile()
                    }
                    return false
                }
                return !audioFiles.isEmpty
            }
            return audioPlaylist
        }(),
        indicatorInfoName: NSLocalizedString("AUDIO_PLAYLISTS", comment: ""),
        notificationName: .VLCAudioPlaylistsDidChangeNotification ,
        includesFunc: { (dataUnit: VLCDataUnit) in
            if case .label(let l) = dataUnit {
                let audioFiles = l.files.filter {
                    if let file = $0 as? MLFile {
                        return file.isSupportedAudioFile()
                    } else {
                        return false
                    }
                }
                return !audioFiles.isEmpty
            }
            return false
        },
        appendFunc: { (dataUnit: VLCDataUnit) in

        })

    static var videoPlaylists = VLCMediaSubcategoryModel<MLLabel>(
        files: {
            let labels = MLLabel.allLabels() as! [MLLabel]
            let audioPlaylist = labels.filter {
                let audioFiles = $0.files.filter {
                    if let file = $0 as? MLFile {
                        return file.isShowEpisode() || file.isMovie() || file.isClip()
                    }
                    return false
                }
                return !audioFiles.isEmpty
            }
            return audioPlaylist
        }(),
        indicatorInfoName: NSLocalizedString("VIDEO_PLAYLISTS", comment: ""),
        notificationName: .VLCVideoPlaylistsDidChangeNotification ,
        includesFunc: { (dataUnit: VLCDataUnit) in
            if case .label(let l) = dataUnit {
                let videoFiles = l.files.filter {
                    if let file = $0 as? MLFile {
                        return file.isShowEpisode() || file.isMovie() || file.isClip()
                    } else {
                        return false
                    }
                }
                return !videoFiles.isEmpty
            }
            return false
    },
        appendFunc: { (dataUnit: VLCDataUnit) in

    })
}
