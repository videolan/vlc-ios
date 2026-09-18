/*****************************************************************************
 * Screenshot.swift
 * VLC for iOSUITests
 *****************************************************************************
 * Copyright (c) 2018-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Mike JS. Choi <mkchoi212 # icloud.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import XCTest

class Screenshot: XCTestCase {
    let app = XCUIApplication()
    let environment = ProcessInfo.processInfo.environment

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        var arguments = ["-kVLCHasActiveSubscription", "YES",
                         "-hasLaunchedBefore", "YES",
                         "-darkMode", "2"]
        if let language = environment["VLC_SCREENSHOTS_LANGUAGE"], !language.isEmpty {
            arguments += ["-AppleLanguages", "(\(language))"]
        }
        if let locale = environment["VLC_SCREENSHOTS_LOCALE"], !locale.isEmpty {
            arguments += ["-AppleLocale", locale]
        }
        app.launchArguments = arguments

        XCUIDevice.shared.orientation = .portrait
        app.launch()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    // MARK: - Media library

    func test01VideoList() {
        tapTab(VLCAccessibilityIdentifier.video)
        _ = element(VLCAccessibilityIdentifier.mediaCell)
        capture("01_video_list")

        tap(element(VLCAccessibilityIdentifier.mediaMenu))
        tap(element(VLCAccessibilityIdentifier.select))
        let cells = visibleCells(VLCAccessibilityIdentifier.mediaCell)
        cells.prefix(2).forEach { $0.tap() }
        capture("02_video_list_selection")
    }

    func test02Playlists() {
        tapTab(VLCAccessibilityIdentifier.playlist)
        let playlist = firstVisibleCell(VLCAccessibilityIdentifier.mediaCell)
        capture("03_playlists")

        playlist.tap()
        capture("04_playlist")
    }

    func test03AudioArtists() {
        openAudioCategory(VLCAccessibilityIdentifier.artists)
        let artistCount = visibleCells(VLCAccessibilityIdentifier.mediaCell).count
        capture("05_audio_artists")

        XCTAssertTrue(openArtistWithSeveralAlbums(count: artistCount), "No artist with more than one album")
        tapPagerTab(VLCAccessibilityIdentifier.albums)
        capture("06_audio_artist_albums")

        tapPagerTab(VLCAccessibilityIdentifier.songs)
        capture("07_audio_artist_songs")
    }

    func test04AudioAlbums() {
        openAudioCategory(VLCAccessibilityIdentifier.albums)
        let album = firstVisibleCell(VLCAccessibilityIdentifier.mediaCell)
        capture("08_audio_albums")

        album.tap()
        capture("09_audio_album")
    }

    func test05AudioTracks() {
        openAudioCategory(VLCAccessibilityIdentifier.songs)
        _ = firstVisibleCell(VLCAccessibilityIdentifier.mediaCell)
        capture("10_audio_tracks")
    }

    func test06AudioGenres() {
        openAudioCategory(VLCAccessibilityIdentifier.genres)
        let genre = firstVisibleCell(VLCAccessibilityIdentifier.mediaCell)
        capture("11_audio_genres")

        genre.tap()
        capture("12_audio_genre_tracks")
    }

    // MARK: - Browse

    func test07Browse() {
        tapTab(VLCAccessibilityIdentifier.localNetwork)
        let favorite = element(VLCAccessibilityIdentifier.favorite)
        capture("13_browse")

        favorite.tap()
        settle(3.0)
        capture("14_browse_directory")
    }

    func test08BrowseAddServer() {
        tapTab(VLCAccessibilityIdentifier.localNetwork)
        tap(element(VLCAccessibilityIdentifier.addServer))
        capture("15_browse_add_server")
    }

    // MARK: - Menu, settings and about

    func test09AppMenu() {
        tapTab(VLCAccessibilityIdentifier.video)
        tap(appMenuButton())
        _ = element(VLCAccessibilityIdentifier.openSettings)
        capture("16_app_menu")

        tap(element(VLCAccessibilityIdentifier.openSettings))
        capture("17_settings")
    }

    func test10About() {
        tapTab(VLCAccessibilityIdentifier.video)
        tap(appMenuButton())
        tap(element(VLCAccessibilityIdentifier.about))
        settle(2.0)
        capture("18_about")
    }

    // MARK: - Audio player

    func test11AudioPlayer() {
        startAudioPlayback()
        capture("19_audio_player")

        tap(element(VLCAccessibilityIdentifier.moreOptions))
        capture("20_audio_player_options")

        tap(element("equalizer"))
        capture("21_audio_player_equalizer")
    }

    func test12AudioMiniPlayer() {
        startAudioPlayback()
        tap(element(VLCAccessibilityIdentifier.closePlayback))
        capture("22_audio_mini_player")
    }

    // MARK: - Video player

    func test13VideoPlayer() {
        tapTab(VLCAccessibilityIdentifier.video)
        firstVisibleCell(VLCAccessibilityIdentifier.mediaCell).tap()
        let closeButton = app.descendants(matching: .any).matching(identifier: VLCAccessibilityIdentifier.closePlayback).firstMatch
        if !closeButton.waitForExistence(timeout: 5.0) {
            firstVisibleCell(VLCAccessibilityIdentifier.mediaCell).tap()
        }
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10.0))

        XCUIDevice.shared.orientation = .landscapeLeft
        let moreOptions = app.descendants(matching: .any).matching(identifier: VLCAccessibilityIdentifier.moreOptions).firstMatch
        setVideoControls(visible: false, moreOptions)
        capture("23_video_player")

        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)).doubleTap()
        capture("24_video_player_double_tap_seek", settleTime: 0.3)

        setVideoControls(visible: true, moreOptions)
        capture("25_video_player_hud", settleTime: 0.5)

        tap(moreOptions)
        capture("26_video_player_options")

        tap(element("playback"))
        capture("27_video_player_playback_speed")
    }

    // MARK: - On Air, radio and podcasts

    func test14OnAir() {
        tapTab(VLCAccessibilityIdentifier.onAir)
        _ = element(VLCAccessibilityIdentifier.railItem)
        capture("28_on_air", settleTime: 2.0)
    }

    func test15Radio() {
        tapTab(VLCAccessibilityIdentifier.onAir)
        tap(element(VLCAccessibilityIdentifier.onAirRadio))
        let country = element(VLCAccessibilityIdentifier.radioCountry)
        capture("29_radio", settleTime: 2.0)

        country.tap()
        _ = app.tables.cells.firstMatch.waitForExistence(timeout: 20.0)
        capture("30_radio_stations", settleTime: 3.0)
    }

    func test15RadioCountries() {
        tapTab(VLCAccessibilityIdentifier.onAir)
        tap(element(VLCAccessibilityIdentifier.onAirRadio))
        tap(element(VLCAccessibilityIdentifier.radioAllCountries))
        _ = app.tables.cells.firstMatch.waitForExistence(timeout: 20.0)
        capture("31_radio_countries")
    }

    func test16Podcasts() {
        tapTab(VLCAccessibilityIdentifier.onAir)
        tap(element(VLCAccessibilityIdentifier.onAirPodcasts))
        let show = element(VLCAccessibilityIdentifier.railItem)
        capture("32_podcasts", settleTime: 2.0)

        show.tap()
        let episode = app.cells.matching(identifier: VLCAccessibilityIdentifier.podcastEpisode).firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 10.0), "Missing episode")
        capture("33_podcast_show", settleTime: 2.0)

        var opened = false
        for _ in 0..<3 where !opened {
            episode.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            opened = wait(timeout: 3.0) { !episode.exists }
        }
        XCTAssertTrue(opened, "Episode detail did not open")
        capture("34_podcast_episode", settleTime: 2.0)
    }

    func test17PodcastDirectory() {
        openPodcastDirectory()
        let feed = element(VLCAccessibilityIdentifier.railItem, timeout: 30.0)
        capture("35_podcast_directory", settleTime: 3.0)

        feed.tap()
        capture("36_podcast_directory_feed", settleTime: 3.0)
    }

    func test17PodcastDirectoryLanguages() {
        openPodcastDirectory()
        tap(element(VLCAccessibilityIdentifier.podcastLanguage))
        _ = app.tables.cells.firstMatch.waitForExistence(timeout: 20.0)
        capture("37_podcast_directory_languages")
    }

    // MARK: - Helpers

    private func capture(_ name: String, settleTime: TimeInterval = 1.0) {
        settle(settleTime)

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        guard let outputPath = environment["VLC_SCREENSHOTS_OUTPUT"], !outputPath.isEmpty else {
            return
        }
        let outputURL = URL(fileURLWithPath: outputPath, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
            try screenshot.pngRepresentation.write(to: outputURL.appendingPathComponent(name + ".png"))
        } catch {
            XCTFail("Failed to write \(name): \(error)")
        }
    }

    private func settle(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    @discardableResult
    private func wait(timeout: TimeInterval, until condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return true
            }
            settle(0.25)
        }
        return condition()
    }

    private func element(_ identifier: String, timeout: TimeInterval = 10.0) -> XCUIElement {
        let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing element \(identifier)")
        return element
    }

    private func tap(_ element: XCUIElement) {
        wait(timeout: 5.0) { element.isHittable }
        element.tap()
    }

    private func visibleCells(_ identifier: String, limit: Int = Int.max) -> [XCUIElement] {
        let query = app.cells.matching(identifier: identifier)
        XCTAssertTrue(query.firstMatch.waitForExistence(timeout: 10.0), "Missing cell \(identifier)")
        let windowFrame = app.windows.firstMatch.frame
        let count = query.count
        var cells: [XCUIElement] = []
        var index = 0
        while index < count && index < 50 && cells.count < limit {
            let cell = query.element(boundBy: index)
            index += 1
            guard cell.exists else {
                continue
            }
            let frame = cell.frame
            if !frame.isEmpty && windowFrame.intersects(frame) && cell.isHittable {
                cells.append(cell)
            } else if !cells.isEmpty {
                break
            }
        }
        return cells
    }

    private func firstVisibleCell(_ identifier: String) -> XCUIElement {
        guard let cell = visibleCells(identifier, limit: 1).first else {
            XCTFail("No visible cell \(identifier)")
            return app.cells.matching(identifier: identifier).firstMatch
        }
        return cell
    }

    private func tabButton(_ identifier: String) -> XCUIElement {
        let tabBarButton = app.tabBars.buttons.matching(identifier: identifier).firstMatch
        if tabBarButton.exists {
            return tabBarButton
        }
        return app.buttons.matching(identifier: identifier).firstMatch
    }

    private func tapTab(_ identifier: String) {
        let button = tabButton(identifier)
        XCTAssertTrue(button.waitForExistence(timeout: 10.0), "Missing tab \(identifier)")
        button.tap()
    }

    private func openAudioCategory(_ identifier: String) {
        if tabButton(VLCAccessibilityIdentifier.audio).waitForExistence(timeout: 5.0) {
            tapTab(VLCAccessibilityIdentifier.audio)
            tapPagerTab(identifier)
        } else {
            tapTab(identifier)
        }
    }

    private func tapPagerTab(_ identifier: String) {
        let label = app.staticTexts.matching(identifier: identifier).firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 10.0), "Missing pager tab \(identifier)")
        tap(label)
    }

    private func openArtistWithSeveralAlbums(count: Int) -> Bool {
        for index in 0..<count {
            if index > 0 {
                app.launch()
                openAudioCategory(VLCAccessibilityIdentifier.artists)
            }
            let cells = visibleCells(VLCAccessibilityIdentifier.mediaCell)
            guard index < cells.count else {
                return false
            }
            cells[index].tap()

            let audioCategories = app.staticTexts.matching(identifier: VLCAccessibilityIdentifier.artists).firstMatch
            wait(timeout: 5.0) { !audioCategories.exists }
            if app.staticTexts.matching(identifier: VLCAccessibilityIdentifier.albums).firstMatch.waitForExistence(timeout: 2.0) {
                return true
            }
        }
        return false
    }

    private func appMenuButton() -> XCUIElement {
        let button = app.navigationBars.buttons.matching(identifier: VLCAccessibilityIdentifier.settings).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10.0), "Missing app menu")
        return button
    }

    private func startAudioPlayback() {
        openAudioCategory(VLCAccessibilityIdentifier.songs)
        firstVisibleCell(VLCAccessibilityIdentifier.mediaCell).tap()
        _ = element(VLCAccessibilityIdentifier.moreOptions)
        settle(2.0)
    }

    private func openPodcastDirectory() {
        tapTab(VLCAccessibilityIdentifier.onAir)
        tap(element(VLCAccessibilityIdentifier.onAirPodcasts))
        tap(element(VLCAccessibilityIdentifier.podcastAdd))
        tap(element(VLCAccessibilityIdentifier.podcastDirectory))
    }

    private func setVideoControls(visible: Bool, _ controlsElement: XCUIElement) {
        let isVisible = { controlsElement.exists && controlsElement.isHittable }
        if !visible && wait(timeout: 10.0, until: { !isVisible() }) {
            return
        }
        if isVisible() != visible {
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        }
        let settled = wait(timeout: 3.0) { isVisible() == visible }
        if visible {
            XCTAssertTrue(settled, "Video controls not shown")
        }
    }
}
