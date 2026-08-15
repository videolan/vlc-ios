/*****************************************************************************
 * ControlPlayerViewController.swift
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
import AVFoundation
import SwiftUI

extension VLCRepeatMode {
    func getName() -> String {
        switch self {
        case .doNotRepeat: return NSLocalizedString("OFF", comment: "")
        case .repeatAllItems: return NSLocalizedString("QUEUE_LABEL", comment: "")
        case .repeatCurrentItem: return NSLocalizedString("TRACKS_WO_COUNTER", comment: "")
        default: return NSLocalizedString("OFF", comment: "")
        }
    }
}

class ControlPlayerViewController: NSObject, ObservableObject {
    static let shared: ControlPlayerViewController = ControlPlayerViewController()
    lazy var playbackService = PlaybackService.sharedInstance()
    
    @Published private(set)var currentMedia: VLCMLMedia?
    @Published private(set)var nowPlayingTitle: String = ""
    @Published private(set)var nowPlayingArtworkURL: URL?
    @Published private(set)var nowPlayingRadioStation: RadioStation?
    
    @Published private(set)var isPlaying: Bool = false
    @Published private(set)var isMedia: Bool = false
    @Published private(set)var nextInQueue: [VLCMLMedia] = []
    
    @Published private(set)var shuffle: Bool = false
    
    // Errors ecountered
    @Published private(set)var errorMessage: String = ""
    @Published private(set)var hasError: Bool = false
    
    @Published private(set)var repeatMode: VLCRepeatMode = VLCRepeatMode.doNotRepeat
    
    private var queue: [VLCMLMedia] = []
    private var currentIndex: Int = 0

    override init() {
        super.init()
        
        isPlaying = playbackService.isPlaying
        isMedia = playbackService.currentlyPlayingMedia != nil
        playbackService.delegate = self
        playbackService.isShuffleMode = false
        shuffle = false
        repeatMode = playbackService.repeatMode
    }
    
    // MARK: Media Player methods
    
    /// Method used for playing radio stations. It recieved the radio stations and starts the player
    /// - Parameter station: the radio station to be played
    func playStation(station: RadioStation) {
        if let mlMedia = VLCMLMedia(forPlaying: station.media) {
            setNowPlaying(mlMedia: mlMedia)
            playbackService.play(mlMedia)
            nowPlayingRadioStation = station
            
            APLog("Playing: " + playbackService.description)
            
            return
        } else {
            APLog("There's been an error loading the station. Please try again.")
        }

        displayError(message: NSLocalizedString("STATION_LOAD_ERROR", comment: ""))
    }
    
    /// Used for playing a queue. It can be called anywhere and the player will the play the media from queue at the index.
    /// - Parameters:
    ///   - medias: The media queue to be played
    ///   - index: The starting index (counting begines from 0)
    func playQueue(_ medias: [VLCMLMedia], startingAt index: Int) {
        queue = medias
        playbackService.playMedia(at: index, fromCollection: medias)
        refreshNextInQueue()
    }
    
    
    // MARK: Player controls
    
    /// Method for Pause/Resume Button on Player UI. It pauses or resumes the media playing
    func pauseResumeToggle() {
        if isPlaying {
            playbackService.pause()
            isPlaying = false
        } else {
            playbackService.play()
            isPlaying = true
        }
    }

    /// Plays the next music in queue. If there isn't any other song left to play, restarts the same song.
    /// If repeat queue is ON, the queue becomes a circular list
    /// If repeat song is ON, plays the same song again
    func playNext() {
        playbackService.next()
    }

    /// Plays the previous music in queue. If there isn't any other song left to play, restarts the same song.
    /// If repeat queue is ON, the queue becomes a circular list
    /// If repeat song is ON, plays the same song again
    func playPrevious() {
        playbackService.previous()
    }
    
    
    /// It skips the track by index times. It's used for skiping the current playing track when a track is pressed to be played from the next in queue view.
    /// - Parameter index: The number of times the current track should be skipped.
    func skipTrack(_ index: Int) {
        let activeList = shuffle ? playbackService.shuffledList : playbackService.mediaList
        let nextIndex = currentIndex + 1 + index
        
        guard index > 0, activeList.count > nextIndex else {
            return
        }
        
        playbackService.playItem(at: UInt(nextIndex))
    }
    
    /// Dismisses the errors and the UI Error
    func dismissError() {
        self.errorMessage = ""
        self.hasError = false
    }
    
    /// Changes the repeat mode to the next one and applies the effect
    func changeRepeatMode() {
        playbackService.toggleRepeatMode()
    }
    
    /// Toggle suffle between on and off
    func toggleShuffle() {
        playbackService.isShuffleMode.toggle()
    }
    
    
    // MARK: Utility Methods
    private func setNowPlaying(media: VLCMedia) {
        guard let mlMedia = VLCMLMedia(forPlaying: media),
              let index = queue.firstIndex(where: { $0.identifier() == mlMedia.identifier() }) else {
            return
        }
        nowPlayingTitle = queue[index].title
        nowPlayingArtworkURL = queue[index].thumbnail()
    }
    
    private func setNowPlaying(mlMedia: VLCMLMedia) {
        nowPlayingTitle = mlMedia.title
        nowPlayingArtworkURL = mlMedia.thumbnail()
    }
    
    func refreshNextInQueue() {
        let newList = shuffle ? playbackService.shuffledList : playbackService.mediaList
        let newQueue : [VLCMLMedia] = (0 ..< Int(newList.count)).compactMap { VLCMLMedia(forPlaying: newList.media(at: UInt($0))) }
        
        guard let nowPlaying = playbackService.currentlyPlayingLibraryMedia,
              let index = newQueue.firstIndex(where: { $0.identifier() == nowPlaying.identifier() }) else {
            return
        }
        
        currentIndex = index
        nextInQueue = Array(newQueue.dropFirst(index + 1))
    }
    
    private func displayError(message: String) {
        withAnimation(.easeInOut) {
            self.errorMessage = message
            self.hasError = true
        }
    }
}

/// Extension of ControlPlayerViewController for separating the Playback Service Delegate
extension ControlPlayerViewController: VLCPlaybackServiceDelegate {
    func mediaPlayerStateChanged(_ currentState: VLCMediaPlayerState, isPlaying: Bool, currentMediaHasTrackToChooseFrom: Bool, currentMediaHasChapters: Bool, for playbackService: PlaybackService) {
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            switch currentState {
            case .opening:
                self.handlePlaybackStarting()
            case .playing:
                self.handlePlaybackStarted()
            case .paused:
                self.handlePlaybackPaused()
            case .stopping, .stopped:
                self.handlePlaybackStopped()
            case .error:
                self.handlePlaybackFailed()
            default:
                break
            }
        }
        
    }
    
    func playbackService(_ playbackService: PlaybackService, nextMedia media: VLCMedia) {
        DispatchQueue.main.async {
            self.refreshNextInQueue()
            self.setNowPlaying(media: media)
        }
    }
    
    func playModeUpdated() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.repeatMode = self.playbackService.repeatMode
            self.shuffle = self.playbackService.isShuffleMode
            self.refreshNextInQueue()
        }
    }
    
    private func handlePlaybackStarting() {
        isPlaying = true
        isMedia = true
    }
    
    private func handlePlaybackStarted() {
        isPlaying = true
        isMedia = true
    }

    private func handlePlaybackPaused() {
        isPlaying = false
        isMedia = playbackService.currentlyPlayingMedia != nil
    }

    private func handlePlaybackStopped() {
        isPlaying = false
        isMedia = playbackService.currentlyPlayingMedia != nil
        nowPlayingRadioStation = nil
    }

    private func handlePlaybackFailed() {
        isPlaying = false
        isMedia = playbackService.currentlyPlayingMedia != nil
        displayError(message: NSLocalizedString("RADIO_DATA_LOAD_ERROR", comment: ""))
    }
}
