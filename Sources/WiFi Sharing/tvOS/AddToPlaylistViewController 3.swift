//
//  AddToPlaylistViewController.swift
//  VLC-tvOS
//
//  Created by Eshan Singh on 20/08/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

import Foundation

class AddToPlaylistViewController: UIViewController {
    
    @IBOutlet weak var playlistTableView: UITableView!
    @IBOutlet weak var createPlaylistButton: UIButton!
    
    let playlistModel: PlaylistModel
    let medialib: MediaLibraryService
    
    @objc var mediaToAdd = [VLCMLMedia]()
    
    init() {
        let appCoordinator = VLCAppCoordinator.sharedInstance()
        medialib = appCoordinator.mediaLibraryService
        self.playlistModel = PlaylistModel(medialibrary: medialib)
        super.init(nibName: nil, bundle: nil)
    
    }
    
    override func viewDidLoad() {
        playlistTableView.dataSource = self
        playlistTableView.delegate = self
        playlistTableView.register(UINib(nibName: "PlaylistTableViewCell", bundle: nil), forCellReuseIdentifier: "playlistCell")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func createNewPlaylist(_ sender: UIButton) {
        let playlistAlert = UIAlertController(title: "Create Playlist", message: nil, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        playlistAlert.addAction(cancelAction)

        var playlistName: String?

        playlistAlert.addTextField { textField in
        }

        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [self] action in
            if let textField = playlistAlert.textFields?.first, let name = textField.text, !name.isEmpty {
                playlistName = name
                if let playlist = self.medialib.createPlaylist(with: playlistName!) {
                    for media in mediaToAdd {
                        playlist.appendMedia(media)
                    }
                    self.dismiss(animated: true)
                }
            }
        }

        playlistAlert.addAction(confirmAction)

        present(playlistAlert, animated: true, completion: nil)

    }
}
// MARK: - UITableViewDataSource

extension AddToPlaylistViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistModel.files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:"playlistCell") as! PlaylistTableViewCell
        cell.playlist = playlistModel.files[indexPath.row]
        return cell
    }
    
}
// MARK: - UITableViewDelegate

extension AddToPlaylistViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for media in mediaToAdd {
            playlistModel.files[indexPath.row].appendMedia(media)
        }
        self.dismiss(animated: true)
    }
}
