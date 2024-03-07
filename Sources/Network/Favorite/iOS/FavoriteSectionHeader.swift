/*****************************************************************************
 * FavoriteSectionHeader.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Eshan Singh <eeeshan789@icloud.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class FavoriteSectionHeader: UITableViewHeaderFooterView {
    static var identifier = "FavoriteSectionHeader"
    static var height: CGFloat = 40

    lazy var headerView: FavoriteHeaderContentView = {
        return FavoriteHeaderContentView()
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupContentView()
    }
       
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupContentView() {
      contentView.addSubview(headerView)
      headerView.translatesAutoresizingMaskIntoConstraints = false
     
      NSLayoutConstraint.activate([
        headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
        headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        headerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
      ])
    }
}
