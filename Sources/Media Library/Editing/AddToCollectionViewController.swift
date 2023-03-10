/*****************************************************************************
 * AddToCollectionViewController.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *          Andrew Breckenridge <asbreckenridge # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import UIKit

protocol AddToCollectionViewControllerDelegate: AnyObject {
    func addToCollectionViewController(_ addToCollectionViewController: AddToCollectionViewController,
                                       didSelectCollection collection: MediaCollectionModel)
    func addToCollectionViewController(_ addToPlaylistViewController: AddToCollectionViewController,
                                       newCollectionName name: String,
                                       from mlType: MediaCollectionModel.Type)
    func addToCollectionViewControllerMoveCollections(_
        addToCollectionViewController: AddToCollectionViewController)
}

enum AddToCollectionSection: Int, CaseIterable {
    case moveToRoot = 0
    case collection
}

class AddToCollectionViewController: UIViewController {
    @IBOutlet private weak var newCollectionButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!

    private let sidePadding: CGFloat = 10
    private var collectionModelType: MediaCollectionModel.Type?

    var mlCollection = [MediaCollectionModel]()

    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumLineSpacing = 10
        collectionViewLayout.minimumInteritemSpacing = 0
        return collectionViewLayout
    }()

    weak var delegate: AddToCollectionViewControllerDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        navigationController?.navigationBar.isTranslucent = false
        collectionView.reloadData()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initViews()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification,
                                               object: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    override func viewSafeAreaInsetsDidChange() {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
     override func viewDidLayoutSubviews() {
          super.viewDidLayoutSubviews()
          collectionView.collectionViewLayout.invalidateLayout()
    }

    @objc private func themeDidChange() {
        view.backgroundColor = PresentationTheme.current.colors.background
        collectionView.backgroundColor = PresentationTheme.current.colors.background
        setNeedsStatusBarAppearanceUpdate()
    }

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }

    func updateInterface(for collectionModelType: MediaCollectionModel.Type) {
        if collectionModelType is VLCMLPlaylist.Type {
            title = NSLocalizedString("ADD_TO_PLAYLIST", comment: "")
        } else {
            title = NSLocalizedString("ADD_TO_MEDIA_GROUP", comment: "")
        }
        self.collectionModelType = collectionModelType
        setupNewCollectionButton(for: collectionModelType)
    }

    // MARK: - Create new Actions

    @IBAction private func handleMoveCollection() {
        delegate?.addToCollectionViewControllerMoveCollections(self)
    }

    @IBAction private func handleNewCollection(_ sender: UIButton) {
        guard let collectionModelType = collectionModelType else {
            assertionFailure("AddToCollectionViewController: handleNewCollection: Failed to retrieve type")
            return
        }

        var title: String
        var description: String
        var placeholder: String

        if collectionModelType is VLCMLPlaylist.Type {
            title = NSLocalizedString("PLAYLISTS", comment: "")
            description = NSLocalizedString("PLAYLIST_DESCRIPTION", comment: "")
            placeholder = NSLocalizedString("PLAYLIST_PLACEHOLDER", comment: "")
        } else {
            title = NSLocalizedString("MEDIA_GROUPS", comment: "")
            description = NSLocalizedString("MEDIA_GROUPS_DESCRIPTION", comment: "")
            placeholder = NSLocalizedString("MEDIA_GROUPS_PLACEHOLDER", comment: "")
        }

        let alertController = UIAlertController(title: title,
                                                message: description,
                                                preferredStyle: .alert)

        alertController.addTextField(configurationHandler: {
            textField in
            textField.placeholder = placeholder
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
            self.delegate?.addToCollectionViewController(self,
                                                         newCollectionName: text,
                                                         from: collectionModelType)
        }
        alertController.addAction(cancelButton)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Private initializers

private extension AddToCollectionViewController {
    private func initViews() {
        Bundle.main.loadNibNamed("AddToCollectionView", owner: self, options: nil)
        view.backgroundColor = PresentationTheme.current.colors.background
        setupNavigationBar()
        setupCollectionView()
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("BUTTON_CANCEL",
                                                                                    comment: ""),
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(dismissView))
    }

    private func setupNewCollectionButton(for type: MediaCollectionModel.Type) {
        newCollectionButton.layer.masksToBounds = true
        newCollectionButton.layer.cornerRadius = 10
        newCollectionButton.backgroundColor = PresentationTheme.current.colors.orangeUI

        var title: String
        var hint: String

        if type is VLCMLPlaylist.Type {
            title = NSLocalizedString("PLAYLIST_CREATION", comment: "")
            hint = NSLocalizedString("PLAYLIST_CREATION_HINT", comment: "")
        } else {
            title = NSLocalizedString("MEDIA_GROUP_CREATION", comment: "")
            hint = NSLocalizedString("MEDIA_GROUP_CREATION_HINT", comment: "")
        }

        newCollectionButton.setTitle(title, for: .normal)
        newCollectionButton.titleLabel?.font = UIFont.preferredCustomFont(forTextStyle: .headline)
        newCollectionButton.accessibilityLabel = title
        newCollectionButton.accessibilityHint = hint
    }

    private func setupCollectionView() {
        let cellNib = UINib(nibName: MediaCollectionViewCell.nibName, bundle: nil)
        collectionView.register(cellNib,
                                        forCellWithReuseIdentifier: MediaCollectionViewCell.defaultReuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = collectionViewLayout
        collectionView.backgroundColor = PresentationTheme.current.colors.background
    }
}

// MARK: - UICollectionViewFlowLayout

extension AddToCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return MediaCollectionViewCell.cellSizeForWidth(collectionView.bounds.size.width)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: sidePadding, bottom: 0, right: sidePadding)
    }
}

// MARK: - UICollectionViewDelegate

extension AddToCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if  collectionModelType is VLCMLMediaGroup.Type
            && indexPath.section == AddToCollectionSection.moveToRoot.rawValue {
            delegate?.addToCollectionViewControllerMoveCollections(self)
            return
        }

        guard indexPath.row <= mlCollection.count else {
            assertionFailure("AddToPlaylistViewController: didSelectItemAt: IndexPath out of range.")
            return
        }
        delegate?.addToCollectionViewController(self, didSelectCollection: mlCollection[indexPath.row])
    }
}

// MARK: - UICollectionViewDataSource

extension AddToCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // Do not add the moveToRoot action for playlists
        if collectionModelType is VLCMLPlaylist.Type {
            return 1
        }
        return AddToCollectionSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        // No moveToRoot action for playlists
        if collectionModelType is VLCMLPlaylist.Type {
            return mlCollection.count
        }

        if section == AddToCollectionSection.moveToRoot.rawValue {
            return 1
        } else {
            return mlCollection.count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCollectionViewCell.defaultReuseIdentifier,
                                                            for: indexPath) as? MediaCollectionViewCell else {
            return UICollectionViewCell()
        }
        if collectionModelType is VLCMLMediaGroup.Type
            && indexPath.section == AddToCollectionSection.moveToRoot.rawValue {
            cell.thumbnailView.image = UIImage(named: "removeFromMediaGroup")
            cell.thumbnailView.contentMode = .center
            cell.titleLabel.text = NSLocalizedString("MEDIA_GROUP_MOVE_TO_ROOT", comment: "")
            cell.accessibilityLabel = NSLocalizedString("MEDIA_GROUP_MOVE_TO_ROOT_HINT", comment: "")
            cell.newLabel.isHidden = true
            return cell
        }

        guard indexPath.row <= mlCollection.count else {
            assertionFailure("AddToPlaylistViewController: cellForItemAt: IndexPath out of range.")
            return UICollectionViewCell()
        }
        cell.media = mlCollection[indexPath.row] as? VLCMLObject
        cell.disableScrollView()
        return cell
    }
}
