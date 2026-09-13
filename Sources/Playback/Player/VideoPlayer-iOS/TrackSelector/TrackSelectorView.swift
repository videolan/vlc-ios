/*****************************************************************************
 * TrackSelectorView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol TrackSelectorViewDelegate: AnyObject {
    func trackSelectorView(_ trackSelectorView: TrackSelectorView, didRequestLoadExternalFileForAudio audio: Bool)
    func trackSelectorViewDidRequestDownloadSubtitles(_ trackSelectorView: TrackSelectorView)
    func trackSelectorView(_ trackSelectorView: TrackSelectorView, didRequestDelayForAudio audio: Bool)
    func trackSelectorViewDidRequestDismissal(_ trackSelectorView: TrackSelectorView)
}

final class TrackSelectorView: UIView {
    private enum Tab: Int {
        case audio
        case subtitles
    }

    private enum RowItem {
        case off
        case track(TrackSelectorRow)
    }

    private enum Metrics {
        static let topInset: CGFloat = 12
        static let bottomInset: CGFloat = 12
        static let horizontalInset: CGFloat = 14
        static let segmentedControlToTable: CGFloat = 8
        static let tableToFooter: CGFloat = 6
        static let footerRowHeight: CGFloat = 52
        static let footerRowSpacing: CGFloat = 8
    }

    weak var delegate: TrackSelectorViewDelegate?

    private let playbackService = PlaybackService.sharedInstance()

    private var activeTab: Tab = .subtitles
    private var dualSubtitleMode = false

    private var audioRows: [TrackSelectorRow] = []
    private var subtitleRows: [TrackSelectorRow] = []
    private var items: [RowItem] = []
    private var hasPerformedInitialScroll = false
    private var footerConstraints: [NSLayoutConstraint] = []
    private var tableHeightConstraint: NSLayoutConstraint?

    // MARK: - Views

    private let backgroundContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            NSLocalizedString("AUDIO", comment: "").capitalized,
            NSLocalizedString("SUBTITLES", comment: "").capitalized
        ])
        let font = UIFont.preferredFont(forTextStyle: .headline)
        control.setTitleTextAttributes([.font: font], for: .normal)
        control.setTitleTextAttributes([.font: font], for: .selected)
        control.addTarget(self, action: #selector(didChangeTab), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.register(TrackSelectorCell.self, forCellReuseIdentifier: TrackSelectorCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var secondSubtitleButton: RoundedCornerPlayerButton = {
        let button = RoundedCornerPlayerButton(showsChevron: false)
        button.update(title: NSLocalizedString("SECOND_SUBTITLE", comment: ""))
        button.addTarget(self, action: #selector(didTapSecondSubtitle), for: .touchUpInside)
        return button
    }()

    private lazy var syncRow: RoundedCornerPlayerButton = {
        let row = RoundedCornerPlayerButton(showsChevron: true)
        row.setIcon(systemName: "metronome")
        row.addTarget(self, action: #selector(didTapSyncRow), for: .touchUpInside)
        return row
    }()

    private lazy var loadButton: RoundedCornerPlayerButton = {
        let button = RoundedCornerPlayerButton(showsChevron: true)
        button.setIcon(systemName: "doc.badge.plus")
        button.addTarget(self, action: #selector(didTapLoad), for: .touchUpInside)
        return button
    }()

    private lazy var downloadButton: RoundedCornerPlayerButton = {
        let button = RoundedCornerPlayerButton(showsChevron: true)
        button.setIcon(systemName: "arrow.down.doc")
        button.update(title: NSLocalizedString("BUTTON_DOWNLOAD", comment: ""))
        button.addTarget(self, action: #selector(didTapDownload), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        overrideUserInterfaceStyle = .dark

        setupLayout()
        rebuildData()
        dualSubtitleMode = playbackService.indexOfCurrentSecondaryVideoSubtitleTrack >= 0
        segmentedControl.selectedSegmentIndex = activeTab.rawValue
        applyTab()

        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(requestDismissal))
        swipeDownRecognizer.direction = .down
        addGestureRecognizer(swipeDownRecognizer)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(reduceTransparencyChanged),
                                       name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(playbackMetadataChanged),
                                       name: Notification.Name(VLCPlaybackServicePlaybackMetadataDidChange),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(requestDismissal),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidMoveOnToNextItem),
                                       object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let tableHeightConstraint = tableHeightConstraint,
           abs(tableHeightConstraint.constant - tableView.contentSize.height) > 0.5 {
            tableHeightConstraint.constant = tableView.contentSize.height
        }

        if !hasPerformedInitialScroll, tableView.bounds.height > 0, let indexPath = selectedIndexPath() {
            hasPerformedInitialScroll = true
            tableView.scrollToRow(at: indexPath, at: .none, animated: false)
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        requestDismissal()
        return true
    }

    // MARK: - Public

    func focusForAccessibility() {
        UIAccessibility.post(notification: .screenChanged, argument: segmentedControl)
    }

    // MARK: - Layout

    private func setupLayout() {
        backgroundContainer.roundCorners(radius: Self.cardCornerRadius)
        addSubview(backgroundContainer)
        installBackgroundEffect()

        addSubview(segmentedControl)
        addSubview(tableView)
        addSubview(loadButton)
        addSubview(downloadButton)
        addSubview(syncRow)
        addSubview(secondSubtitleButton)

        let inset = Metrics.horizontalInset
        let heightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = .defaultHigh
        tableHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            segmentedControl.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.topInset),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            segmentedControl.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.segmentedControlHeight),

            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: Metrics.segmentedControlToTable),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            heightConstraint,
        ])
    }

    private func layoutFooter() {
        NSLayoutConstraint.deactivate(footerConstraints)
        footerConstraints.removeAll()

        let isSubtitles = (activeTab == .subtitles)
        secondSubtitleButton.isHidden = !isSubtitles || subtitleRows.isEmpty
        downloadButton.isHidden = !isSubtitles

        if isSubtitles {
            footerConstraints = pairConstraints(left: secondSubtitleButton, right: syncRow)
                + pairConstraints(left: loadButton, right: downloadButton)
                + [
                    loadButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Metrics.bottomInset),
                    secondSubtitleButton.bottomAnchor.constraint(equalTo: loadButton.topAnchor,
                                                                 constant: -Metrics.footerRowSpacing),
                    tableView.bottomAnchor.constraint(equalTo: secondSubtitleButton.topAnchor,
                                                      constant: -Metrics.tableToFooter),
                ]
        } else {
            footerConstraints = pairConstraints(left: loadButton, right: syncRow)
                + [
                    loadButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Metrics.bottomInset),
                    tableView.bottomAnchor.constraint(equalTo: loadButton.topAnchor, constant: -Metrics.tableToFooter),
                ]
        }
        NSLayoutConstraint.activate(footerConstraints)
    }

    private func pairConstraints(left: UIView, right: UIView) -> [NSLayoutConstraint] {
        return [
            left.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalInset),
            left.trailingAnchor.constraint(equalTo: right.leadingAnchor, constant: -10),
            right.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalInset),
            left.widthAnchor.constraint(equalTo: right.widthAnchor),
            left.heightAnchor.constraint(equalToConstant: Metrics.footerRowHeight),
            right.heightAnchor.constraint(equalToConstant: Metrics.footerRowHeight),
            left.centerYAnchor.constraint(equalTo: right.centerYAnchor),
        ]
    }

    private func installBackgroundEffect() {
        backgroundContainer.subviews.forEach { $0.removeFromSuperview() }
        let effectView = UIView.makeOverlayBackgroundView()
        effectView.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainer.addSubview(effectView)
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            effectView.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor),
        ])
    }

    // MARK: - Data

    private func rebuildData() {
        audioRows = playbackService.audioTracks.enumerated().map {
            TrackSelectorRow(track: $0.element, ordinal: $0.offset + 1, kind: .audio)
        }
        subtitleRows = playbackService.textTracks.enumerated().map {
            TrackSelectorRow(track: $0.element, ordinal: $0.offset + 1, kind: .subtitle)
        }
    }

    private func rebuildItems() {
        switch activeTab {
        case .audio:
            items = [.off] + audioRows.map { .track($0) }
        case .subtitles:
            let tracks = subtitleRows.map { RowItem.track($0) }
            items = dualSubtitleMode ? tracks : [.off] + tracks
        }
    }

    private func reloadTable() {
        rebuildItems()
        tableView.reloadData()
        setNeedsLayout()
    }

    private func applyTab() {
        layoutFooter()

        loadButton.update(title: NSLocalizedString("LOAD_EXTERNAL", comment: ""))
        updateSecondSubtitleIcon()
        updateSyncSummary()
        reloadTable()
    }

    private func updateSecondSubtitleIcon() {
        secondSubtitleButton.setIcon(systemName: dualSubtitleMode ? "minus.circle.fill" : "plus.circle.fill")
    }

    private func updateSyncSummary() {
        let delayMs = (activeTab == .audio) ? playbackService.audioDelay : playbackService.subtitleDelay
        let summary: String
        if delayMs == 0 {
            summary = NSLocalizedString("NO_DELAY", comment: "")
        } else {
            summary = PlaybackDelayFormatter.string(forDelay: delayMs)
        }

        syncRow.update(title: NSLocalizedString("SYNC", comment: ""), summary: summary)
    }

    // MARK: - Selection

    private var currentSelectionIndex: Int {
        switch activeTab {
        case .audio:
            return playbackService.indexOfCurrentAudioTrack
        case .subtitles:
            return playbackService.indexOfCurrentPrimaryVideoSubtitleTrack
        }
    }

    private func selectionState(for row: TrackSelectorRow) -> Bool {
        return currentSelectionIndex == row.trackIndex
    }

    private var isOffSelected: Bool {
        switch activeTab {
        case .audio:
            return playbackService.indexOfCurrentAudioTrack == -1
        case .subtitles:
            return playbackService.indexOfCurrentPrimaryVideoSubtitleTrack == -1
                && playbackService.indexOfCurrentSecondaryVideoSubtitleTrack == -1
        }
    }

    private func selectedIndexPath() -> IndexPath? {
        let row = items.firstIndex {
            switch $0 {
            case .off:
                return isOffSelected
            case .track(let track):
                return track.trackIndex == currentSelectionIndex
            }
        }
        return row.map { IndexPath(row: $0, section: 0) }
    }

    private func assignment(for row: TrackSelectorRow) -> TrackSelectorAssignment {
        if playbackService.indexOfCurrentPrimaryVideoSubtitleTrack == row.trackIndex {
            return .primary
        }
        if playbackService.indexOfCurrentSecondaryVideoSubtitleTrack == row.trackIndex {
            return .secondary
        }
        return .none
    }

    private func applyOffSelection() {
        switch activeTab {
        case .audio:
            playbackService.disableAudio()
        case .subtitles:
            playbackService.disablePrimaryVideoSubtitle()
            playbackService.disableSecondaryVideoSubtitle()
        }
    }

    private func applyTrackSelection(_ row: TrackSelectorRow) {
        switch activeTab {
        case .audio:
            playbackService.selectAudioTrack(at: row.trackIndex)
        case .subtitles:
            playbackService.selectPrimaryVideoSubtitle(at: row.trackIndex)
            playbackService.disableSecondaryVideoSubtitle()
        }
    }

    // MARK: - Actions

    @objc private func didChangeTab() {
        activeTab = Tab(rawValue: segmentedControl.selectedSegmentIndex) ?? .audio
        applyTab()
    }

    @objc private func didTapSecondSubtitle() {
        if dualSubtitleMode {
            playbackService.disableSecondaryVideoSubtitle()
            dualSubtitleMode = false
        } else {
            dualSubtitleMode = true
        }
        updateSecondSubtitleIcon()
        reloadTable()
    }

    @objc private func didTapSyncRow() {
        delegate?.trackSelectorView(self, didRequestDelayForAudio: activeTab == .audio)
    }

    @objc private func didTapLoad() {
        delegate?.trackSelectorView(self, didRequestLoadExternalFileForAudio: activeTab == .audio)
    }

    @objc private func didTapDownload() {
        delegate?.trackSelectorViewDidRequestDownloadSubtitles(self)
    }

    @objc private func requestDismissal() {
        delegate?.trackSelectorViewDidRequestDismissal(self)
    }

    @objc private func playbackMetadataChanged() {
        rebuildData()
        applyTab()
    }

    @objc private func reduceTransparencyChanged() {
        installBackgroundEffect()
    }

    // MARK: - Helpers

    private static let segmentedControlHeight: CGFloat = 44
    private static let cardCornerRadius: CGFloat = 30
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension TrackSelectorView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackSelectorCell.identifier,
                                                       for: indexPath) as? TrackSelectorCell else {
            return UITableViewCell()
        }
        cell.delegate = self

        switch items[indexPath.row] {
        case .off:
            let offRow = TrackSelectorRow(trackIndex: -1,
                                          name: NSLocalizedString("TRACK_SELECTOR_OFF", comment: ""),
                                          isDerivedName: false,
                                          meta: nil,
                                          isSelected: isOffSelected)
            cell.configure(row: offRow, dualMode: false, assignment: .none)
        case .track(var row):
            let dual = (activeTab == .subtitles && dualSubtitleMode)
            row.isSelected = selectionState(for: row)
            let assign = dual ? assignment(for: row) : .none
            cell.configure(row: row, dualMode: dual, assignment: assign)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if activeTab == .subtitles && dualSubtitleMode {
            return
        }
        switch items[indexPath.row] {
        case .off:
            applyOffSelection()
        case .track(let row):
            applyTrackSelection(row)
        }
        reloadTable()
    }
}

// MARK: - TrackSelectorCellDelegate

extension TrackSelectorView: TrackSelectorCellDelegate {
    func trackSelectorCellDidTogglePrimary(_ cell: TrackSelectorCell) {
        togglePill(for: cell, primary: true)
    }

    func trackSelectorCellDidToggleSecondary(_ cell: TrackSelectorCell) {
        togglePill(for: cell, primary: false)
    }

    private func togglePill(for cell: TrackSelectorCell, primary: Bool) {
        guard let indexPath = tableView.indexPath(for: cell),
              case .track(let row) = items[indexPath.row] else {
            return
        }
        if primary {
            if playbackService.indexOfCurrentPrimaryVideoSubtitleTrack == row.trackIndex {
                playbackService.disablePrimaryVideoSubtitle()
            } else {
                playbackService.selectPrimaryVideoSubtitle(at: row.trackIndex)
            }
        } else {
            if playbackService.indexOfCurrentSecondaryVideoSubtitleTrack == row.trackIndex {
                playbackService.disableSecondaryVideoSubtitle()
            } else {
                playbackService.selectSecondaryVideoSubtitle(at: row.trackIndex)
            }
        }
        reloadTable()
    }
}
