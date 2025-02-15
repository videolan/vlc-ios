/*****************************************************************************
 * Observable.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2019 VideoLAN. All rights reserved.
 * Copyright © 2019 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *          Craig Reyenga <craig.reyenga # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class Observable<T: AnyObject> {
    // Using ObjectIdentifier to avoid duplication and facilitate identification of observing object
    private var observers = [ObjectIdentifier: Observer<T>]()

    func addObserver(_ observer: T) {
        let identifier = ObjectIdentifier(observer)
        observers[identifier] = Observer(observer)
    }

    func removeObserver(_ observer: T) {
        let identifier = ObjectIdentifier(observer)
        observers.removeValue(forKey: identifier)
    }

    /// Notify observers by executing the provided action upon each.
    /// - Parameter action: the action to execute upon each observer
    func notifyObservers(action: (T) -> Void) {
        // Copy keys before iterating so we can detect observers that have been
        // removed as a side effect of calling out to a previous observer.
        let keys = Array(observers.keys)

        for k in keys {
            guard let observer = observers[k]?.observer else { continue }
            action(observer)
        }
    }

}

// MARK: - Observer

// Since weak is a property assigned to anything that is of class type and not struct
// you have to explicitly constraint your generic parameter to be of class type
fileprivate class Observer<T: AnyObject> {
   weak var observer: T?

   init(_ observer: T) {
       self.observer = observer
   }
}
