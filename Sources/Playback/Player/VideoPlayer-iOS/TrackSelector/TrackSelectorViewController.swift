/*****************************************************************************
 * TrackSelectorViewController.swift
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

protocol TrackSelectorViewControllerDelegate: AnyObject {
    func trackSelector(_ controller: TrackSelectorViewController, didRequestLoadExternalFileForAudio audio: Bool)
    func trackSelectorDidRequestDownloadSubtitles(_ controller: TrackSelectorViewController)
    func trackSelectorDidRequestSpeedAndSync(_ controller: TrackSelectorViewController)
}

class TrackSelectorViewController: UIViewController {
    private enum Tab: Int {
        case audio
        case subtitles
    }

    private enum RowItem {
        case off
        case track(TrackSelectorRow)
    }

    weak var delegate: TrackSelectorViewControllerDelegate?

    private let playbackService = PlaybackService.sharedInstance()

    private var activeTab: Tab = .subtitles
    private var dualSubtitleMode = false

    private var audioRows: [TrackSelectorRow] = []
    private var subtitleRows: [TrackSelectorRow] = []
    private var items: [RowItem] = []
    private var hasPerformedInitialScroll = false

    // MARK: - Views

    private let backgroundContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlayPrimaryTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 26)
            button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        } else {
            button.setImage(UIImage(named: "close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        button.tintColor = PresentationTheme.currentExcludingWhite.colors.overlaySecondaryTextColor
        button.accessibilityLabel = NSLocalizedString("BUTTON_CLOSE", comment: "")
        button.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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

    private var footerConstraints: [NSLayoutConstraint] = []

    init(delegate: TrackSelectorViewControllerDelegate?) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        configureSheetPresentation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        setupLayout()
        rebuildData()
        dualSubtitleMode = playbackService.indexOfCurrentSecondaryVideoSubtitleTrack >= 0
        segmentedControl.selectedSegmentIndex = activeTab.rawValue
        applyTab()

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
                                       selector: #selector(playbackItemChanged),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidMoveOnToNextItem),
                                       object: nil)
    }

    @objc private func playbackMetadataChanged() {
        rebuildData()
        applyTab()
    }

    @objc private func playbackItemChanged() {
        dismiss(animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasPerformedInitialScroll, let indexPath = selectedIndexPath() {
            hasPerformedInitialScroll = true
            tableView.scrollToRow(at: indexPath, at: .none, animated: false)
        }
    }

    private func configureSheetPresentation() {
#if !os(visionOS)
        if #available(iOS 15.0, *) {
            modalPresentationStyle = .pageSheet
            if let sheet = sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 30
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
        } else if #available(iOS 13.0, *) {
            // The native card sheet is swipe-to-dismiss out of the box.
            modalPresentationStyle = .pageSheet
        } else {
            modalPresentationStyle = .formSheet
        }
#else
        modalPresentationStyle = .pageSheet
#endif
    }

    private func setupLayout() {
        backgroundContainer.roundCorners(radius: 30)
        backgroundContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(backgroundContainer)
        installBackgroundEffect()

        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        view.addSubview(loadButton)
        view.addSubview(downloadButton)
        view.addSubview(syncRow)
        view.addSubview(secondSubtitleButton)

        let guide = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
        ])

        if #available(iOS 13.0, *) {
            segmentedControl.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16).isActive = true
        } else {
            view.addSubview(titleLabel)
            view.addSubview(closeButton)
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 14),
                titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

                closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
                closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                closeButton.widthAnchor.constraint(equalToConstant: 30),
                closeButton.heightAnchor.constraint(equalToConstant: 30),
                closeButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),

                segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            ])
        }
    }

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
    }

    @objc private func didChangeTab() {
        activeTab = Tab(rawValue: segmentedControl.selectedSegmentIndex) ?? .audio
        applyTab()
    }

    private func applyTab() {
        let isSubtitles = (activeTab == .subtitles)
        if #unavailable(iOS 13.0) {
            titleLabel.text = isSubtitles ? NSLocalizedString("SUBTITLES", comment: "").capitalized
                                          : NSLocalizedString("AUDIO", comment: "").capitalized
        }

        layoutFooter()

        loadButton.update(title: NSLocalizedString("LOAD_EXTERNAL", comment: ""))
        updateSecondSubtitleIcon()
        updateSyncSummary()
        reloadTable()
    }

    private func layoutFooter() {
        NSLayoutConstraint.deactivate(footerConstraints)
        footerConstraints.removeAll()

        let isSubtitles = (activeTab == .subtitles)
        secondSubtitleButton.isHidden = !isSubtitles || subtitleRows.isEmpty
        downloadButton.isHidden = !isSubtitles

        let bottom = view.bottomAnchor
        if isSubtitles {
            footerConstraints = pairConstraints(left: secondSubtitleButton, right: syncRow)
                + pairConstraints(left: loadButton, right: downloadButton)
                + [
                    loadButton.bottomAnchor.constraint(equalTo: bottom, constant: -16),
                    secondSubtitleButton.bottomAnchor.constraint(equalTo: loadButton.topAnchor, constant: -12),
                    tableView.bottomAnchor.constraint(equalTo: secondSubtitleButton.topAnchor, constant: -8),
                ]
        } else {
            footerConstraints = pairConstraints(left: loadButton, right: syncRow)
                + [
                    loadButton.bottomAnchor.constraint(equalTo: bottom, constant: -16),
                    tableView.bottomAnchor.constraint(equalTo: loadButton.topAnchor, constant: -8),
                ]
        }
        NSLayoutConstraint.activate(footerConstraints)
    }

    private func pairConstraints(left: UIView, right: UIView) -> [NSLayoutConstraint] {
        return [
            left.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            left.trailingAnchor.constraint(equalTo: right.leadingAnchor, constant: -10),
            right.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            left.widthAnchor.constraint(equalTo: right.widthAnchor),
            left.heightAnchor.constraint(equalToConstant: 56),
            right.heightAnchor.constraint(equalToConstant: 56),
            left.centerYAnchor.constraint(equalTo: right.centerYAnchor),
        ]
    }

    private func updateSecondSubtitleIcon() {
        secondSubtitleButton.setIcon(systemName: dualSubtitleMode ? "minus.circle.fill" : "plus.circle.fill")
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

    private func updateSyncSummary() {
        let delayMs = (activeTab == .audio) ? playbackService.audioDelay : playbackService.subtitleDelay
        let summary: String
        if delayMs == 0 {
            summary = NSLocalizedString("NO_DELAY", comment: "")
        } else {
            let delay = Self.numberFormatter.string(from: NSNumber(value: delayMs / 1000.0)) ?? "0.0"
            summary = String(format: NSLocalizedString("DELAY_FORMAT", comment: ""), delay)
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

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func didTapSyncRow() {
        delegate?.trackSelectorDidRequestSpeedAndSync(self)
    }

    @objc private func didTapLoad() {
        delegate?.trackSelector(self, didRequestLoadExternalFileForAudio: activeTab == .audio)
    }

    @objc private func didTapDownload() {
        delegate?.trackSelectorDidRequestDownloadSubtitles(self)
    }

    private func installBackgroundEffect() {
        backgroundContainer.subviews.forEach { $0.removeFromSuperview() }
        let effectView = makeSheetBackgroundView()
        effectView.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainer.addSubview(effectView)
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            effectView.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor),
        ])
    }

    private func makeSheetBackgroundView() -> UIView {
        if UIAccessibility.isReduceTransparencyEnabled {
            let view = UIView()
            view.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
            return view
        }

#if !os(visionOS)
        if #available(iOS 26.0, *) {
            return UIVisualEffectView(effect: UIGlassEffect())
        }
#endif

        let style: UIBlurEffect.Style
        if #available(iOS 13.0, *) {
            style = .systemChromeMaterialDark
        } else {
            style = .dark
        }
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    @objc private func reduceTransparencyChanged() {
        installBackgroundEffect()
    }

    // MARK: - Helpers

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

extension TrackSelectorViewController: UITableViewDataSource, UITableViewDelegate {
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

extension TrackSelectorViewController: TrackSelectorCellDelegate {
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
