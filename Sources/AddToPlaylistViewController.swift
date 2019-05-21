/*****************************************************************************
 * AddToPlaylistViewController.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

protocol AddToPlaylistViewControllerDelegate: class {
    func addToPlaylistViewController(_ addToPlaylistViewController: AddToPlaylistViewController,
                                     didSelectPlaylist playlist: VLCMLPlaylist)
    func addToPlaylistViewController(_ addToPlaylistViewController: AddToPlaylistViewController,
                                     newPlaylistWithName name: String)
}

class AddToPlaylistViewController: UIViewController {
    @IBOutlet private weak var newPlaylistButton: UIButton!
    @IBOutlet private weak var playlistCollectionView: UICollectionView!

    private let cellHeight: CGFloat = 56
    private let sidePadding: CGFloat = 20

    var playlists: [VLCMLPlaylist]

    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumLineSpacing = 10
        collectionViewLayout.minimumInteritemSpacing = 0
        return collectionViewLayout
    }()

    weak var delegate: AddToPlaylistViewControllerDelegate?

    init(playlists: [VLCMLPlaylist]) {
        self.playlists = playlists
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        navigationController?.navigationBar.isTranslucent = false
        playlistCollectionView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification,
                                               object: nil)
        title = NSLocalizedString("ADD_TO_PLAYLIST", comment: "")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    @objc private func themeDidChange() {
        view.backgroundColor = PresentationTheme.current.colors.background
        playlistCollectionView.backgroundColor = PresentationTheme.current.colors.background
        setNeedsStatusBarAppearanceUpdate()
    }

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func handleNewPlaylist(_ sender: UIButton) {
        let alertController = UIAlertController(title: NSLocalizedString("PLAYLISTS", comment: ""),
                                                message: NSLocalizedString("PLAYLIST_DESCRIPTION", comment: ""),
                                                preferredStyle: .alert)

        alertController.addTextField(configurationHandler: {
            textField in
            textField.placeholder = NSLocalizedString("PLAYLIST_PLACEHOLDER", comment: "")
        })

        let cancelButton = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                         style: .default)

        let confirmAction = UIAlertAction(title: NSLocalizedString("BUTTON_DONE", comment: ""),
                                          style: .default) {
            [weak alertController] _ in
            guard let alertController = alertController,
                let textField = alertController.textFields?.first else { return }

            guard let text = textField.text, text != "" else {
                DispatchQueue.main.async {
                    VLCAlertViewController.alertViewManager(title: NSLocalizedString("ERROR_EMPTY_NAME",
                                                                                     comment: ""),
                                                            viewController: self)
                }
                return
            }
            self.delegate?.addToPlaylistViewController(self, newPlaylistWithName: text)
        }
        alertController.addAction(cancelButton)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Private initializers

private extension AddToPlaylistViewController {
    private func initViews() {
        Bundle.main.loadNibNamed("AddToPlaylistView", owner: self, options: nil)
        view.backgroundColor = PresentationTheme.current.colors.background
        setupNavigationBar()
        setupNewPlaylistButton()
        setupPlaylistCollectionView()
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("BUTTON_CANCEL",
                                                                                    comment: ""),
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(dismissView))
    }

    private func setupNewPlaylistButton() {
        newPlaylistButton.layer.masksToBounds = true
        newPlaylistButton.layer.cornerRadius = 10
        newPlaylistButton.backgroundColor = PresentationTheme.current.colors.orangeUI
        newPlaylistButton.setTitle(NSLocalizedString("PLAYLIST_CREATION", comment: ""), for: .normal)
        newPlaylistButton.accessibilityLabel = NSLocalizedString("PLAYLIST_CREATION", comment: "")
        newPlaylistButton.accessibilityHint = NSLocalizedString("PLAYLIST_CREATION_HINT", comment: "")
    }

    private func setupPlaylistCollectionView() {
        let cellNib = UINib(nibName: MediaCollectionViewCell.nibName, bundle: nil)
        playlistCollectionView.register(cellNib,
                                        forCellWithReuseIdentifier: MediaCollectionViewCell.defaultReuseIdentifier)
        playlistCollectionView.delegate = self
        playlistCollectionView.dataSource = self
        playlistCollectionView.collectionViewLayout = collectionViewLayout
        playlistCollectionView.backgroundColor = PresentationTheme.current.colors.background
    }
}

// MARK: - UICollectionViewFlowLayout

extension AddToPlaylistViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - (sidePadding * 2), height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: sidePadding, bottom: 0, right: sidePadding)
    }
}

// MARK: - UICollectionViewDelegate

extension AddToPlaylistViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row <= playlists.count else {
            assertionFailure("AddToPlaylistViewController: didSelectItemAt: IndexPath out of range.")
            return
        }
        delegate?.addToPlaylistViewController(self, didSelectPlaylist: playlists[indexPath.row])
    }
}

// MARK: - UICollectionViewDataSource

extension AddToPlaylistViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return playlists.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCollectionViewCell.defaultReuseIdentifier,
                                                            for: indexPath) as? MediaCollectionViewCell else {
            return UICollectionViewCell()
        }
        guard indexPath.row <= playlists.count else {
            assertionFailure("AddToPlaylistViewController: cellForItemAt: IndexPath out of range.")
            return UICollectionViewCell()
        }
        cell.media = playlists[indexPath.row]
        return cell
    }
}
