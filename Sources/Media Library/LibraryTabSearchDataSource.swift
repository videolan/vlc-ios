/*****************************************************************************
 * LibraryTabSearchDataSource.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

// MARK: - LibrarySearchScope

enum LibrarySearchScope {
    case video
    case audio
}

// MARK: - LibrarySearchSection

struct LibrarySearchSection {
    let title: String
    let items: [VLCMLObject]
}

// MARK: - LibraryTabSearchDataSourceDelegate

protocol LibraryTabSearchDataSourceDelegate: AnyObject {
    func libraryTabSearchDataSource(_ dataSource: LibraryTabSearchDataSource,
                                    didSelect item: VLCMLObject,
                                    in section: LibrarySearchSection)
    func libraryTabSearchDataSourceWillBeginDragging(_ dataSource: LibraryTabSearchDataSource)
}

// MARK: - LibraryTabSearchDataSource

class LibraryTabSearchDataSource: NSObject {
    // MARK: Properties

    let scope: LibrarySearchScope
    weak var delegate: LibraryTabSearchDataSourceDelegate?

    private(set) var sections = [LibrarySearchSection]()
    private(set) var searchString: String = ""

    var isEmpty: Bool {
        return sections.isEmpty
    }

    var hasSearchablePattern: Bool {
        return !LibraryTabSearchDataSource.pattern(from: searchString).isEmpty
    }

    private let mediaLibraryService: MediaLibraryService
    private let searchQueue = DispatchQueue(label: "org.videolan.vlc-ios.library-tab-search", qos: .userInitiated)
    private let searchGenerationLock = NSLock()
    private var searchGeneration: Int = 0
    private var cachedCellSize: CGSize = .zero
    private var cachedCellWidth: CGFloat = 0

    private let sectionHeaderHeight: CGFloat = 40.0

    private var medialib: VLCMediaLibrary {
        return mediaLibraryService.medialib
    }

    // MARK: Init

    init(scope: LibrarySearchScope, mediaLibraryService: MediaLibraryService) {
        self.scope = scope
        self.mediaLibraryService = mediaLibraryService
        super.init()
    }

    // MARK: Public methods

    func reset() {
        _ = nextSearchGeneration()
        searchString = ""
        sections = []
    }

    func search(for searchString: String, completion: @escaping () -> Void) {
        self.searchString = searchString
        let generation = nextSearchGeneration()

        guard hasSearchablePattern else {
            sections = []
            completion()
            return
        }

        let pattern = LibraryTabSearchDataSource.pattern(from: searchString)
        searchQueue.async { [weak self] in
            // A newer search was requested while this one was queued, skip the queries
            guard let self = self, self.isCurrentSearch(generation) else { return }

            let sections = self.searchSections(for: pattern).filter { !$0.items.isEmpty }

            DispatchQueue.main.async {
                guard self.isCurrentSearch(generation) else {
                    return
                }
                self.sections = sections
                completion()
            }
        }
    }
}

// MARK: - Search generation

private extension LibraryTabSearchDataSource {
    func nextSearchGeneration() -> Int {
        searchGenerationLock.lock()
        defer { searchGenerationLock.unlock() }
        searchGeneration += 1
        return searchGeneration
    }

    func isCurrentSearch(_ generation: Int) -> Bool {
        searchGenerationLock.lock()
        defer { searchGenerationLock.unlock() }
        return generation == searchGeneration
    }
}

// MARK: - Library content

private extension LibraryTabSearchDataSource {
    static func pattern(from searchString: String) -> String {
        return searchString.trimmingCharacters(in: .whitespaces)
    }

    static func isDisplayable(_ mediaGroup: VLCMLMediaGroup) -> Bool {
        return mediaGroup.nbVideo() > 0 && (mediaGroup.nbTotalMedia() > 1 || mediaGroup.userInteracted())
    }

    func searchSections(for pattern: String) -> [LibrarySearchSection] {
        switch scope {
        case .video:
            let videos = LibrarySearchSection(title: NSLocalizedString("VIDEOS", comment: ""),
                                              items: medialib.searchVideo(pattern, sort: .alpha, desc: false) ?? [])
            let mediaGroups = medialib.searchMediaGroups(withPattern: pattern, sort: .alpha, desc: false)?
                .filter { LibraryTabSearchDataSource.isDisplayable($0) } ?? []
            return [LibrarySearchSection(title: NSLocalizedString("VIDEO_GROUPS", comment: ""), items: mediaGroups),
                    videos]
        case .audio:
            let hideFeatArtists = UserDefaults.standard.bool(forKey: kVLCAudioLibraryHideFeatArtists)
            let artists = medialib.searchArtists(byName: pattern, all: !hideFeatArtists, sort: .alpha, desc: false)?
                .filter {
                    let isGeneratedArtist = $0.identifier() == UnknownArtistID || $0.identifier() == VariousArtistID
                    return !isGeneratedArtist || $0.tracksCount() > 0
                } ?? []

            return [
                LibrarySearchSection(title: NSLocalizedString("ARTISTS", comment: ""),
                                     items: artists),
                LibrarySearchSection(title: NSLocalizedString("ALBUMS", comment: ""),
                                     items: medialib.searchAlbums(byPattern: pattern, sort: .alpha, desc: false) ?? []),
                LibrarySearchSection(title: NSLocalizedString("SONGS", comment: ""),
                                     items: medialib.searchAudio(pattern, sort: .alpha, desc: false) ?? []),
                LibrarySearchSection(title: NSLocalizedString("GENRES", comment: ""),
                                     items: medialib.searchGenre(byName: pattern, sort: .alpha, desc: false) ?? [])
            ]
        }
    }
}

// MARK: - UICollectionViewDataSource

extension LibraryTabSearchDataSource: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections.objectAtIndex(index: section)?.items.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCollectionViewCell.defaultReuseIdentifier,
                                                            for: indexPath) as? MediaCollectionViewCell else {
            assertionFailure("LibraryTabSearchDataSource: MediaCollectionViewCell is not registered.")
            return UICollectionViewCell()
        }

        guard let section = sections.objectAtIndex(index: indexPath.section),
              let item = section.items.objectAtIndex(index: indexPath.row) else {
            return cell
        }

        if let mediaGroup = item as? VLCMLMediaGroup {
            mediaGroup.media(of: .video)?.prefix(4).forEach {
                mediaLibraryService.requestThumbnail(for: $0)
            }
        } else if let media = item as? VLCMLMedia, media.type() == .video {
            mediaLibraryService.requestThumbnail(for: media)
        }

        cell.isEditing = false
        cell.media = item
        cell.isAccessibilityElement = true
        cell.accessibilityIdentifier = VLCAccessibilityIdentifier.mediaCell
        cell.disableScrollView()

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                           withReuseIdentifier: TrackSectionHeader.headerID,
                                                                           for: indexPath) as? TrackSectionHeader else {
            return UICollectionReusableView()
        }

        header.update(sectionTitle: sections.objectAtIndex(index: indexPath.section)?.title ?? "")
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension LibraryTabSearchDataSource: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let section = sections.objectAtIndex(index: indexPath.section),
              let item = section.items.objectAtIndex(index: indexPath.row) else {
            return
        }

        delegate?.libraryTabSearchDataSource(self, didSelect: item, in: section)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.libraryTabSearchDataSourceWillBeginDragging(self)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.safeAreaLayoutGuide.layoutFrame.width
        if cachedCellSize == .zero || cachedCellWidth != width {
            let safeAreaInsets = collectionView.window?.safeAreaInsets ?? collectionView.safeAreaInsets
            cachedCellSize = MediaCollectionViewCell.cellSizeForWidth(width, safeAreaInsets: safeAreaInsets)
            cachedCellWidth = width
        }
        return cachedCellSize
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.safeAreaLayoutGuide.layoutFrame.width, height: sectionHeaderHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        let padding = MediaCollectionViewCell.edgePadding
        return UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return MediaCollectionViewCell.edgePadding
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return MediaCollectionViewCell.interItemPadding
    }
}
