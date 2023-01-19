/*****************************************************************************
 * MediaModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import CoreSpotlight

protocol MediaModel: MLBaseModel where MLType == VLCMLMedia { }

extension MediaModel {
    func append(_ item: VLCMLMedia) {
        if !files.contains(where: { $0 == item }) {
            files.append(item)
        }
    }

    func delete(_ items: [VLCMLMedia]) {
        for case let media in items {
            media.deleteMainFile()
        }
        medialibrary.reload()
        filterFilesFromDeletion(of: items)
    }
}

// MARK: - ViewModel

extension VLCMLMedia {
    func deleteMainFile() {
        if let mainFile = mainFile() {
            mainFile.delete()
        }
    }

    @objc func mediaDuration() -> String {
        return String(format: "%@", VLCTime(number: NSNumber.init(value: duration())))
    }

    @objc func formatSize() -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(mainFile()?.size() ?? 0),
                                         countStyle: .file)
    }

    @objc func videoDimensions() -> String {
        if let firstTrack = videoTracks?.first {
            return String(format: NSLocalizedString("FORMAT_VIDEO_DIMENSIONS", comment: ""),
                          firstTrack.width(), firstTrack.height())
        }
        return ""
    }

    @objc func thumbnailImage() -> UIImage? {
        var image = VLCThumbnailsCache.thumbnail(for: thumbnail())
        if image == nil
            || (!UserDefaults.standard.bool(forKey: kVLCSettingShowThumbnails) && subtype() != .albumTrack)
            || (!UserDefaults.standard.bool(forKey: kVLCSettingShowArtworks) && subtype() == .albumTrack) {
            let isDarktheme = PresentationTheme.current.isDark
            if subtype() == .albumTrack {
                image = isDarktheme ? UIImage(named: "song-placeholder-dark") : UIImage(named: "song-placeholder-white")
            } else {
                image = isDarktheme ? UIImage(named: "movie-placeholder-dark") : UIImage(named: "movie-placeholder-white")
            }
        }
        return image
    }

    func accessibilityText(editing: Bool) -> String? {
        if editing {
            return title + " " + mediaDuration() + " " + formatSize()
        }
        return title + " " + albumTrackArtistName() + " " + (isNew ? NSLocalizedString("NEW", comment: "") : "")
    }

    func title() -> String {
        if UserDefaults.standard.bool(forKey: kVLCOptimizeItemNamesForDisplay) == true
            && ((subtype() == .albumTrack && title.isSupportedAudioMediaFormat())
                || (subtype() != .albumTrack && title.isSupportedMediaFormat())) {
            return (title as NSString).deletingPathExtension
        }
        return title
    }
}

// MARK: - CoreSpotlight

extension VLCMLMedia {
    func coreSpotlightAttributeSet() -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: "public.audiovisual-content")
        attributeSet.title = title
        attributeSet.metadataModificationDate = Date()
        attributeSet.addedDate = Date()
        attributeSet.duration = NSNumber(value: duration() / 1000)
        attributeSet.streamable = 0
        attributeSet.deliveryType = 0
        attributeSet.local = 1
        attributeSet.playCount = NSNumber(value: playCount())
        if thumbnailStatus() == .available {
            let image = UIImage(contentsOfFile: thumbnail()?.path ?? "")
            attributeSet.thumbnailData = image?.jpegData(compressionQuality: 0.9)
        }
        attributeSet.codecs = codecs()
        attributeSet.languages = languages()
        if let audioTracks = audioTracks {
            for track in audioTracks {
                attributeSet.audioBitRate = NSNumber(value: track.bitrate())
                attributeSet.audioChannelCount = NSNumber(value: track.nbChannels())
                attributeSet.audioSampleRate = NSNumber(value: track.sampleRate())
            }
        }
        if subtype() == .albumTrack {
            if let genre = genre {
                attributeSet.genre = genre.name
            }
            if let artist = artist {
                attributeSet.artist = artist.name
            }
            attributeSet.audioTrackNumber = NSNumber(value:trackNumber)
            if let album = album {
                attributeSet.artist = album.title
            }
        }

        return attributeSet
    }

    func codecs() -> [String] {
        var codecs = [String]()
        if let videoTracks = videoTracks {
            for track in videoTracks {
                codecs.append(track.codec)
            }
        }
        if let audioTracks = audioTracks {
            for track in audioTracks {
                codecs.append(track.codec)
            }
        }
        if let subtitleTracks = subtitleTracks {
            for track in subtitleTracks {
                codecs.append(track.codec)
            }
        }
        return codecs
    }

    func languages() -> [String] {
        var languages = [String]()

        if let videoTracks = videoTracks {
            for track in videoTracks where track.language != "" {
                languages.append(track.language)
            }
        }
        if let audioTracks = audioTracks {
            for track in audioTracks where track.language != "" {
                languages.append(track.language)
            }
        }
        if let subtitleTracks = subtitleTracks {
            for track in subtitleTracks where track.language != "" {
                languages.append(track.language)
            }
        }
        return languages
    }

    func updateCoreSpotlightEntry() {
        if !KeychainCoordinator.passcodeLockEnabled {
            let groupIdentifier = ProcessInfo.processInfo.environment["GROUP_IDENTIFIER"]
            let item = CSSearchableItem(uniqueIdentifier: "\(identifier())", domainIdentifier: groupIdentifier, attributeSet: coreSpotlightAttributeSet())
            CSSearchableIndex.default().indexSearchableItems([item], completionHandler: nil)
        }
    }
}

// MARK: - Search
extension VLCMLMedia: SearchableMLModel {
    func contains(_ searchString: String) -> Bool {
        var matches = false

        if subtype() == .albumTrack {
            matches = matches || artist?.contains(searchString) ?? false
            matches = matches || genre?.contains(searchString) ?? false
            matches = matches || album?.contains(searchString) ?? false
        }

        matches = matches || title.lowercased().contains(searchString)

        return matches
    }
}

extension VLCMLMedia {
    func albumTrackArtistName() -> String {
        guard let artist = artist, artist.identifier() != UnknownArtistID else {
            return NSLocalizedString("UNKNOWN_ARTIST", comment: "")
        }
        return artist.name
    }
}
