/*****************************************************************************
 * MediaCategory.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

// MARK: - MovieCategoryViewController

class MovieCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = MediaGroupViewModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

// MARK: - ShowEpisodeCategoryViewController

class ShowEpisodeCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = ShowEpisodeModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

// MARK: - PlaylistCategoryViewController

class PlaylistCategoryViewController: MediaCategoryViewController {
    private lazy var createPlaylistButton: UIBarButtonItem = {
        let createPlaylistButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(handleCreatePlaylist))
        return createPlaylistButton
    }()

    private let playlistModel: PlaylistModel

    init(_ mediaLibraryService: MediaLibraryService) {
        let model = PlaylistModel(medialibrary: mediaLibraryService)
        playlistModel = model
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }

    func getCreatePlaylistButton() -> UIBarButtonItem {
        return createPlaylistButton
    }

    @objc func handleCreatePlaylist() {
        let addToCollectionViewController = AddToCollectionViewController()
        addToCollectionViewController.delegate = self
        addToCollectionViewController.mlCollection = playlistModel.medialibrary.playlists()
        addToCollectionViewController.updateInterface(for: VLCMLPlaylist.self, isOnlyCreation: true)
        let createPlaylistNavigationController = UINavigationController(rootViewController: addToCollectionViewController)
        present(createPlaylistNavigationController, animated: true)
    }
}

// MARK: AddToCollectionViewControllerDelegate

extension PlaylistCategoryViewController: AddToCollectionViewControllerDelegate {
    func addToCollectionViewController(_ addToCollectionViewController: AddToCollectionViewController,
                                       didSelectCollection collection: MediaCollectionModel) {
        addToCollectionViewController.dismiss(animated: true)
    }

    func addToCollectionViewController(_ addToCollectionViewController: AddToCollectionViewController,
                                       newCollectionName name: String,
                                       from mlType: MediaCollectionModel.Type) {
        guard playlistModel.medialibrary.createPlaylist(with: name) != nil else {
            assertionFailure("PlaylistCategoryViewController: Failed to create a playlist.")
            VLCAlertViewController.alertViewManager(title: NSLocalizedString("ERROR_PLAYLIST_CREATION", comment: ""),
                                                    viewController: addToCollectionViewController)
            return
        }
        addToCollectionViewController.dismiss(animated: true)
    }

    func addToCollectionViewControllerMoveCollections(_ addToCollectionViewController: AddToCollectionViewController) {
        addToCollectionViewController.dismiss(animated: true)
    }
}

// MARK: - TrackCategoryViewController

class TrackCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = TrackModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        self.isSectionable = true
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionHeadersPinToVisibleBounds = true
        }
        model.observable.addObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        UserDefaults.standard.set(2, forKey: kVLCAudioTabIndex)
        super.viewWillAppear(animated)
    }
}

// MARK: - GenreCategoryViewController

class GenreCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = GenreModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        UserDefaults.standard.set(3, forKey: kVLCAudioTabIndex)
        super.viewWillAppear(animated)
    }
}

// MARK: - ArtistCategoryViewController

class ArtistCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = ArtistModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        UserDefaults.standard.set(0, forKey: kVLCAudioTabIndex)
        super.viewWillAppear(animated)
    }
}

// MARK: - FolderViewController

class FolderViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService, isAudio: Bool, folder: VLCMLFolder?) {
        let model = FolderModel(medialibrary: mediaLibraryService, isAudio: isAudio, folder: folder)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        UserDefaults.standard.set(4, forKey: kVLCAudioTabIndex)
        super.viewWillAppear(animated)
    }
}

// MARK: - AlbumCategoryViewController

class AlbumCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService) {
        let model = AlbumModel(medialibrary: mediaLibraryService)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        UserDefaults.standard.set(1, forKey: kVLCAudioTabIndex)
        super.viewWillAppear(animated)
    }
}

// MARK: - ArtistAlbumCategoryViewController

class ArtistAlbumCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService, mediaCollection: VLCMLArtist) {
        let model = AlbumModel(medialibrary: mediaLibraryService, artist: mediaCollection)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

// MARK: - HistoryCategoryViewController

class HistoryCategoryViewController: MediaCategoryViewController {
    init(_ mediaLibraryService: MediaLibraryService, mediaType: VLCMLMediaType) {
        let model = HistoryModel(medialibrary: mediaLibraryService, mediaType: mediaType)
        super.init(mediaLibraryService: mediaLibraryService, model: model)
        model.observable.addObserver(self)
    }
}

// MARK: - CollectionCategoryViewController

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
            let sortModel = model.sortModel
            let tracks = collection.tracks(with: sortModel.currentSort, desc: sortModel.desc)
            playbackService.playCollection(tracks)
        }
    }
}
