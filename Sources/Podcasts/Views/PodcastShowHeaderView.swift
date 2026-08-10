/*****************************************************************************
 * PodcastShowHeaderView.swift
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

class PodcastShowHeaderView: UIView {
    private let show: PodcastShow

    private let artworkView = PodcastArtworkView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .title2).semibolded
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var titleFrame: CGRect {
        return nameLabel.frame
    }

    init(show: PodcastShow) {
        self.show = show
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(artworkView)
        addSubview(nameLabel)

        artworkView.configure(name: show.name, artworkURL: show.artworkURL, cornerRadius: 20, fontSize: 44)

        nameLabel.text = show.name

        var constraints = [
            artworkView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            artworkView.centerXAnchor.constraint(equalTo: centerXAnchor),
            artworkView.widthAnchor.constraint(equalToConstant: 140),
            artworkView.heightAnchor.constraint(equalToConstant: 140),

            nameLabel.topAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30)
        ]

        if let author = show.author, !author.isEmpty {
            addSubview(authorLabel)
            authorLabel.text = author
            constraints += [
                authorLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
                authorLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
                authorLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
                authorLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
            ]
        } else {
            constraints.append(nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4))
        }

        NSLayoutConstraint.activate(constraints)

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        backgroundColor = colors.background
        nameLabel.textColor = colors.cellTextColor
        authorLabel.textColor = colors.cellDetailTextColor
    }
}
