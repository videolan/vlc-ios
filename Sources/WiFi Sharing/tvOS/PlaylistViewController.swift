//
//  PlaylistViewController.swift
//  VLC-tvOS
//
//  Created by Eshan Singh on 07/08/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

import UIKit

class PlaylistViewController: VLCDeletionCapableViewController {

    @IBOutlet weak var playlistView: UITableView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var VLCcone: UIImageView!

    var medialibraryService: MediaLibraryService
    var playlistModel: PlaylistModel
    var medialibObservor: tvOSModelObserver?
    var currentlyFocusedIndexPath: IndexPath?
    var sortingHandler: SortingHandler

    // Searching Properties
    var didBeginSearching = false
    var searchedPlaylists = [VLCMLPlaylist]()

    override func viewDidLoad() {
        playlistView.dataSource = self
        playlistView.delegate = self
        playlistView.register(UINib(nibName: "PlaylistTableViewCell", bundle: nil), forCellReuseIdentifier: "playlistCell")
        medialibObservor = tvOSModelObserver(observerDelegate: self, playlistModel: playlistModel)
        searchBar.delegate = self
        medialibObservor?.observeLibrary()
        super.viewDidLoad()
    }

    init() {
        let appcoordinator = VLCAppCoordinator.sharedInstance()
        medialibraryService = appcoordinator.mediaLibraryService
        playlistModel = PlaylistModel(medialibrary: medialibraryService)
        sortingHandler = SortingHandler(playlistModel: playlistModel)

        super.init(nibName: nil, bundle: nil)
        self.title = playlistModel.indicatorName
    }

    @IBAction func sortPlaylist(_ sender: UIButton) {
        sortingHandler.constructSortAlert(playlistView:self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
// MARK: - UITableViewDataSource

extension PlaylistViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = didBeginSearching ? searchedPlaylists.count : playlistModel.files.count

        self.VLCcone.isHidden = (count >= 1) ? true : false
        self.searchBar.isHidden = (count >= 1) ? false : true
        self.sortButton.isHidden = (count >= 1) ? false : true

        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:"playlistCell") as! PlaylistTableViewCell
        if didBeginSearching {
            cell.playlist = searchedPlaylists[indexPath.row]
        } else {
            cell.playlist = playlistModel.files[indexPath.row]
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension PlaylistViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playlistMediaViewController = PlaylistMediaViewController()
        let cell = tableView.cellForRow(at: indexPath) as! PlaylistTableViewCell
        playlistMediaViewController.playlist = cell.playlist!
        present(playlistMediaViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool {
        if self.isEditing {
            return context.nextFocusedIndexPath == nil
        }
        return true
    }

    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let nextPath = context.nextFocusedIndexPath {
            self.isEditing = false
            self.currentlyFocusedIndexPath = nextPath
        }
    }
    // MARK: - editing

    override var indexPathToDelete: IndexPath? {
        return self.currentlyFocusedIndexPath
    }

    override var itemToDelete: String? {
        if let indexPathToDelete = self.indexPathToDelete {
            let row = indexPathToDelete.row
            let playlistTodelete = didBeginSearching ? searchedPlaylists[row] : playlistModel.files[row]
            return playlistTodelete.name
        }
        return ""
    }

    override func deleteFile(atIndex indexPathToDelete: IndexPath?) {
        super.deleteFile(atIndex: indexPathToDelete)

        guard let indexPathToDelete = indexPathToDelete else {
            return
        }

        playlistView.performBatchUpdates({
            let row = indexPathToDelete.row
            let playlistToDelete = didBeginSearching ? searchedPlaylists[row] : playlistModel.files[row]
            searchedPlaylists.remove(at: row)
            playlistModel.delete([playlistToDelete])
            didBeginSearching = false
            self.searchBar.text = ""
            self.playlistView.reloadData()
        }) { finished in
            self.isEditing = false
        }
    }

    override func renameFile(atIndex indexPathToRename: IndexPath?) {
        super.renameFile(atIndex: indexPathToRename)

        let mediatoRename = didBeginSearching ? searchedPlaylists[indexPathToRename!.row] : playlistModel.files[indexPathToRename!.row]

        let currentTitle = mediatoRename.name

        let alertTitle = "Rename \(currentTitle) to:"
        let renameAlert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)

        renameAlert.addTextField { textField in
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
            if let textField = renameAlert.textFields?.first,
               let newName = textField.text,
               !newName.isEmpty {
                mediatoRename.updateName(newName)
                Thread.sleep(forTimeInterval: 2)
                self.didBeginSearching = !self.didBeginSearching
                self.playlistView.reloadData()
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
               let focusedCell = playlistView.cellForRow(at: indexPath) {
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
            self.playlistView.reloadData()
        }
    }
}

// MARK: - UITextFieldDelegate

extension PlaylistViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        let stringToSearch = textField.text
        searchedPlaylists.removeAll() // Clear the previous search results
        sortButton.isHidden = true

        if textField.text!.isEmpty {
            didBeginSearching = false
            sortButton.isHidden = false
            self.playlistView.reloadData()
            return
        }

        didBeginSearching = true

        for playlist in playlistModel.files {
            let exists = playlist.contains(stringToSearch!)
            if exists {
                searchedPlaylists.append(playlist)
            }
        }

        self.playlistView.reloadData()
    }
}
