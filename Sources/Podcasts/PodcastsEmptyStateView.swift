/*****************************************************************************
 * PodcastsEmptyStateView.swift
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

class PodcastsEmptyStateView: UIView {
    var onSearchPodcasts: (() -> Void)?
    var onAddViaRSS: (() -> Void)?

    private let iconBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .title2).semibolded
        label.textAlignment = .center
        label.text = NSLocalizedString("PODCAST_EMPTY_TITLE", comment: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = NSLocalizedString("PODCAST_EMPTY_DESCRIPTION", comment: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("PODCAST_SEARCH_PODCASTS", comment: ""), for: .normal)
        button.titleLabel?.font = .preferredCustomFont(forTextStyle: .subheadline).semibolded
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let addRSSButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("PODCAST_ADD_VIA_RSS", comment: ""), for: .normal)
        button.titleLabel?.font = .preferredCustomFont(forTextStyle: .subheadline).semibolded
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false

        iconBackground.addSubview(iconView)
        addSubview(iconBackground)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(searchButton)
        addSubview(addRSSButton)

        searchButton.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
        addRSSButton.addTarget(self, action: #selector(didTapAddRSS), for: .touchUpInside)

        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 34, weight: .regular)
            iconView.image = UIImage(systemName: "antenna.radiowaves.left.and.right", withConfiguration: config)
        }

        NSLayoutConstraint.activate([
            iconBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconBackground.topAnchor.constraint(equalTo: topAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 88),
            iconBackground.heightAnchor.constraint(equalToConstant: 88),

            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconBackground.bottomAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            searchButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            searchButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
            searchButton.heightAnchor.constraint(equalToConstant: 46),

            addRSSButton.topAnchor.constraint(equalTo: searchButton.bottomAnchor, constant: 10),
            addRSSButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            addRSSButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
            addRSSButton.heightAnchor.constraint(equalToConstant: 46),
            addRSSButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        iconBackground.backgroundColor = colors.orangeUI.withAlphaComponent(0.16)
        iconBackground.layer.cornerRadius = 44
        iconView.tintColor = colors.orangeUI
        titleLabel.textColor = colors.cellTextColor
        descriptionLabel.textColor = colors.cellDetailTextColor

        searchButton.backgroundColor = colors.orangeUI
        searchButton.setTitleColor(colors.background, for: .normal)

        addRSSButton.backgroundColor = .clear
        addRSSButton.setTitleColor(colors.cellTextColor, for: .normal)
        addRSSButton.layer.borderColor = colors.separatorColor.cgColor
    }

    @objc private func didTapSearch() {
        onSearchPodcasts?()
    }

    @objc private func didTapAddRSS() {
        onAddViaRSS?()
    }
}
