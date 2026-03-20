//
//  PlaylistViewController.swift
//  VLC-tvOS
//
//  Created by Eshan Singh on 07/08/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

import UIKit

class PlaylistViewController: VLCDeletionCapableViewController {

    var playlistCollectionView: UICollectionView!
    var searchBar: UITextField!
    var sortButton: UIButton!
    var VLCcone: UIImageView!

    var medialibraryService: MediaLibraryService
    var playlistModel: PlaylistModel
    var medialibObservor: tvOSModelObserver?
    var currentlyFocusedIndexPath: IndexPath?
    var sortingHandler: SortingHandler

    // Searching Properties
    var didBeginSearching = false
    var searchedPlaylists = [VLCMLPlaylist]()

    init() {
        let appcoordinator = VLCAppCoordinator.sharedInstance()
        medialibraryService = appcoordinator.mediaLibraryService
        playlistModel = PlaylistModel(medialibrary: medialibraryService)
        sortingHandler = SortingHandler(playlistModel: playlistModel)

        super.init(nibName: nil, bundle: nil)
        self.title = playlistModel.indicatorName
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSearchBar()
        setupSortButton()
        setupCollectionView()
        setupEmptyStateView()

        medialibObservor = tvOSModelObserver(observerDelegate: self, playlistModel: playlistModel)
        medialibObservor?.observeLibrary()
    }

    // MARK: - Layout

    private func setupSearchBar() {
        searchBar = UITextField()
        searchBar.placeholder = NSLocalizedString("SEARCH", comment: "")
        searchBar.borderStyle = .roundedRect
        searchBar.textAlignment = .center
        searchBar.font = UIFont.preferredFont(forTextStyle: .headline)
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            searchBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchBar.widthAnchor.constraint(equalToConstant: 654),
            searchBar.heightAnchor.constraint(equalToConstant: 70),
        ])
    }

    private func setupSortButton() {
        sortButton = UIButton(type: .system)
        sortButton.setImage(UIImage(named: "sort"), for: .normal)
        sortButton.addTarget(self, action: #selector(sortPlaylist(_:)), for: .primaryActionTriggered)
        sortButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sortButton)

        NSLayoutConstraint.activate([
            sortButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            sortButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            sortButton.heightAnchor.constraint(equalToConstant: 70),
        ])
    }

    private func setupCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        let inset: CGFloat = 50.0
        flowLayout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        flowLayout.itemSize = VLCMovieTVCollectionViewCell.cellSize()
        flowLayout.minimumInteritemSpacing = 48.0
        flowLayout.minimumLineSpacing = 80.0

        playlistCollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        playlistCollectionView.dataSource = self
        playlistCollectionView.delegate = self
        playlistCollectionView.register(VLCMovieTVCollectionViewCell.self,
                                        forCellWithReuseIdentifier: VLCMovieTVCollectionViewCellIdentifier)
        playlistCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playlistCollectionView)

        NSLayoutConstraint.activate([
            playlistCollectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 30),
            playlistCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            playlistCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            playlistCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }

    private func setupEmptyStateView() {
        VLCcone = UIImageView(image: UIImage(named: "cone"))
        VLCcone.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(VLCcone)

        NSLayoutConstraint.activate([
            VLCcone.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            VLCcone.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc func sortPlaylist(_ sender: UIButton) {
        sortingHandler.constructSortAlert(playlistView: self)
    }

    private func playlist(at index: Int) -> VLCMLPlaylist {
        return didBeginSearching ? searchedPlaylists[index] : playlistModel.files[index]
    }
}

// MARK: - UICollectionViewDataSource

extension PlaylistViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = didBeginSearching ? searchedPlaylists.count : playlistModel.files.count

        VLCcone.isHidden = count >= 1
        searchBar.isHidden = count < 1
        sortButton.isHidden = count < 1

        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCMovieTVCollectionViewCellIdentifier, for: indexPath) as! VLCMovieTVCollectionViewCell
        let playlist = playlist(at: indexPath.row)
        cell.titleLabel.text = playlist.title()
        cell.descriptionLabel.text = playlist.numberOfTracksString() + " · " + playlist.durationString()
        cell.thumbnailView.image = playlist.thumbnailImage()
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension PlaylistViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let playlistMediaViewController = PlaylistMediaViewController()
        playlistMediaViewController.playlist = playlist(at: indexPath.row)
        present(playlistMediaViewController, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        if isEditing {
            return context.nextFocusedIndexPath == nil
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let nextPath = context.nextFocusedIndexPath {
            isEditing = false
            currentlyFocusedIndexPath = nextPath
        }
    }
}

// MARK: - Editing

extension PlaylistViewController {

    override var indexPathToDelete: IndexPath? {
        return currentlyFocusedIndexPath
    }

    override var itemToDelete: String? {
        guard let indexPath = indexPathToDelete else { return "" }
        return playlist(at: indexPath.row).name
    }

    override func deleteFile(atIndex indexPathToDelete: IndexPath?) {
        super.deleteFile(atIndex: indexPathToDelete)

        guard let indexPathToDelete = indexPathToDelete else { return }

        let row = indexPathToDelete.row
        let playlistToDelete = playlist(at: row)
        if didBeginSearching {
            searchedPlaylists.remove(at: row)
        }
        playlistModel.delete([playlistToDelete])
        didBeginSearching = false
        searchBar.text = ""
        isEditing = false
        playlistCollectionView.reloadData()
    }

    override func renameFile(atIndex indexPathToRename: IndexPath?) {
        super.renameFile(atIndex: indexPathToRename)

        guard let indexPathToRename = indexPathToRename else { return }

        let mediaToRename = playlist(at: indexPathToRename.row)
        let currentTitle = mediaToRename.name

        let alertTitle = "Rename \(currentTitle) to:"
        let renameAlert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)

        renameAlert.addTextField { _ in }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
            if let textField = renameAlert.textFields?.first,
               let newName = textField.text,
               !newName.isEmpty {
                mediaToRename.updateName(newName)
                self.playlistCollectionView.reloadData()
            }
        }

        renameAlert.addAction(confirmAction)
        renameAlert.addAction(cancelAction)

        present(renameAlert, animated: true, completion: nil)
    }

    override var isEditing: Bool {
        didSet {
            super.isEditing = isEditing

            if let indexPath = currentlyFocusedIndexPath,
               let focusedCell = playlistCollectionView.cellForItem(at: indexPath) {
                if isEditing {
                    focusedCell.layer.add(CAAnimation.vlc_wiggleAnimationwithSoftMode(true), forKey: VLCWiggleAnimationKey)
                } else {
                    focusedCell.layer.removeAnimation(forKey: VLCWiggleAnimationKey)
                }
            }
        }
    }
}

// MARK: - MediaLibraryDelegate

extension PlaylistViewController: MediaLibraryDelegate {
    func refreshCollection() {
        DispatchQueue.main.async {
            self.playlistCollectionView.reloadData()
        }
    }
}

// MARK: - UITextFieldDelegate

extension PlaylistViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        searchedPlaylists.removeAll()
        sortButton.isHidden = true

        if textField.text?.isEmpty ?? true {
            didBeginSearching = false
            sortButton.isHidden = false
            playlistCollectionView.reloadData()
            return
        }

        didBeginSearching = true

        for playlist in playlistModel.files {
            if playlist.contains(textField.text!) {
                searchedPlaylists.append(playlist)
            }
        }

        playlistCollectionView.reloadData()
    }
}
