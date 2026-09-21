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
    private static let downloadImage = UIImage(systemName: "arrow.down.circle",
                                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))

    private static let downloadedImage = UIImage(systemName: "arrow.down.circle.fill",
                                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))

    private static let downloadingImage = UIImage(systemName: "stop.circle",
                                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))

    private(set) var isDownloaded = false
    private(set) var isDownloading = false

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
            setImage(PodcastDownloadButton.downloadingImage, for: .normal)
            tintColor = colors.orangeUI
            accessibilityLabel = NSLocalizedString("PODCAST_EPISODE_CANCEL_DOWNLOAD", comment: "")
            return
        }

        if downloaded {
            setImage(PodcastDownloadButton.downloadedImage, for: .normal)
            tintColor = colors.orangeUI
        } else {
            setImage(PodcastDownloadButton.downloadImage, for: .normal)
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
