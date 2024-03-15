/*****************************************************************************
 * VLCFavoriteListViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Eshan Singh <eeeshan789@icloud.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class VLCFavoriteListViewController: VLCRemoteBrowsingCollectionViewController {
    
    let favoriteService: VLCFavoriteService = VLCAppCoordinator.sharedInstance().favoriteService
    
    // For delete operations
    private var currentlyFocusedIndexPath: IndexPath?
    private var isAnyCellFocused: Bool = false
    
    init() {
        super.init(nibName: "VLCRemoteBrowsingCollectionViewController", bundle: nil)
        title = NSLocalizedString("FAVORITES", comment: "")
        super.collectionView.register(FavoriteSectionHeader.self, forSupplementaryViewOfKind:
                                        UICollectionView.elementKindSectionHeader, withReuseIdentifier: FavoriteSectionHeader.identifier)
        
        let deleteRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(startEditMode))
        deleteRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        deleteRecognizer.minimumPressDuration = 1.0
        self.view.addGestureRecognizer(deleteRecognizer)
        
        let cancelRecognizer = UITapGestureRecognizer(target: self, action: #selector(endEditMode))
        cancelRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue), NSNumber(value: UIPress.PressType.menu.rawValue)]
        cancelRecognizer.isEnabled = self.isEditing
        self.view.addGestureRecognizer(cancelRecognizer)
        showEmptyViewIfNeeded()
    }
    
    required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
    }
    
    private func showEmptyViewIfNeeded() {
        if favoriteService.numberOfFavoritedServers == 0 {
            self.nothingFoundLabel.text = NSLocalizedString("NO_FAVORITES_DESCRIPTION", comment: "")
            self.nothingFoundLabel.sizeToFit()
            let nothingFoundView = self.nothingFoundView
            nothingFoundView!.sizeToFit()
            nothingFoundView!.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(nothingFoundView!)
            
            let yConstraint = NSLayoutConstraint(item: nothingFoundView as Any,
                                                 attribute: .centerY,
                                                 relatedBy: .equal,
                                                 toItem: self.view,
                                                 attribute: .centerY,
                                                 multiplier: 1.0,
                                                 constant: 0.0)
            self.view.addConstraint(yConstraint)
            
            let xConstraint = NSLayoutConstraint(item: nothingFoundView as Any,
                                                 attribute: .centerX,
                                                 relatedBy: .equal,
                                                 toItem: self.view,
                                                 attribute: .centerX,
                                                 multiplier: 1.0,
                                                 constant: 0.0)
            self.view.addConstraint(xConstraint)
        }
    }
}
// MARK: - UICollectionView
extension VLCFavoriteListViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favoriteService.numberOfFavoritesOfServer(at: section)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return favoriteService.numberOfFavoritedServers
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VLCRemoteBrowsingTVCell", for: indexPath) as! VLCRemoteBrowsingTVCell
        if let favorite = favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row) {
            cell.title = favorite.userVisibleName
        }
        cell.isDirectory = true
        cell.thumbnailImage = UIImage(named: "folder")
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let favorite = favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row) {

            var serverBrowser: VLCNetworkServerBrowser? = nil
            let identifier = favorite.protocolIdentifier as NSString

            /* fasttrack UPnP as it does not allow authentication */
            if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierUPnP) {
                serverBrowser = VLCNetworkServerBrowserVLCMedia.uPnPNetworkServerBrowser(with: favorite.url)
            } else {
                if let login = favorite.loginInformation {
                    if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierFTP) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia.ftpNetworkServerBrowser(withLogin: login)
                    } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierPlex) {
                        serverBrowser = VLCNetworkServerBrowserPlex.init(login: login)
                    } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierSMB) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia.smbNetworkServerBrowser(withLogin: login)
                    } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierNFS) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia.nfsNetworkServerBrowser(withLogin: login)
                    } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierSFTP) {
                        serverBrowser = VLCNetworkServerBrowserVLCMedia.sftpNetworkServerBrowser(withLogin: login)
                    }
                } else {
                    let media = VLCMedia(url: favorite.url)
                    serverBrowser = VLCNetworkServerBrowserVLCMedia(media: media)
                }
            }

            let serverBrowserVC = VLCSearchableServerBrowsingTVViewController(serverBrowser: serverBrowser!)
            self.navigationController?.pushViewController(serverBrowserVC, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
         if kind == UICollectionView.elementKindSectionHeader {
             let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FavoriteSectionHeader.identifier, for: indexPath) as!  FavoriteSectionHeader
             header.headerView.hostnameLabel.text = favoriteService.nameOfFavoritedServer(at: indexPath
                .section)
             header.headerView.section = indexPath.section
             header.headerView.delegate = self
            return header
         }
        return UICollectionReusableView()
    }
    
}
// MARK: - Deletion
extension VLCFavoriteListViewController {
    @objc private func startEditMode() {
        self.isEditing = true
        let alertController = UIAlertController(title: NSLocalizedString("UNFAVORITE_ALERT_TITLE", comment: ""), message: nil, preferredStyle: .alert)

        let confirmAction = UIAlertAction(title: NSLocalizedString("REMOVE_FAVORITE", comment: ""), style: .default) { (action) in
            self.favoriteService.removeFavoriteOfServer(with: self.currentlyFocusedIndexPath!.section, at: self.currentlyFocusedIndexPath!.row)
            self.collectionView.reloadData()
        }

        let cancelAction = UIAlertAction(title:"BUTTON_CANCEL", style: .destructive, handler: nil)

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        if self.isAnyCellFocused {
            present(alertController, animated: true, completion: nil)
        }
            
    }
    
    @objc private func endEditMode() {
        self.isEditing = false
    }
}
// MARK: - Rename Delegate
extension VLCFavoriteListViewController: FavoriteSectionHeaderDelegate {
    func reloadData() {
        self.collectionView.reloadData()
    }
}
// MARK: - UICollectionViewFlowLayout
extension VLCFavoriteListViewController {
    override func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard let nextFocusedIndexPath = context.nextFocusedIndexPath else {
            // Handle the case where nextFocusedIndexPath is nil, if needed.
            return
        }
        self.currentlyFocusedIndexPath = nextFocusedIndexPath
        self.isAnyCellFocused = true
        let sectionNumber = nextFocusedIndexPath.section
        let sectionHeaderIndexPath = IndexPath(item: 0, section: sectionNumber)
        if let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: sectionHeaderIndexPath) as? FavoriteSectionHeader {
            setupFocusGuide(for: header, at: nextFocusedIndexPath, in: collectionView)
        }
    }
}

extension VLCFavoriteListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: FavoriteSectionHeader.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 50, left: 100, bottom: 50, right: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 100.00
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 48
    }
    
}

public extension IndexPath {
  func isLastRow(at collectionView: UICollectionView) -> Bool {
    return row == (collectionView.numberOfItems(inSection: section) - 1)
  }
}

// MARK: - Focus Engine Guide for Header's Rename Button
extension VLCFavoriteListViewController {
    private func setupFocusGuide(for header: FavoriteSectionHeader, at indexPath: IndexPath, in collectionView: UICollectionView) {
        let focusGuide = UIFocusGuide()
        self.view.addLayoutGuide(focusGuide)
        focusGuide.isEnabled = true
        focusGuide.preferredFocusEnvironments = [header.headerView.renameButton]

        let cell = collectionView.cellForItem(at: indexPath)
        
        focusGuide.widthAnchor.constraint(equalTo: cell?.widthAnchor ?? focusGuide.widthAnchor).isActive = true
        focusGuide.heightAnchor.constraint(equalTo: cell?.heightAnchor ?? focusGuide.heightAnchor).isActive = true

        if indexPath.isLastRow(at: collectionView) {
            focusGuide.bottomAnchor.constraint(equalTo: cell?.bottomAnchor ?? focusGuide.bottomAnchor).isActive = true
            focusGuide.leftAnchor.constraint(equalTo: cell?.rightAnchor ?? focusGuide.leftAnchor).isActive = true
        } else {
            focusGuide.bottomAnchor.constraint(equalTo: cell?.topAnchor ?? focusGuide.bottomAnchor).isActive = true
            focusGuide.leftAnchor.constraint(equalTo: cell?.leftAnchor ?? focusGuide.leftAnchor).isActive = true
        }
    }
}
