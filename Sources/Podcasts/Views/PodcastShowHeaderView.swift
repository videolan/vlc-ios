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
    var onToggleSubscribe: (() -> Void)?

    private let show: PodcastShow
    private let store = PodcastStore.shared

    private let artworkView = PodcastArtworkView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .title2).semibolded
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subscribeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .preferredCustomFont(forTextStyle: .footnote).semibolded
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

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
        addSubview(subscribeButton)

        subscribeButton.addTarget(self, action: #selector(didTapSubscribe), for: .touchUpInside)

        artworkView.configure(name: show.name, artworkURL: show.artworkURL, cornerRadius: 20, fontSize: 44)

        nameLabel.text = show.name

        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            artworkView.centerXAnchor.constraint(equalTo: centerXAnchor),
            artworkView.widthAnchor.constraint(equalToConstant: 140),
            artworkView.heightAnchor.constraint(equalToConstant: 140),

            nameLabel.topAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),

            subscribeButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12),
            subscribeButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            subscribeButton.heightAnchor.constraint(equalToConstant: 40),
            subscribeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            subscribeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
        refreshSubscribeState()
    }

    func refreshSubscribeState() {
        let isSubscribed = store.isSubscribed(showId: show.id)
        let colors = PresentationTheme.current.colors

        let title = isSubscribed
            ? NSLocalizedString("PODCAST_SUBSCRIBED", comment: "")
            : NSLocalizedString("PODCAST_SUBSCRIBE", comment: "")
        subscribeButton.setTitle(title, for: .normal)

        if isSubscribed {
            subscribeButton.backgroundColor = .clear
            subscribeButton.setTitleColor(colors.cellTextColor, for: .normal)
            subscribeButton.layer.borderWidth = 1
            subscribeButton.layer.borderColor = colors.separatorColor.cgColor
        } else {
            subscribeButton.backgroundColor = colors.orangeUI
            subscribeButton.setTitleColor(colors.background, for: .normal)
            subscribeButton.layer.borderWidth = 0
        }
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        backgroundColor = colors.background
        nameLabel.textColor = colors.cellTextColor
        refreshSubscribeState()
    }

    @objc private func didTapSubscribe() {
        onToggleSubscribe?()
    }
}
