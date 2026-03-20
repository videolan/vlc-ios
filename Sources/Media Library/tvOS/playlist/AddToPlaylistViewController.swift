//
//  AddToPlaylistViewController.swift
//  VLC-tvOS
//
//  Created by Eshan Singh on 20/08/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

import UIKit

class AddToPlaylistViewController: UIViewController {

    var playlistCollectionView: UICollectionView!
    var createPlaylistButton: UIButton!
    var titleLabel: UILabel!

    let playlistModel: PlaylistModel
    let medialib: MediaLibraryService

    @objc var mediaToAdd = [VLCMLMedia]()

    init() {
        let appCoordinator = VLCAppCoordinator.sharedInstance()
        medialib = appCoordinator.mediaLibraryService
        playlistModel = PlaylistModel(medialibrary: medialib)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTitleLabel()
        setupCreateButton()
        setupCollectionView()
        setupFocusGuide()
    }

    // MARK: - Layout

    private func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("ADD_TO_PLAYLIST", comment: "")
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        titleLabel.textColor = PresentationTheme.current.colors.cellTextColor
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setupCreateButton() {
        createPlaylistButton = UIButton(type: .system)
        createPlaylistButton.setTitle(NSLocalizedString("PLAYLIST_CREATION", comment: ""), for: .normal)
        createPlaylistButton.addTarget(self, action: #selector(createNewPlaylist(_:)), for: .primaryActionTriggered)
        createPlaylistButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createPlaylistButton)

        NSLayoutConstraint.activate([
            createPlaylistButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            createPlaylistButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
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
        playlistCollectionView.remembersLastFocusedIndexPath = true
        playlistCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playlistCollectionView)

        NSLayoutConstraint.activate([
            playlistCollectionView.topAnchor.constraint(equalTo: createPlaylistButton.bottomAnchor, constant: 20),
            playlistCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            playlistCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            playlistCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }

    private func setupFocusGuide() {
        let focusGuide = UIFocusGuide()
        view.addLayoutGuide(focusGuide)

        NSLayoutConstraint.activate([
            focusGuide.topAnchor.constraint(equalTo: createPlaylistButton.bottomAnchor),
            focusGuide.bottomAnchor.constraint(equalTo: playlistCollectionView.topAnchor),
            focusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            focusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        focusGuide.preferredFocusEnvironments = [playlistCollectionView!]
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        // Dynamically redirect: from collection view -> button, from button -> collection view
        if let guide = view.layoutGuides.first(where: { $0 is UIFocusGuide }) as? UIFocusGuide {
            if context.nextFocusedView === createPlaylistButton {
                guide.preferredFocusEnvironments = [playlistCollectionView!]
            } else {
                guide.preferredFocusEnvironments = [createPlaylistButton!]
            }
        }
    }

    // MARK: - Actions

    @objc func createNewPlaylist(_ sender: UIButton) {
        let playlistAlert = UIAlertController(title: NSLocalizedString("PLAYLIST_CREATION", comment: ""),
                                              message: NSLocalizedString("PLAYLIST_DESCRIPTION", comment: ""),
                                              preferredStyle: .alert)

        playlistAlert.addTextField { textField in
            textField.placeholder = NSLocalizedString("PLAYLIST_PLACEHOLDER", comment: "")
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel, handler: nil)
        playlistAlert.addAction(cancelAction)

        let confirmAction = UIAlertAction(title: NSLocalizedString("BUTTON_DONE", comment: ""), style: .default) { [self] _ in
            if let textField = playlistAlert.textFields?.first,
               let name = textField.text,
               !name.isEmpty {
                if let playlist = medialib.createPlaylist(with: name) {
                    for media in mediaToAdd {
                        playlist.appendMedia(media)
                    }
                    dismiss(animated: true)
                }
            }
        }
        playlistAlert.addAction(confirmAction)

        present(playlistAlert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension AddToPlaylistViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playlistModel.files.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCMovieTVCollectionViewCellIdentifier, for: indexPath) as! VLCMovieTVCollectionViewCell
        let playlist = playlistModel.files[indexPath.row]
        cell.titleLabel.text = playlist.title()
        cell.descriptionLabel.text = playlist.numberOfTracksString() + " · " + playlist.durationString()
        cell.thumbnailView.image = playlist.thumbnailImage()
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension AddToPlaylistViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let playlist = playlistModel.files[indexPath.row]
        for media in mediaToAdd {
            playlist.appendMedia(media)
        }
        dismiss(animated: true)
    }
}
