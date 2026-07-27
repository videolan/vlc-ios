/*****************************************************************************
 * PodcastDownloadButton.swift
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

class PodcastDownloadButton: UIButton {
    private(set) var isDownloaded = false
    private(set) var isDownloading = false

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let style: UIActivityIndicatorView.Style
        #if os(visionOS)
        // visionOS has no pre-iOS-13 codepath to support, and .gray doesn't exist there at all.
        style = .medium
        #else
        if #available(iOS 13.0, *) {
            style = .medium
        } else {
            style = .gray
        }
        #endif
        let indicator = UIActivityIndicatorView(style: style)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

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
        contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        imageView?.contentMode = .scaleAspectFit
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        applyTheme()
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(applyTheme),
                                                name: .VLCThemeDidChangeNotification,
                                                object: nil)
    }

    func configure(downloaded: Bool, downloading: Bool = false) {
        isDownloaded = downloaded
        isDownloading = downloading
        let colors = PresentationTheme.current.colors

        if downloading {
            setImage(nil, for: .normal)
            activityIndicator.startAnimating()
            isUserInteractionEnabled = false
            accessibilityLabel = NSLocalizedString("PODCAST_EPISODE_DOWNLOADING", comment: "")
            return
        }
        activityIndicator.stopAnimating()
        isUserInteractionEnabled = true

        guard #available(iOS 13.0, *) else {
            setTitle(downloaded ? "✓" : "↓", for: .normal)
            return
        }

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        if downloaded {
            setImage(UIImage(systemName: "checkmark.circle.fill", withConfiguration: config), for: .normal)
            tintColor = colors.orangeUI
        } else {
            setImage(UIImage(systemName: "arrow.down.circle", withConfiguration: config), for: .normal)
            tintColor = colors.cellDetailTextColor
        }
        accessibilityLabel = downloaded
            ? NSLocalizedString("PODCAST_EPISODE_DOWNLOADED", comment: "")
            : NSLocalizedString("PODCAST_EPISODE_DOWNLOAD", comment: "")
    }

    @objc private func applyTheme() {
        configure(downloaded: isDownloaded, downloading: isDownloading)
    }
}
