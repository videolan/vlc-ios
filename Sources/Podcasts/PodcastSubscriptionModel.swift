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

    func addSubscription(mrl: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let success = self.service?.addSubscription(withMRL: mrl) ?? false
            DispatchQueue.main.async {
                if success {
                    self.refresh()
                    self.observable.notifyObservers { $0.mediaLibraryBaseModelReloadView() }
                }
                completion(success)
            }
        }
    }

    func removeSubscription(_ subscription: VLCMLSubscription) {
        _ = medialibrary.medialib.removeSubscription(withIdentifier: subscription.identifier())
        refresh()
        observable.notifyObservers { $0.mediaLibraryBaseModelReloadView() }
    }

    private func refresh() {
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
                      didUpdateCacheForSubscriptionWithId subscriptionId: NSNumber) {
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
