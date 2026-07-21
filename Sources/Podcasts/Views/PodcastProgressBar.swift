/*****************************************************************************
 * PodcastProgressBar.swift
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

class PodcastProgressBar: UIView {
    private let trackView = UIView()
    private let fillView = UIView()
    private var fillWidthConstraint: NSLayoutConstraint?

    var progress: CGFloat = 0 {
        didSet {
            updateFillWidth()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true

        trackView.translatesAutoresizingMaskIntoConstraints = false
        fillView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(trackView)
        trackView.addSubview(fillView)

        NSLayoutConstraint.activate([
            trackView.topAnchor.constraint(equalTo: topAnchor),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor)
        ])

        let widthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.isActive = true
        fillWidthConstraint = widthConstraint

        applyTheme()
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        trackView.layer.cornerRadius = layer.cornerRadius
        fillView.layer.cornerRadius = layer.cornerRadius
        updateFillWidth()
    }

    private func updateFillWidth() {
        let clamped = max(0, min(1, progress))
        fillWidthConstraint?.constant = bounds.width * clamped
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        trackView.backgroundColor = colors.separatorColor
        fillView.backgroundColor = colors.orangeUI
    }
}
