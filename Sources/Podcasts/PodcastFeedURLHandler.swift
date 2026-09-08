/*****************************************************************************
 * PodcastFeedURLHandler.swift
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

final class PodcastFeedURLHandler: NSObject, VLCURLHandler {
    var movieURL: URL?
    var subURL: URL?
    var successCallback: URL?
    var errorCallback: URL?
    var fileName: String?

    private static let feedSchemes = ["feed", "feeds", "pcast", "itpc"]
    private static let feedPathExtensions = ["opml", "rss"]

    private var pendingFeedURLs: [URL] = []
    private var pendingFallbackURL: URL?
    private var activationObserver: NSObjectProtocol?

    @objc func canHandleOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        if let scheme = url.scheme?.lowercased(), PodcastFeedURLHandler.feedSchemes.contains(scheme) {
            return true
        }

        return url.isFileURL
            && PodcastFeedURLHandler.feedPathExtensions.contains(url.pathExtension.lowercased())
    }

    @objc func performOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        pendingFeedURLs = []
        pendingFallbackURL = nil

        guard !url.isFileURL else {
            resolveDocument(at: url)
            return true
        }

        guard let resolved = feedURL(fromSchemeURL: url) else {
            presentError(.invalidURL)
            return true
        }

        pendingFeedURLs = [resolved.primary]
        pendingFallbackURL = resolved.fallback
        presentConfirmationWhenPossible()
        return true
    }

    // MARK: - Scheme normalization

    private func feedURL(fromSchemeURL url: URL) -> (primary: URL, fallback: URL?)? {
        guard let scheme = url.scheme?.lowercased() else {
            return nil
        }

        var remainder = String(url.absoluteString.dropFirst(scheme.count + 1))
        if remainder.hasPrefix("//") {
            remainder = String(remainder.dropFirst(2))
        }
        remainder = repairedSchemeSeparator(in: remainder)

        let lowercasedRemainder = remainder.lowercased()
        let webScheme = ["https://", "http://"].first { lowercasedRemainder.hasPrefix($0) }

        guard hasValidAuthority(in: remainder.dropFirst(webScheme?.count ?? 0)) else {
            return nil
        }

        if webScheme != nil {
            guard let primary = URL(string: remainder), primary.host != nil else {
                return nil
            }
            return (primary, nil)
        }

        guard let primary = URL(string: "https://" + remainder), primary.host != nil else {
            return nil
        }

        if scheme == "feeds" {
            return (primary, nil)
        }

        return (primary, URL(string: "http://" + remainder))
    }

    private func hasValidAuthority(in string: Substring) -> Bool {
        let authority = string.prefix { $0 != "/" && $0 != "?" && $0 != "#" }
        let hostAndPort = authority.split(separator: "@").last ?? ""

        guard !hostAndPort.hasPrefix("[") else {
            return hostAndPort.contains("]")
        }

        let components = hostAndPort.split(separator: ":", omittingEmptySubsequences: false)
        guard let host = components.first, !host.isEmpty, components.count <= 2 else {
            return false
        }

        guard components.count == 2 else {
            return true
        }

        return !components[1].isEmpty && components[1].allSatisfy { $0.isASCII && $0.isNumber }
    }

    // Safari rewrites "feed://https://example.org/x" to "feed://https//example.org/x"
    private func repairedSchemeSeparator(in string: String) -> String {
        for scheme in ["https", "http"] where string.hasPrefix(scheme + "//") {
            return scheme + "://" + String(string.dropFirst(scheme.count + 2))
        }

        return string
    }

    // MARK: - Document resolution

    private func resolveDocument(at url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let documentFeedURLs = self.feedURLs(inDocumentAt: url)

            DispatchQueue.main.async {
                guard !documentFeedURLs.isEmpty else {
                    self.presentError(.notAFeed)
                    return
                }

                self.pendingFeedURLs = documentFeedURLs
                self.presentConfirmationWhenPossible()
            }
        }
    }

    private func feedURLs(inDocumentAt url: URL) -> [URL] {
        let isSecurityScopedURL = url.startAccessingSecurityScopedResource()
        let data = try? Data(contentsOf: url)
        if isSecurityScopedURL {
            url.stopAccessingSecurityScopedResource()
        }

        if InboxManager.isInInbox(url) {
            try? FileManager.default.removeItem(at: url)
        }

        guard let data = data else {
            return []
        }

        let parser = PodcastFeedDocumentParser()
        if url.pathExtension.lowercased() == "opml" {
            return parser.subscribedFeedURLs(inOPML: data)
        }

        guard let selfURL = parser.selfURL(inFeed: data) else {
            return []
        }

        return [selfURL]
    }

    // MARK: - Confirmation

    private func presentConfirmationWhenPossible() {
        DispatchQueue.main.async {
            self.removeActivationObserver()

            if self.presentConfirmation() {
                return
            }

            /* on a cold launch the window is not key yet, so there is nothing to present on */
            self.activationObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                                            object: nil,
                                                                            queue: .main) { _ in
                guard self.presentConfirmation() || self.pendingFeedURLs.isEmpty else {
                    return
                }

                self.removeActivationObserver()
            }
        }
    }

    private func removeActivationObserver() {
        guard let observer = activationObserver else {
            return
        }

        NotificationCenter.default.removeObserver(observer)
        activationObserver = nil
    }

    @discardableResult
    private func presentConfirmation() -> Bool {
        guard !pendingFeedURLs.isEmpty,
              let viewController = UIApplication.shared.topViewController else {
            return false
        }

        let message: String
        if pendingFeedURLs.count == 1 {
            message = pendingFeedURLs[0].absoluteString
        } else {
            message = String(format: NSLocalizedString("PODCAST_SUBSCRIBE_FEEDS_MESSAGE", comment: ""),
                             pendingFeedURLs.count)
        }

        let cancelButton = VLCAlertButton(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                          style: .cancel) { _ in
            self.pendingFeedURLs = []
            self.pendingFallbackURL = nil
        }
        let subscribeButton = VLCAlertButton(title: NSLocalizedString("PODCAST_SUBSCRIBE", comment: ""),
                                             style: .default) { _ in
            self.subscribeToPendingFeeds()
        }

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("PODCAST_SUBSCRIBE", comment: ""),
                                                errorMessage: message,
                                                viewController: viewController,
                                                buttonsAction: [cancelButton, subscribeButton])
        return true
    }

    // MARK: - Subscribing

    private func subscribeToPendingFeeds() {
        let mediaLibraryService = VLCAppCoordinator.sharedInstance().mediaLibraryService
        PodcastStore.shared.configure(mediaLibraryService: mediaLibraryService)

        let feedURLs = pendingFeedURLs
        let fallbackURL = pendingFallbackURL
        pendingFeedURLs = []
        pendingFallbackURL = nil

        guard let podcastsViewController = showPodcasts(with: mediaLibraryService) else {
            presentError(.unknown)
            return
        }

        podcastsViewController.subscribe(to: feedURLs, fallbackURL: fallbackURL)
    }

    private func showPodcasts(with mediaLibraryService: MediaLibraryService) -> PodcastsViewController? {
        let tabBarController = VLCAppCoordinator.sharedInstance().tabBarController
        guard let controllers = tabBarController.viewControllers,
              let index = controllers.firstIndex(where: {
                  ($0 as? UINavigationController)?.viewControllers.first is VLCOnAirViewController
              }),
              let navigationController = controllers[index] as? UINavigationController else {
            return nil
        }

        tabBarController.selectedIndex = index

        if let podcastsViewController = navigationController.viewControllers.compactMap({ $0 as? PodcastsViewController }).last {
            navigationController.popToViewController(podcastsViewController, animated: true)
            return podcastsViewController
        }

        let podcastsViewController = PodcastsViewController(mediaLibraryService: mediaLibraryService)
        navigationController.pushViewController(podcastsViewController, animated: true)
        return podcastsViewController
    }

    // MARK: - Errors

    private func presentError(_ reason: PodcastAddSubscriptionError) {
        presentAlert(message: reason.localizedMessage)
    }

    private func presentAlert(message: String) {
        guard let viewController = UIApplication.shared.topViewController else {
            return
        }

        VLCAlertViewController.alertViewManager(title: NSLocalizedString("PODCAST_SUBSCRIBE", comment: ""),
                                                errorMessage: message,
                                                viewController: viewController)
    }
}

private class PodcastFeedDocumentParser: NSObject {
    fileprivate var feedURLs: [URL] = []
    fileprivate var selfLinkURL: URL?
    fileprivate var isParsingFeed = false

    func subscribedFeedURLs(inOPML data: Data) -> [URL] {
        isParsingFeed = false
        parse(data)
        return feedURLs
    }

    func selfURL(inFeed data: Data) -> URL? {
        isParsingFeed = true
        parse(data)
        return selfLinkURL
    }

    private func parse(_ data: Data) {
        feedURLs = []
        selfLinkURL = nil

        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = false
        parser.delegate = self
        parser.parse()
    }

    fileprivate func webURL(from string: String?) -> URL? {
        guard let string = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: string),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil else {
            return nil
        }

        return url
    }
}

extension PodcastFeedDocumentParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName: String?, attributes attributeDict: [String: String]) {
        let element = elementName.lowercased()

        if element == "outline" {
            let type = attributeDict.first { $0.key.lowercased() == "type" }?.value.lowercased()
            guard type == nil || type == "rss" || type == "atom",
                  let value = attributeDict.first(where: { $0.key.lowercased() == "xmlurl" })?.value,
                  let url = webURL(from: value) else {
                return
            }
            feedURLs.append(url)
            return
        }

        guard isParsingFeed, element == "link" || element.hasSuffix(":link"),
              attributeDict.first(where: { $0.key.lowercased() == "rel" })?.value.lowercased() == "self",
              let url = webURL(from: attributeDict.first(where: { $0.key.lowercased() == "href" })?.value) else {
            return
        }

        selfLinkURL = url
        parser.abortParsing()
    }
}
