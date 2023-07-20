/*****************************************************************************
 * BookmarksView.swift
 *
 * Copyright © 2022 VLC authors and VideoLAN
 * Copyright © 2022 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol BookmarksViewDelegate: AnyObject {
    func bookmarksViewGetCurrentPlayingMedia() -> VLCMLMedia?
    func bookmarksViewDidSelectBookmark(value: Float)
    func bookmarksViewShouldDisableGestures(_ disable: Bool)
    func bookmarksViewDisplayAlert(action: BookmarkActionIdentifier, index: Int, isEditing: Bool)
    func bookmarksViewOpenBookmarksView()
    func bookmarksViewOpenAddBookmarksView()
    func bookmarksViewCloseAddBookmarksView()
}

@objc enum BookmarkActionIdentifier: Int {
    case rename = 1
    case delete
}

class BookmarksView: UIView {
    private let addBookmarkButton = UIButton()
    private let addBookmarkAtTimeButton = UIButton()
    private var bookmarksTableView: UITableView!
    private let bookmarksTableViewCellReuseIdentifier = "bookmarksTableViewCellReuseIdentifier"
    private lazy var addBookmarksView: AddBookmarksView = {
        let addBookmarksView = AddBookmarksView(frame: .zero, tableView: bookmarksTableView)
        addBookmarksView.delegate = self
        return addBookmarksView
    }()
    private var isEditing: Bool = false

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
        setupButton()
        setupTheme()
    }

    func update() {
        if bookmarksTableView == nil {
            setupTable()
        }
        bookmarksTableView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()
    }

    func setupTheme() {
        let colors = PresentationTheme.currentExcludingWhite.colors
        backgroundColor = colors.background
    }

    private func setupTable() {
        bookmarksTableView = UITableView()
        addSubview(bookmarksTableView)
        bookmarksTableView.delegate = self
        bookmarksTableView.dataSource = self
        bookmarksTableView.register(UITableViewCell.self, forCellReuseIdentifier: bookmarksTableViewCellReuseIdentifier)
        bookmarksTableView.backgroundColor = .clear
        setupTableContraints()
    }

    private func setupTableContraints() {
        bookmarksTableView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            bookmarksTableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            bookmarksTableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            bookmarksTableView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            bookmarksTableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func setupButton() {
        addBookmarkButton.setImage(UIImage(named: "add-bookmark")?.withRenderingMode(.alwaysTemplate), for: .normal)

        addBookmarkButton.imageView?.contentMode = .scaleAspectFit
        addBookmarkButton.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        addBookmarkButton.addTarget(self, action: #selector(addBookmark), for: .touchUpInside)
        addBookmarkButton.setContentHuggingPriority(.required, for: .horizontal)
        addBookmarkButton.setContentHuggingPriority(.required, for: .vertical)
        addBookmarkButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        addBookmarkAtTimeButton.setImage(UIImage(named: "add-bookmark-at")?.withRenderingMode(.alwaysTemplate), for: .normal)

        addBookmarkAtTimeButton.imageView?.contentMode = .scaleAspectFit
        addBookmarkAtTimeButton.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        addBookmarkAtTimeButton.addTarget(self, action: #selector(openAddView), for: .touchUpInside)
        addBookmarkAtTimeButton.setContentHuggingPriority(.required, for: .horizontal)
        addBookmarkAtTimeButton.setContentHuggingPriority(.required, for: .vertical)
        addBookmarkAtTimeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @objc private func addBookmark() {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            let playbackService = PlaybackService.sharedInstance()
            let currentTime = playbackService.playedTime()
            let currentTimeInt64 = Int64(truncating: currentTime.value ?? 0)
            currentMedia.addBookmark(atTime: currentTimeInt64)
            if let bookmark = currentMedia.bookmark(atTime: currentTimeInt64) {
                bookmark.name = NSLocalizedString("BOOKMARK_DEFAULT_NAME", comment: "") + " " + currentTime.stringValue
            }
            bookmarksTableView.reloadData()
        }
    }

    @objc private func openAddView() {
        delegate?.bookmarksViewOpenAddBookmarksView()
        bookmarksTableView.removeFromSuperview()
        addBookmarksView.updateTableView()
        isEditing = true
    }

    func deleteBookmarkAt(row: Int) {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                if bookmarks.count > row {
                    currentMedia.removeBookmark(atTime: bookmarks[row].time)
                    bookmarksTableView.reloadData()
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

    func restoreTable() {
        bookmarksTableView.delegate = self
        bookmarksTableView.dataSource = self
    }

    func getAddBookmarksView() -> AddBookmarksView {
        return addBookmarksView
    }
}

extension BookmarksView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "", handler: { _, _, _ in
            self.delegate?.bookmarksViewDisplayAlert(action: .delete, index: indexPath.row, isEditing: self.isEditing)
        })

        deleteAction.image = UIImage(named: "delete")?.withRenderingMode(.alwaysTemplate)

        let renameAction = UIContextualAction(style: .normal, title: "", handler: { _, _, _ in
            self.delegate?.bookmarksViewDisplayAlert(action: .rename, index: indexPath.row, isEditing: self.isEditing)
        })

        renameAction.backgroundColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        renameAction.image = UIImage(named: "rename")?.withRenderingMode(.alwaysTemplate)

        return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteLabel = NSLocalizedString("BUTTON_DELETE", comment: "")
        let deleteAction = UITableViewRowAction(style: .destructive, title: deleteLabel, handler: { _, _ in
            self.delegate?.bookmarksViewDisplayAlert(action: .delete, index: indexPath.row, isEditing: self.isEditing)
        })

        let renameLabel = NSLocalizedString("BUTTON_RENAME", comment: "")
        let renameAction = UITableViewRowAction(style: .normal, title: renameLabel, handler: { _, _ in
            self.delegate?.bookmarksViewDisplayAlert(action: .rename, index: indexPath.row, isEditing: self.isEditing)
        })

        renameAction.backgroundColor = PresentationTheme.currentExcludingWhite.colors.orangeUI

        return [deleteAction, renameAction]
    }

    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        delegate?.bookmarksViewShouldDisableGestures(true)
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        delegate?.bookmarksViewShouldDisableGestures(false)
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
        cell.textLabel?.textColor = colors.cellTextColor
        cell.selectionStyle = .none

        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                cell.textLabel?.text = bookmarks[row].name
            }
        }

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

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if frame.minX == 0 {
            delegate?.bookmarksViewShouldDisableGestures(true)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.bookmarksViewShouldDisableGestures(false)
    }
}


extension BookmarksView: AddBookmarksViewDelegate {
    func addBookmarksViewDidClose() {
        addSubview(bookmarksTableView)
        setupTableContraints()
        delegate?.bookmarksViewCloseAddBookmarksView()
        isEditing = false
    }

    func addBookmarksViewAddBookmark() {
        addBookmark()
    }
}

extension BookmarksView: ActionSheetAccessoryViewsDelegate {
    func actionSheetAccessoryViews(_ actionSheet: ActionSheetSectionHeader) -> [UIView] {
        return [addBookmarkButton, addBookmarkAtTimeButton]
    }
}
