/*****************************************************************************
 * TrackSelectorView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2021 VideoLAN. All rights reserved.
 * Copyright © 2021 Videolabs
 *
 * Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
 *
 * Refer to the COPYING file of the official project for license.
*****************************************************************************/

enum TrackSelectorSwitchingMode {
    case tracks
    case chapters
}

class TrackSelectorView: UIView {
    private lazy var playbackService = PlaybackService.sharedInstance()

    private let tableView: UITableView = UITableView()

    var switching: TrackSelectorSwitchingMode = .tracks {
        didSet {
            segmentedControl.selectedSegmentIndex = switching == .tracks ? 0 : 1
        }
    }

    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: [
            UIImage(named: "iconSubtitle") ?? NSLocalizedString("AUDIO", comment: ""),
            UIImage(named: "iconChapters") ?? NSLocalizedString("VIDEO", comment: "")
        ])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueDidChange), for: .valueChanged)
        segmentedControl.setContentHuggingPriority(.required, for: .horizontal)
        segmentedControl.setContentCompressionResistancePriority(.required, for: .vertical)
        return segmentedControl
    }()
    var parentViewController: UIViewController?

    private lazy var isRightToLeft: Bool = {
        UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
    }()

    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        setupTableView()
        setupConstraints()
        setupTheme()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder: NSCoder) not implemented")
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(tableView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func setupTheme() {
        backgroundColor = PresentationTheme.darkTheme.colors.background
        tableView.backgroundColor = PresentationTheme.darkTheme.colors.background
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = PresentationTheme.darkTheme.colors.orangeUI
        } else {
            segmentedControl.tintColor = PresentationTheme.darkTheme.colors.orangeUI
        }
    }

    // MARK: - Public methods
    func update() {
        switch switching {
        case .tracks:
            if !hasMultipleAudioTracks() && !hasVideoSubtitles() {
                switching = .chapters
            }
        case .chapters:
            if !hasMultitpleTitles() && !hasMultipleChapters() {
                switching = .tracks
            }
        }
        segmentedControl.setEnabled(hasMultipleAudioTracks() || hasVideoSubtitles(), forSegmentAt: 0)
        segmentedControl.setEnabled(hasMultitpleTitles() || hasMultipleChapters(), forSegmentAt: 1)
        tableView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - Private helpers
    private func hasMultipleAudioTracks() -> Bool {
        return playbackService.numberOfAudioTracks > 2
    }

    private func hasVideoSubtitles() -> Bool {
        return playbackService.numberOfVideoSubtitlesIndexes >= 1
    }

    private func hasMultitpleTitles() -> Bool {
        return playbackService.numberOfTitles > 1
    }

    private func hasMultipleChapters() -> Bool {
        return playbackService.numberOfChaptersForCurrentTitle > 1
    }

    // MARK: - Event handlers
    @objc private func segmentedControlValueDidChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            switching = .tracks
        case 1:
            switching = .chapters
        default:
            break
        }
        update()
    }
}

// MARK: - PopupViewAccessoryViewDelegate

extension TrackSelectorView: PopupViewAccessoryViewsDelegate {
    func popupViewAccessoryView(_ popupView: PopupView) -> [UIView] {
        return [segmentedControl]
    }
}

// MARK: - TableView Delegate / DataSource

extension TrackSelectorView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 0

        switch switching {
        case .tracks:
            if hasMultipleAudioTracks() {
                sections += 1
            }
            if hasVideoSubtitles() {
                sections += 1
            }
        case .chapters:
            if hasMultitpleTitles() {
                sections += 1
            }
            if hasMultipleChapters() {
                sections += 1
            }
        }

        return sections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch switching {
        case .tracks:
            if hasMultipleAudioTracks() && section == 0 {
                return playbackService.numberOfAudioTracks
            }
            return playbackService.numberOfVideoSubtitlesIndexes
        case .chapters:
            if hasMultitpleTitles() && section == 0 {
                return playbackService.numberOfTitles
            }
            return playbackService.numberOfChaptersForCurrentTitle
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch switching {
        case .tracks:
            if hasMultipleAudioTracks() && section == 0 {
                return NSLocalizedString("CHOOSE_AUDIO_TRACK", comment: "")
            }
            if hasVideoSubtitles() {
                return NSLocalizedString("CHOOSE_SUBTITLE_TRACK", comment: "")
            }
        case .chapters:
            if hasMultitpleTitles() && section == 0 {
                return NSLocalizedString("CHOOSE_TITLE", comment: "")
            }
            if hasMultipleChapters() {
                return NSLocalizedString("CHOOSE_CHAPTER", comment: "")
            }
        }

        return NSLocalizedString("UNKNOWN_TRACK_TYPE", comment: "")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

        let section = indexPath.section
        let row = indexPath.row

        cell.backgroundColor = PresentationTheme.darkTheme.colors.cellBackgroundA
        cell.textLabel?.textColor = PresentationTheme.darkTheme.colors.cellTextColor

        switch switching {
        case .tracks:
            var trackName: String
            if hasMultipleAudioTracks() && section == 0 {
                if playbackService.indexOfCurrentAudioTrack == row {
                    cell.textLabel?.textColor = PresentationTheme.darkTheme.colors.orangeUI
                }
                trackName = playbackService.audioTrackName(at: row)
            } else {
                if playbackService.indexOfCurrentSubtitleTrack == row {
                    cell.textLabel?.textColor = PresentationTheme.darkTheme.colors.orangeUI
                }
                trackName = playbackService.videoSubtitleName(at: row)
            }
            if trackName == "Disable" {
                cell.textLabel?.text = NSLocalizedString("DISABLE_LABEL", comment: "")
            } else {
                cell.textLabel?.text = trackName
            }
        case .chapters:
            if hasMultitpleTitles() && section == 0 {
                let description = playbackService.titleDescriptionsDict(at: row)
                if let name = description[VLCTitleDescriptionName],
                   let duration = VLCTime(number: description[VLCTitleDescriptionDuration] as? NSNumber).stringValue {
                    cell.textLabel?.text = isRightToLeft ? "(\(duration)) \(name)" : "\(name) (\(duration))"
                }
                if playbackService.indexOfCurrentTitle == row {
                    cell.textLabel?.textColor = PresentationTheme.darkTheme.colors.orangeUI
                }
            } else {
                let description = playbackService.chapterDescriptionsDict(at: row)
                if let name = description[VLCChapterDescriptionName],
                   let duration = VLCTime(number: description[VLCChapterDescriptionDuration] as? NSNumber).stringValue {
                    cell.textLabel?.text = isRightToLeft ? "(\(duration)) \(name)" : "\(name) (\(duration))"
                }
                if playbackService.indexOfCurrentChapter == row {
                    cell.textLabel?.textColor = PresentationTheme.darkTheme.colors.orangeUI
                }
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let section = indexPath.section
        let row = indexPath.row

        switch switching {
        case .tracks:
            if hasMultipleAudioTracks() && section == 0 {
                playbackService.selectAudioTrack(at: row)
            } else if row < playbackService.numberOfVideoSubtitlesIndexes - 1 {
                playbackService.selectVideoSubtitle(at: row)
            } else {
                if let parentViewController = parentViewController as? VideoPlayerViewController {
                    parentViewController.downloadMoreSPU()
                }
            }
        case .chapters:
            if hasMultitpleTitles() && section == 0 {
                playbackService.selectTitle(at: row)
            } else {
                playbackService.selectChapter(at: row)
            }
        }
        tableView.reloadData()
    }
}
