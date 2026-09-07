/*****************************************************************************
 * PodcastEpisodeDetailViewController.swift
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

class PodcastEpisodeDetailViewController: UIViewController {
    private static let horizontalPadding: CGFloat = 20
    private static let verticalGap: CGFloat = 14
    private static let artworkSize: CGFloat = 180
    private static let artworkRadius: CGFloat = 14

    private let show: PodcastShow
    private let episodeId: String
    private let store = PodcastStore.shared

    private var episode: PodcastEpisode

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let artworkView = PodcastArtworkView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .title3).semibolded
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredCustomFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let notesTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private let playBarButton = UIBarButtonItem()
    private let overflowButton = UIBarButtonItem()

    private var cachedNotes: NSMutableAttributedString?
    private var cachedNotesSource: String?

    private var notesTopToAuthorConstraint: NSLayoutConstraint!
    private var notesTopToMetaConstraint: NSLayoutConstraint!

    init(episode: PodcastEpisode, show: PodcastShow) {
        self.episode = episode
        self.episodeId = episode.id
        self.show = show
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never

        setupUI()
        setupNavigationBarButtons()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(applyTheme),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(refresh),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidStart),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(refresh),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidPause),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(refresh),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidResume),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(refresh),
                                       name: Notification.Name(VLCPlaybackServicePlaybackDidStop),
                                       object: nil)

        store.addObserver(self)
        applyTheme()
        refresh()
    }

    deinit {
        store.removeObserver(self)
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(artworkView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(metaLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(notesTextView)

        let padding = PodcastEpisodeDetailViewController.horizontalPadding
        let gap = PodcastEpisodeDetailViewController.verticalGap

        notesTopToAuthorConstraint = notesTextView.topAnchor.constraint(equalTo: authorLabel.bottomAnchor,
                                                                       constant: gap)
        notesTopToMetaConstraint = notesTextView.topAnchor.constraint(equalTo: metaLabel.bottomAnchor,
                                                                      constant: gap)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            artworkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            artworkView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            artworkView.widthAnchor.constraint(equalToConstant: PodcastEpisodeDetailViewController.artworkSize),
            artworkView.heightAnchor.constraint(equalToConstant: PodcastEpisodeDetailViewController.artworkSize),

            titleLabel.topAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: gap),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: gap),
            metaLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            metaLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            authorLabel.topAnchor.constraint(equalTo: metaLabel.bottomAnchor, constant: 4),
            authorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            notesTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
    }

    @objc private func refresh() {
        if let updated = store.episodes(forShowId: show.id).first(where: { $0.id == episodeId }) {
            episode = updated
        }

        artworkView.configure(name: show.name,
                              artworkURL: episode.artworkURL ?? show.artworkURL,
                              cornerRadius: PodcastEpisodeDetailViewController.artworkRadius,
                              fontSize: 48)

        titleLabel.text = episode.title

        var metaComponents = [episode.date]
        if let duration = episode.durationText {
            metaComponents.append(duration)
        }
        if let remaining = episode.remainingText {
            metaComponents.append(String(format: NSLocalizedString("PODCAST_TIME_LEFT", comment: ""), remaining))
        }
        metaLabel.text = metaComponents.joined(separator: " · ")

        let author = episode.author?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasAuthor = !(author?.isEmpty ?? true)
        authorLabel.text = author
        authorLabel.isHidden = !hasAuthor
        notesTopToAuthorConstraint.isActive = hasAuthor
        notesTopToMetaConstraint.isActive = !hasAuthor

        updatePlayBarButton()
        updateOverflowMenu()
        updateNotes()
    }

    private func setupNavigationBarButtons() {
        if #available(iOS 26.0, *) {
            overflowButton.image = UIImage(systemName: "ellipsis")
        } else {
            overflowButton.image = UIImage(named: "EllipseCircle")
        }
        overflowButton.accessibilityLabel = NSLocalizedString("BUTTON_MENU", comment: "")
        if #unavailable(iOS 14.0) {
            overflowButton.target = self
            overflowButton.action = #selector(showOverflowActionSheet)
        }

        playBarButton.target = self
        playBarButton.action = #selector(didTapPlay)
        playBarButton.accessibilityLabel = NSLocalizedString("PLAY_PAUSE_BUTTON", comment: "")

        navigationItem.rightBarButtonItems = [playBarButton, overflowButton]
    }

    private func updatePlayBarButton() {
        let isPlaying = store.isPlaying && store.nowPlayingEpisodeId == episodeId
        guard #available(iOS 13.0, *) else {
            playBarButton.image = UIImage(named: isPlaying ? "pauseIcon" : "iconPlay")
            return
        }
        playBarButton.image = UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")
    }

    private func updateOverflowMenu() {
        guard #available(iOS 14.0, *) else {
            return
        }
        overflowButton.menu = overflowActions.menu()
    }

    private var overflowActions: [PodcastMenuAction] {
        var actions = [
            PodcastMenuAction(title: NSLocalizedString("MARK_AS_PLAYED", comment: ""),
                              imageName: "checkmark.circle") { [weak self] in self?.markAsPlayed() },
            PodcastMenuAction(title: NSLocalizedString("APPEND_TO_QUEUE_LABEL", comment: ""),
                              imageName: "text.append") { [weak self] in self?.appendToQueue() },
            PodcastMenuAction(title: NSLocalizedString("PODCAST_EXPORT_MEDIA_FILE", comment: ""),
                              imageName: "arrow.down.doc",
                              isEnabled: episode.downloaded) { [weak self] in self?.shareDownload() },
            PodcastMenuAction(title: NSLocalizedString("PODCAST_OPEN_LINK", comment: ""),
                              imageName: "safari", isEnabled: false) {}
        ]

        if episode.downloaded {
            actions.append(PodcastMenuAction(title: NSLocalizedString("PODCAST_DELETE_DOWNLOAD_TITLE", comment: ""),
                                             imageName: "trash",
                                             isDestructive: true) { [weak self] in self?.confirmDeleteDownload() })
        } else {
            actions.append(PodcastMenuAction(title: NSLocalizedString("PODCAST_EPISODE_DOWNLOAD", comment: ""),
                                             imageName: "arrow.down.circle") { [weak self] in self?.download() })
        }
        return actions
    }

    @objc private func showOverflowActionSheet(_ sender: UIBarButtonItem) {
        overflowActions.presentActionSheet(title: episode.title, from: sender, in: self)
    }

    private func updateNotes() {
        let colors = PresentationTheme.current.colors
        notesTextView.tintColor = colors.orangeUI
        notesTextView.linkTextAttributes = [.foregroundColor: colors.orangeUI]

        guard let notes = episode.notesHTML, !notes.isEmpty else {
            cachedNotes = nil
            cachedNotesSource = nil
            notesTextView.attributedText = nil
            notesTextView.isHidden = true
            return
        }

        let attributedNotes = formattedNotes(for: notes)
        attributedNotes.addAttribute(.foregroundColor, value: colors.cellTextColor,
                                     range: NSRange(location: 0, length: attributedNotes.length))
        notesTextView.attributedText = attributedNotes

        notesTextView.isHidden = false
    }

    // Parsing runs on every playback notification and theme change otherwise, and both the HTML
    // importer and the markdown parser are expensive enough to keep off those paths.
    private func formattedNotes(for notes: String) -> NSMutableAttributedString {
        if let cachedNotes = cachedNotes, cachedNotesSource == notes {
            return cachedNotes
        }

        let attributedNotes = attributedNotes(from: notes)
        let range = NSRange(location: 0, length: attributedNotes.length)
        let bodyFont = UIFont.preferredCustomFont(forTextStyle: .callout)

        if #available(iOS 15.0, *) {
            attributedNotes.enumerateAttribute(.inlinePresentationIntent, in: range, options: []) { value, subrange, _ in
                guard let rawValue = (value as? NSNumber)?.uintValue else {
                    return
                }
                let intent = InlinePresentationIntent(rawValue: rawValue)
                var traits: UIFontDescriptor.SymbolicTraits = []
                if intent.contains(.stronglyEmphasized) {
                    traits.insert(.traitBold)
                }
                if intent.contains(.emphasized) {
                    traits.insert(.traitItalic)
                }
                guard let descriptor = bodyFont.fontDescriptor.withSymbolicTraits(traits) else {
                    return
                }
                attributedNotes.addAttribute(.font, value: UIFont(descriptor: descriptor, size: 0), range: subrange)
            }
        }

        attributedNotes.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            let traits = (value as? UIFont)?.fontDescriptor.symbolicTraits ?? []
            guard let descriptor = bodyFont.fontDescriptor.withSymbolicTraits(traits) else {
                attributedNotes.addAttribute(.font, value: bodyFont, range: subrange)
                return
            }
            attributedNotes.addAttribute(.font, value: UIFont(descriptor: descriptor, size: 0), range: subrange)
        }

        attributedNotes.enumerateAttribute(.paragraphStyle, in: range, options: []) { value, subrange, _ in
            let style = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle
                ?? NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.55
            attributedNotes.addAttribute(.paragraphStyle, value: style, range: subrange)
        }

        cachedNotes = attributedNotes
        cachedNotesSource = notes
        return attributedNotes
    }

    // Feeds put HTML in content:encoded and, within CDATA, in description and itunes:summary alike.
    // Anything without tags or entities is plain text that the publisher may have written as markdown.
    private func attributedNotes(from notes: String) -> NSMutableAttributedString {
        if notes.range(of: "<[^>]+>|&[a-zA-Z]+;|&#[0-9]+;", options: .regularExpression) != nil,
           let data = notes.data(using: .utf8),
           let html = try? NSMutableAttributedString(data: data,
                                                     options: [.documentType: NSAttributedString.DocumentType.html,
                                                               .characterEncoding: String.Encoding.utf8.rawValue],
                                                     documentAttributes: nil) {
            return html
        }

        guard #available(iOS 15.0, *) else {
            return NSMutableAttributedString(string: notes)
        }

        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard let markdown = try? AttributedString(markdown: notes, options: options) else {
            return NSMutableAttributedString(string: notes)
        }
        return NSMutableAttributedString(attributedString: NSAttributedString(markdown))
    }

    @objc private func didTapPlay() {
        if store.nowPlayingEpisodeId == episodeId {
            store.togglePlayPause()
        } else {
            store.playEpisode(episodeId: episodeId, showId: show.id)
        }
    }

    private func markAsPlayed() {
        store.markEpisodeAsPlayed(episodeId: episodeId, showId: show.id)
        refresh()
    }

    private func appendToQueue() {
        store.appendEpisodeToQueue(episodeId: episodeId, showId: show.id)
    }

    private func download() {
        store.downloadEpisode(episodeId: episodeId, showId: show.id)
        refresh()
    }

    private func shareDownload() {
        guard let fileURL = store.downloadedFileURL(episodeId: episodeId, showId: show.id) else {
            return
        }

        let stagedURL = namedCopy(of: fileURL)
        let activityViewController = UIActivityViewController(activityItems: [stagedURL ?? fileURL],
                                                              applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = overflowButton
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            guard let stagedURL = stagedURL else {
                return
            }
            try? FileManager.default.removeItem(at: stagedURL.deletingLastPathComponent())
        }
        present(activityViewController, animated: true)
    }

    private func namedCopy(of fileURL: URL) -> URL? {
        let fileManager = FileManager.default
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("PodcastShare")
        let fileExtension = URL(string: fileURL.lastPathComponent)?.pathExtension ?? fileURL.pathExtension
        let destination = directory.appendingPathComponent("\(show.name) - \(episode.title)")
            .appendingPathExtension(fileExtension)

        do {
            try? fileManager.removeItem(at: directory)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try fileManager.linkItem(at: fileURL, to: destination)
        } catch {
            APLog("podcast share: failed to stage \(fileURL.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
        return destination
    }

    private func confirmDeleteDownload() {
        confirmPodcastDownloadDeletion { [weak self] in
            guard let self = self else { return }
            self.store.deleteDownloadedEpisode(episodeId: self.episodeId, showId: self.show.id)
            self.refresh()
        }
    }

    @objc private func applyTheme() {
        let colors = PresentationTheme.current.colors
        view.backgroundColor = colors.background
        scrollView.backgroundColor = colors.background
        titleLabel.textColor = colors.cellTextColor
        metaLabel.textColor = colors.cellDetailTextColor
        authorLabel.textColor = colors.cellDetailTextColor
        updateOverflowMenu()
        updateNotes()
    }
}

// MARK: - MediaLibraryBaseModelObserver

extension PodcastEpisodeDetailViewController: MediaLibraryBaseModelObserver {
    func mediaLibraryBaseModelReloadView() {
        refresh()
    }
}
