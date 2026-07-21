/*****************************************************************************
 * PodcastShowHeaderCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class PodcastShowHeaderCell: UITableViewCell {
    static let reuseIdentifier = "PodcastShowHeaderCell"

    private(set) var headerView: PodcastShowHeaderView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        selectionStyle = .none
    }

    @discardableResult
    func configure(show: PodcastShow, onToggleSubscribe: @escaping () -> Void) -> PodcastShowHeaderView {
        headerView?.removeFromSuperview()

        let headerView = PodcastShowHeaderView(show: show)
        headerView.onToggleSubscribe = onToggleSubscribe
        contentView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        self.headerView = headerView
        return headerView
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        headerView?.removeFromSuperview()
        headerView = nil
    }
}
