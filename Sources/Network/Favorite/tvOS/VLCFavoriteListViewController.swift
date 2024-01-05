//
//  VLCFavoriteListViewController.swift
//  VLC
//
//  Created by Eshan Singh on 02/01/24.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import Foundation

class VLCFavoriteListViewController: VLCRemoteBrowsingCollectionViewController {
    
    let cellImage = UIImage(named: "heart")
    let detailText = NSLocalizedString("FAVORITEVC_DETAILTEXT", comment: "")
    let favoriteService: VLCFavoriteService = VLCAppCoordinator.sharedInstance().favoriteService
    
    // For delete operations
    private var currentlyFocusedIndexPath: IndexPath?
    private var isAnyCellFocused: Bool = false
    
    init() {
        super.init(nibName: "VLCRemoteBrowsingCollectionViewController", bundle: nil)
        title = NSLocalizedString("FAVORITE", comment: "")
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
    }
    
    required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
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
        let favorite = favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VLCRemoteBrowsingTVCell", for: indexPath) as! VLCRemoteBrowsingTVCell
        cell.title = favorite.userVisibleName
        cell.isDirectory = true
        cell.thumbnailImage = UIImage(named: "folder")
        cell.titleLabel.textColor = UIColor.systemOrange
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let favorite = favoriteService.favoriteOfServer(with: indexPath.section, at: indexPath.row)
        let media = VLCMedia(url: favorite.url)
        let serverBrowser = VLCNetworkServerBrowserVLCMedia(media: media)
        let serverBrowserVC = VLCServerBrowsingTVViewController(serverBrowser: serverBrowser)
        self.navigationController?.pushViewController(serverBrowserVC, animated: true)
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
        let alertController = UIAlertController(title: "Remove this Folder from Favorites ?", message: nil, preferredStyle: .alert)

        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (action) in
            self.favoriteService.removeFavoriteOfServer(with: self.currentlyFocusedIndexPath!.section, at: self.currentlyFocusedIndexPath!.row)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)

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
    func reloadData(sectionIndex: NSInteger) {
        self.collectionView.reloadData()
    }
}
// MARK: - UICollectionViewFlowLayout
extension VLCFavoriteListViewController {
    override func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
          if let nextFocusedIndexPath = context.nextFocusedIndexPath {
              self.currentlyFocusedIndexPath = nextFocusedIndexPath
              self.isAnyCellFocused = true
              } else {
              self.isAnyCellFocused = false
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
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
}

