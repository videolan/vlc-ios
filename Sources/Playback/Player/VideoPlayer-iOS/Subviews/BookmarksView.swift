/*****************************************************************************
 * BookmarksView.swift
 *
 * Copyright © 2022-2026 VLC authors and VideoLAN
 * Copyright © 2022-2026 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol BookmarksViewDelegate: AnyObject {
    func bookmarksViewGetCurrentPlayingMedia() -> VLCMLMedia?
    func bookmarksViewDidSelectBookmark(value: Float)
    func bookmarksViewDisplayRenameAlert(_ bookmarksView: BookmarksView, index: Int)
    func bookmarksViewDisplayDeleteAlert(_ bookmarksView: BookmarksView, index: Int)
    func bookmarksViewDidRequestDismissal()
}

class BookmarksView: UIView {
    private let backgroundView = OverlayCardBackgroundView()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = PresentationTheme.currentExcludingWhite.colors.overlayPrimaryTextColor
        label.text = NSLocalizedString("BOOKMARKS_TITLE", comment: "")
        label.accessibilityTraits = .header
        return label
    }()
    private let bookmarksTableView = UITableView()
    private let bookmarksTableViewCellReuseIdentifier = "bookmarksTableViewCellReuseIdentifier"
    private var tableHeightConstraint: NSLayoutConstraint?

    weak var delegate: BookmarksViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        overrideUserInterfaceStyle = .dark
        addSubview(backgroundView)
        addSubview(titleLabel)
        setupTable()

        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(requestDismissal))
        swipeDownRecognizer.direction = .down
        addGestureRecognizer(swipeDownRecognizer)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestDismissal),
                                               name: Notification.Name(VLCPlaybackServicePlaybackDidMoveOnToNextItem),
                                               object: nil)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bookmarksTableView.layoutIfNeeded()

        if let tableHeightConstraint = tableHeightConstraint,
           abs(tableHeightConstraint.constant - bookmarksTableView.contentSize.height) > 0.5 {
            tableHeightConstraint.constant = bookmarksTableView.contentSize.height
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        requestDismissal()
        return true
    }

    func focusForAccessibility() {
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    private func setupTable() {
        addSubview(bookmarksTableView)
        bookmarksTableView.delegate = self
        bookmarksTableView.dataSource = self
        bookmarksTableView.register(UITableViewCell.self, forCellReuseIdentifier: bookmarksTableViewCellReuseIdentifier)
        bookmarksTableView.backgroundColor = .clear
        bookmarksTableView.separatorStyle = .none
        bookmarksTableView.rowHeight = UITableView.automaticDimension
        bookmarksTableView.estimatedRowHeight = 44
        setupConstraints()
    }

    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bookmarksTableView.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = bookmarksTableView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = .defaultHigh
        tableHeightConstraint = heightConstraint
        let constraints = [
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),

            bookmarksTableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            bookmarksTableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            bookmarksTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            bookmarksTableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            heightConstraint
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc private func requestDismissal() {
        delegate?.bookmarksViewDidRequestDismissal()
    }

    func deleteBookmarkAt(row: Int) {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                if bookmarks.count > row {
                    currentMedia.removeBookmark(atTime: bookmarks[row].time)
                    guard bookmarks.count > 1 else {
                        requestDismissal()
                        return
                    }
                    bookmarksTableView.reloadData()
                    setNeedsLayout()
                }
            }
        }
    }

    func renameBookmarkAt(name: String, row: Int) {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                if bookmarks.count > row {
                    if name.isEmpty {
                        var newName = String()
                        let time = VLCTime(number: NSNumber.init(value: bookmarks[row].time)).stringValue
                        newName = NSLocalizedString("BOOKMARK_DEFAULT_NAME", comment: "") + " " + time
                        bookmarks[row].name = newName
                    } else {
                        bookmarks[row].name = name
                    }
                    bookmarksTableView.reloadData()
                    setNeedsLayout()
                }
            }
        }
    }

    func getBookmarkNameAt(row: Int) -> String {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                return bookmarks[row].name
            }
        }
        return ""
    }
}

extension BookmarksView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteLabel = NSLocalizedString("BUTTON_DELETE", comment: "")
        let deleteAction = UIContextualAction(style: .destructive, title: deleteLabel, handler: { _, _, completion in
            self.delegate?.bookmarksViewDisplayDeleteAlert(self, index: indexPath.row)
            completion(false)
        })

        deleteAction.image = UIImage(named: "delete")?.withRenderingMode(.alwaysTemplate)

        let renameLabel = NSLocalizedString("BUTTON_RENAME", comment: "")
        let renameAction = UIContextualAction(style: .normal, title: renameLabel, handler: { _, _, completion in
            self.delegate?.bookmarksViewDisplayRenameAlert(self, index: indexPath.row)
            completion(true)
        })

        renameAction.backgroundColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        renameAction.image = UIImage(named: "rename")?.withRenderingMode(.alwaysTemplate)

        return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let renameAction = UIAction(title: NSLocalizedString("BUTTON_RENAME", comment: ""),
                                        image: UIImage(named: "rename")?.withRenderingMode(.alwaysTemplate)) { _ in
                self.delegate?.bookmarksViewDisplayRenameAlert(self, index: indexPath.row)
            }
            let deleteAction = UIAction(title: NSLocalizedString("BUTTON_DELETE", comment: ""),
                                        image: UIImage(named: "delete")?.withRenderingMode(.alwaysTemplate),
                                        attributes: .destructive) { _ in
                self.delegate?.bookmarksViewDisplayDeleteAlert(self, index: indexPath.row)
            }
            return UIMenu(children: [renameAction, deleteAction])
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                return bookmarks.count
            }
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: bookmarksTableViewCellReuseIdentifier, for: indexPath)
        let row = indexPath.row
        let colors = PresentationTheme.currentExcludingWhite.colors

        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        var content = UIListContentConfiguration.valueCell()
        content.textProperties.color = colors.overlayPrimaryTextColor
        content.secondaryTextProperties.color = colors.overlaySecondaryTextColor
        content.secondaryTextProperties.font = UIFontMetrics(forTextStyle: .body)
            .scaledFont(for: .monospacedDigitSystemFont(ofSize: 17, weight: .regular))
        content.directionalLayoutMargins.leading = 12
        content.directionalLayoutMargins.trailing = 12

        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                content.text = bookmarks[row].name
                content.secondaryText = VLCTime(number: NSNumber(value: bookmarks[row].time)).stringValue
            }
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                let time = bookmarks[indexPath.row].time
                delegate?.bookmarksViewDidSelectBookmark(value: Float(time))
            }
        }
    }
}
