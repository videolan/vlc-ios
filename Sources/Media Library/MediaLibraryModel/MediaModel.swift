/*****************************************************************************
 * MediaModel.swift
 *
 * Copyright © 2018-2026 VLC authors and VideoLAN
 * Copyright © 2018-2026 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#if !os(watchOS)
import CoreSpotlight
#endif

protocol MediaModel: NSObject, MLBaseModel where MLType == VLCMLMedia { }

extension MediaModel {
    func append(_ item: VLCMLMedia) {
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        if !files.contains(where: { $0 == item }) {
            files.append(item)
        }
    }

    func delete(_ items: [VLCMLMedia]) {
        for case let media in items {
            media.deleteMainFile()
        }
        medialibrary.reload()
        fileArrayLock.lock()
        defer { fileArrayLock.unlock() }
        filterFilesFromDeletion(of: items)
    }
}

// MARK: - ViewModel

extension VLCMLMedia {
    @objc func deleteMainFile() {
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

    @objc func resolutionClass() -> String? {
        guard let firstTrack = videoTracks?.first else {
            return nil
        }
        let shortSide = min(firstTrack.width(), firstTrack.height())
        let longSide = max(firstTrack.width(), firstTrack.height())

        if shortSide >= 4320 || longSide >= 7680 {
            return NSLocalizedString("RESOLUTION_CLASS_8K", comment: "")
        } else if shortSide >= 2160 || longSide >= 3840 {
            return NSLocalizedString("RESOLUTION_CLASS_4K", comment: "")
        } else if shortSide >= 1080 || longSide >= 1920 {
            return NSLocalizedString("RESOLUTION_CLASS_HD", comment: "")
        } else if shortSide >= 540 || longSide >= 960 {
            return NSLocalizedString("RESOLUTION_CLASS_SD", comment: "")
        }
        return nil
    }

    @objc func thumbnailImage() -> UIImage? {
        var image = VLCThumbnailsCache.thumbnail(for: thumbnail())
        if image == nil
            || (!UserDefaults.standard.bool(forKey: kVLCSettingShowThumbnails) && subtype() != .albumTrack)
            || (!UserDefaults.standard.bool(forKey: kVLCSettingShowArtworks) && subtype() == .albumTrack) {
            #if os(watchOS)
            /// watchOS only doesn't have light mode
            let isDarktheme = true
            #else
            let isDarktheme = PresentationTheme.current.isDark
            #endif
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
            && title.isSupportedMediaFormat() {
            return (title as NSString).deletingPathExtension
        }
        return title
    }
}

// MARK: - CoreSpotlight
extension VLCMLMedia {
#if !os(tvOS) && !os(watchOS)
    func coreSpotlightAttributeSet() -> CSSearchableItemAttributeSet {
        let contentType = type() == .video ? "public.movie" : "public.audio"
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: contentType)
        attributeSet.title = title
        attributeSet.metadataModificationDate = Date()
        attributeSet.addedDate = insertionDate()
        attributeSet.contentCreationDate = releaseDate()
        attributeSet.lastUsedDate = lastPlayedDate()
        attributeSet.duration = NSNumber(value: duration() / 1000)
        attributeSet.streamable = 0
        attributeSet.deliveryType = 0
        attributeSet.local = 1
        attributeSet.playCount = NSNumber(value: playCount())
        if thumbnailStatus() == .available {
            let image = VLCThumbnailsCache.minimizedThumbnail(for: thumbnail())
            attributeSet.thumbnailData = image?.jpegData(compressionQuality: 0.9)
        }
        attributeSet.codecs = codecs()
        attributeSet.languages = languages()
        if let file = mainFile() {
            attributeSet.path = file.mrl.path
            attributeSet.contentModificationDate = file.lastModificationDate
            attributeSet.fileSize = NSNumber(value: Double(file.size()) / (1024 * 1024))
        }
        if type() == .video, let video = videoTracks?.first {
            attributeSet.pixelWidth = NSNumber(value: video.width())
            attributeSet.pixelHeight = NSNumber(value: video.height())
            attributeSet.videoBitRate = NSNumber(value: video.bitrate())
        }
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
                attributeSet.musicalGenre = genre.name
            }
            if let artist = artist {
                attributeSet.artist = artist.name
                attributeSet.performers = [artist.name]
            }
            attributeSet.audioTrackNumber = NSNumber(value:trackNumber)
            if let album = album {
                attributeSet.album = album.title
            }
        }

        return attributeSet
    }

    func updateCoreSpotlightEntry() {
        if !KeychainCoordinator.passcodeService.hasSecret {
            let groupIdentifier = ProcessInfo.processInfo.environment["GROUP_IDENTIFIER"]
            let item = CSSearchableItem(uniqueIdentifier: "\(identifier())", domainIdentifier: groupIdentifier, attributeSet: coreSpotlightAttributeSet())
            CSSearchableIndex.default().indexSearchableItems([item], completionHandler: nil)
        }
    }
#endif

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
}

// MARK: - Search
extension VLCMLMedia: SearchableMLModel {
    @objc func contains(_ searchString: String) -> Bool {
        var matches = false

        matches = matches || search(searchString, in: title)

        if subtype() == .albumTrack {
            matches = matches || search(searchString, in: artist?.name ?? "")
            matches = matches || search(searchString, in: genre?.name ?? "")
            matches = matches || search(searchString, in: album?.title ?? "")
        }

        matches = matches || search(searchString, in: title)
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
