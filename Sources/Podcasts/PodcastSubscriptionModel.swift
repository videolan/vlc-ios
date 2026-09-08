/*****************************************************************************
 * PodcastSubscriptionModel.swift
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
import VLCMediaLibraryKit

final class PodcastSubscriptionModel: NSObject {
    private let medialibrary: MediaLibraryService
    let observable = VLCObservable<MediaLibraryBaseModelObserver>()

    private(set) var subscriptions: [VLCMLSubscription] = []

    private var service: VLCMLService? {
        return medialibrary.medialib.service(with: .podcast)
    }

    init(medialibrary: MediaLibraryService) {
        self.medialibrary = medialibrary
        super.init()
        medialibrary.observable.addObserver(self)
        refresh()
    }

    func media(for subscription: VLCMLSubscription) -> [VLCMLMedia] {
        return subscription.media() ?? []
    }

    func media(for subscription: VLCMLSubscription,
               sortedBy criteria: VLCMLSortingCriteria,
               desc: Bool,
               items: UInt32,
               offset: UInt32) -> [VLCMLMedia] {
        return subscription.media(with: criteria, desc: desc, items, offset) ?? []
    }

    func searchMedia(for subscription: VLCMLSubscription,
                     pattern: String,
                     sortedBy criteria: VLCMLSortingCriteria,
                     desc: Bool,
                     items: UInt32,
                     offset: UInt32) -> [VLCMLMedia] {
        return subscription.searchMedia(withPattern: pattern, sort: criteria, desc: desc, items, offset) ?? []
    }

    func addSubscription(mrl: URL, completion: @escaping (Result<Void, PodcastAddSubscriptionError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let success = self.service?.addSubscription(withMRL: mrl) ?? false
            guard success else {
                self.classifyFailure(for: mrl) { reason in
                    DispatchQueue.main.async {
                        completion(.failure(reason))
                    }
                }
                return
            }
            DispatchQueue.main.async {
                self.refresh()
                self.observable.notifyObservers { $0.mediaLibraryBaseModelReloadView() }
                completion(.success(()))
            }
        }
    }

    private func classifyFailure(for url: URL, completion: @escaping (PodcastAddSubscriptionError) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if error != nil {
                completion(.networkUnreachable)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.unknown)
                return
            }
            switch httpResponse.statusCode {
            case 200..<300:
                completion(.notAFeed)
            case 400..<600:
                completion(.httpError(statusCode: httpResponse.statusCode))
            default:
                completion(.unknown)
            }
        }
        task.resume()
    }

    func removeSubscription(_ subscription: VLCMLSubscription) {
        _ = medialibrary.medialib.removeSubscription(withIdentifier: subscription.identifier())
        refresh()
        observable.notifyObservers { $0.mediaLibraryBaseModelReloadView() }
    }

    func play(episodeId: String, subscription: VLCMLSubscription, partialFileURL: URL? = nil) {
        let mediaList = media(for: subscription)
        guard let index = mediaList.firstIndex(where: { String($0.identifier()) == episodeId }) else {
            return
        }
        let media = mediaList[index]

        let playbackService = PlaybackService.sharedInstance()
        playbackService.expectsAudioOnlyContent = true
        playbackService.fullscreenSessionRequested = media.type() == .video

        // The library still points the episode at its remote MRL while the download runs, so the
        // partial file has to be handed to the player directly, on its own.
        if let partialFileURL = partialFileURL, let partialMedia = VLCMedia(url: partialFileURL) {
            let list = VLCMediaList()
            list.add(partialMedia)
            playbackService.playMediaList(list, firstIndex: 0, subtitlesFilePath: nil)
        } else if UserDefaults.standard.bool(forKey: kVLCAutomaticallyPlayNextItem) {
            playbackService.playMedia(at: index, fromCollection: mediaList)
        } else {
            playbackService.play(media)
        }

        // Podcasts aren't one of the collection types setCurrentlyPlayingCollection recognizes
        // (playlist/album/artist/media group); clear it explicitly so Now Playing doesn't offer
        // a stale "back to <last collection>" link left over from a previous, unrelated screen.
        medialibrary.currentlyPlayingCollection = nil
    }

    func refresh() {
        subscriptions = service?.subscriptions() ?? []
    }
}

// MARK: - MediaLibraryObserver

extension PodcastSubscriptionModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: MediaLibraryService, didAddSubscriptions subscriptions: [VLCMLSubscription]) {
        reloadOnMain()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didModifySubscriptionsWithIds subscriptionIds: [NSNumber]) {
        reloadOnMain()
    }

    func medialibrary(_ medialibrary: MediaLibraryService, didDeleteSubscriptionsWithIds subscriptionIds: [NSNumber]) {
        reloadOnMain()
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didReceiveNewMediaForSubscriptionsWithIds subscriptionIds: [NSNumber]) {
        notifyOnMain()
    }

    func medialibrary(_ medialibrary: MediaLibraryService,
                      didUpdateCacheForSubscriptionWithId subscriptionId: VLCMLIdentifier) {
        notifyOnMain()
    }

    private func reloadOnMain() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.refresh()
            self.observable.notifyObservers { $0.mediaLibraryBaseModelReloadView() }
        }
    }

    private func notifyOnMain() {
        DispatchQueue.main.async { [weak self] in
            self?.observable.notifyObservers { $0.mediaLibraryBaseModelReloadView() }
        }
    }
}
