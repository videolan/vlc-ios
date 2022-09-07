/*****************************************************************************
 * Observable.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2019 VideoLAN. All rights reserved.
 * Copyright © 2019 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

// MARK: - Observer

// Since weak is a property assigned to anything that is of class type and not struct
// you have to explicitly constraint your generic parameter to be of class type
class Observer<T: AnyObject> {
    weak var observer: T?

    init(_ observer: T) {
        self.observer = observer
    }
}

class Observable<T: AnyObject> {
    // Using ObjectIdentifier to avoid duplication and facilitate identification of observing object
    private(set) var observers = [ObjectIdentifier: Observer<T>]()

    func addObserver(_ observer: T) {
        let identifier = ObjectIdentifier(observer)
        observers[identifier] = Observer(observer)
    }

    func removeObserver(_ observer: T) {
        let identifier = ObjectIdentifier(observer)
        observers.removeValue(forKey: identifier)
    }
}
