/*****************************************************************************
 * RadioController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: David Neacsu <neacsudavid287 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import VLCKit
import SwiftUI
import Combine

class RadioController: NSObject, ObservableObject, VLCMediaDiscovererDelegate, VLCMediaParserDelegate {
    static let shared: RadioController = RadioController()
    
    // MARK: Class Parameters
    @Published private(set) var countries: [RadioStation] = []
    @Published private(set) var stations: [RadioStation] = []
    @Published private(set) var isLoadingCountries: Bool = false
    @Published private(set) var isLoadingStations: Bool = false
    
    @Published private(set) var recents: [RadioStation] = []
    @Published private(set) var favorites: [RadioStation] = []
    
    @Published private(set) var hasError: Bool = false
    @Published private(set) var errorMessage: String = ""

    private var discoverer: VLCMediaDiscoverer?
    private var subitemsObserver: NSObjectProtocol?
    private var mediaParser: VLCMediaParser?
    
    /// Set the number of recently played stations to be saved
    private let maxRecents = 10
    
    private var storageURL: URL? {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("FavoritesRadioStation.json")
    }
    
    private override init() {
        super.init()
        loadSavedStations()
    }

    // MARK: Radio Discovery Service Control Methods
    /// Starts the vlc discoverer based on the predefined radio stations list. The discoverer fetches the list of countries. Results and effects can be seen on method calls for mediaAdded and mediaRemoved
    func enableDiscovery() {
        if discoverer != nil {
            return
        }
        let newDiscoverer = VLCMediaDiscoverer(name: "radio")
        newDiscoverer.delegate = self
        
        let responseDiscovery = newDiscoverer.start()
        
        if responseDiscovery != 0 {
            setError(NSLocalizedString("RADIO_GENERIC_ERROR", comment: ""))
        }
        
        discoverer = newDiscoverer
        setLoadingAnimated(true, for: \.isLoadingCountries)
    }
    
    
    /// Stops the discoverer from searching and loading countries list and stations list
    func stopDiscovery() {
        discoverer?.delegate = nil
        discoverer?.stop()
        discoverer = nil
    }
    
    
    // MARK: Discovery Service Delegate Methods
    func mediaAdded(_ media: VLCMedia, parent: VLCMedia?) {
        DispatchQueue.main.async {
            self.reloadCountries()
        }
    }
    
    func mediaRemoved(_ media: VLCMedia) {
        DispatchQueue.main.async {
            self.reloadCountries()
        }
    }
    
    func mediaFinishedParsing(_ media: VLCMedia, with status: VLCMediaParsedStatus) {
        DispatchQueue.main.async {
            switch status {
            case .failed, .timeout:
                self.setError(NSLocalizedString("RADIO_DATA_LOAD_ERROR", comment: ""))
                break
            case .done:
                if media.mediaType == .directory {
                    self.reloadCountries()
                } else {
                    self.reloadStations(for: media)
                }
                break
            default :
                break
            }
        }
    }
    
    
    private func reloadCountries() {
        if let list = discoverer?.discoveredMedia {
            setLoadingAnimated(true, for: \.isLoadingCountries)
            
            list.lock()
            defer {
                list.unlock()
            }
            
            countries = (0..<list.count).compactMap { i -> RadioStation? in
                guard let media = list.media(at: UInt(i)) else { return nil }
                let md = media.metaData
                let title = md.title ?? media.url?.lastPathComponent ?? NSLocalizedString("UNKNOWN_ALBUM", comment: "")
                let id = media.url?.absoluteString
                    ?? String(ObjectIdentifier(media).hashValue)
                return RadioStation(id: id, title: title, imageURL: md.artworkURL, media: media)
            }
            setLoadingAnimated(false, for: \.isLoadingCountries)
        }
    }
    
    private func reloadStations(for country: VLCMedia) {
        if let list = country.subitems {
            setLoadingAnimated(true, for: \.isLoadingStations)
            
            list.lock()
            defer {
                list.unlock()
            }
            
            stations = (0..<list.count).compactMap { i -> RadioStation? in
                guard let media = list.media(at: UInt(i)) else { return nil }
                let md = media.metaData
                let title = md.title ?? media.url?.lastPathComponent ?? NSLocalizedString("UNKNOWN_ALBUM", comment: "")
                let id = media.url?.absoluteString
                    ?? String(ObjectIdentifier(media).hashValue)
                return RadioStation(id: id, title: title, imageURL: md.artworkURL, media: media)
            }
            setLoadingAnimated(false, for: \.isLoadingStations)
        }
    }
    
    
    /// Loads the station list based on the country selected. It make a request to the parser for populating the stations list.
    /// - Parameter country: The country for which the stations should be obtained
    func loadCountryStations(country: RadioStation) {
        stations = []
        
        setLoadingAnimated(true, for: \.isLoadingStations)
        
        if mediaParser != nil {
            clearMediaParser()
        }
        
        let newMediaParser = VLCMediaParser(library: VLCLibrary.shared(), timeout: -1)
        newMediaParser.delegate = self
        newMediaParser.queue(country.media, options: .parse)
        
        mediaParser = newMediaParser
        
        if let observer = subitemsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        subitemsObserver = NotificationCenter.default.addObserver(forName: VLCMedia.subitemsChangedNotification, object: country.media, queue: .main, using: { _ in
            self.reloadStations(for: country.media)
        })
        
        reloadStations(for: country.media)
    }
    
    
    /// Method used for exiting the stations list. Must be called for clearing the list and the parser for obtaining the list for the new country that wil selected
    func leaveCountryStations() {
        if let observer = subitemsObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        stations = []
        clearMediaParser()
    }
    
    // MARK: Recents Methods
    
    /// Method for registering a station in the recent played staitons
    /// It removes the duplicates and trims the list to the maximum number set by maxRecents parameter
    /// - Parameter station: the station to be remembered
    func addStationToRecents(_ station: RadioStation) {
        recents.removeAll(where: { $0.id == station.id})
        recents.insert(station, at: 0)
        
        if recents.count > maxRecents {
            recents = Array(recents.prefix(maxRecents))
        }
        
        saveStations()
    }
    
    // MARK: Favorites Methods
    
    /// Method for checking if a station is added to favorites
    /// - Parameter station: the station checked if it's added for favorites
    /// - Returns: True/False if it is
    func isFavorite(_ station: RadioStation) -> Bool {
        favorites.contains(where: { $0.id == station.id })
    }
    
    /// Add a station to the favorites list
    /// - Parameter station: the station to be added to favorites
    func addStationToFavorites(_ station: RadioStation) {
        guard !isFavorite(station) else { return }
        favorites.append(station)
        saveStations()
    }
    
    /// Removes the station from the favorites list
    /// - Parameter station: The station to be removed from favorites
    func removeStationFromFavorites(_ station: RadioStation) {
        favorites.removeAll(where: { $0.id == station.id })
        saveStations()
    }
    
    /// Method used for the favorites button. It adds or removes the station from the favorites based on the previous state
    /// - Parameter station: the station to be added or removed to/from favorites
    func toggleFavorites(_ station: RadioStation) {
        if isFavorite(station) {
            removeStationFromFavorites(station)
        } else {
            addStationToFavorites(station)
        }
    }
    
    // MARK: Storage Methods
    private func saveStations() {
        let storageData = SavedStations(
            recents: recents.map { $0.record },
            favorites: favorites.map { $0.record }
        )
        
        guard let data = try? JSONEncoder().encode(storageData) else { return }
        guard storageURL != nil else { return }
        try? data.write(to: storageURL!, options: .atomic)
    }
    
    private func loadSavedStations() {
        guard storageURL != nil else { return }
        guard let data = try? Data(contentsOf: storageURL!), let savedData = try? JSONDecoder().decode(SavedStations.self, from: data) else { return }
        
        recents = savedData.recents.compactMap({ RadioStation(record: $0) })
        favorites = savedData.favorites.compactMap({ RadioStation(record: $0) })
    }

    // MARK: Utility Methods
    
    /// Sets the new value for the parsed variable with a default or defined animation. Useful for affecting Views based on the parsed variable
    /// - Parameters:
    ///   - newValue: The new value to be set
    ///   - keyPath: The variable to be modified
    ///   - animation: The animation used for displaying the effect. Default is .easeInOut(duration: 0.25)
    private func setLoadingAnimated(_ newValue: Bool, for keyPath: ReferenceWritableKeyPath<RadioController, Bool>, animation: Animation = .easeInOut(duration: 0.25)) {
        withAnimation(animation) {
            self[keyPath: keyPath] = newValue
        }
    }
    
    private func setError(_ message: String) {
        withAnimation(.easeIn) {
            errorMessage = message
            hasError = true
        }
    }
    
    /// Clears any error. Must be used for removing displayed errors
    func dismissError() {
        withAnimation(.easeOut) {
            errorMessage = ""
            hasError = false
        }
    }

    private func clearMediaParser() {
        mediaParser?.delegate = nil
        mediaParser = nil
    }
    
}
