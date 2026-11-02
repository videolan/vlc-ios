/*****************************************************************************
 * VLCNetworkListCell+PodcastFeed.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

extension VLCNetworkListCell {
    private static let podcastArtworkSize: CGFloat = 72
    private static let podcastArtworkRadius: CGFloat = 9
    private static let podcastVerticalPadding: CGFloat = 8

    @objc static var podcastFeedHeight: CGFloat {
        return podcastArtworkSize + 2 * podcastVerticalPadding
    }

    @objc(configureWithPodcastFeed:subscriptionState:)
    func configure(podcastFeed feed: VLCPodcastIndexFeed, subscriptionState state: PodcastSubscriptionState) {
        title = feed.title
        subtitle = feed.subtitle
        thumbnailView.setImage(nil, placeholderName: feed.title)
        iconURL = feed.artworkURL
        thumbnailWidthConstraint.constant = VLCNetworkListCell.podcastArtworkSize
        thumbnailHeightConstraint.constant = VLCNetworkListCell.podcastArtworkSize
        thumbnailView.layer.cornerRadius = VLCNetworkListCell.podcastArtworkRadius
        isDownloadable = false
        isFavorable = false
        apply(podcastSubscriptionState: state)
    }

    @objc(applyPodcastSubscriptionState:)
    func apply(podcastSubscriptionState state: PodcastSubscriptionState) {
        switch state {
        case .available:
            accessoryView = nil
            accessoryType = .none
        case .pending:
            let coneView = PulsingConeView(coneSize: 22)
            coneView.startAnimating()
            accessoryType = .none
            accessoryView = coneView
        case .subscribed:
            accessoryView = nil
            accessoryType = .checkmark
            tintColor = PresentationTheme.current.colors.orangeUI
        }
    }
}
