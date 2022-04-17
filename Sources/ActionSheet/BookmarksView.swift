/*****************************************************************************
 * ChapterView.swift
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

protocol AddBookmarksViewDelegate: AnyObject {
    func addBookmarksViewDidClose()
    func addBookmarksViewAddBookmark()
}

class AddBookmarksView: UIView {
    private let closeButton = UIButton()
    private let addButton = UIButton()
    private let titleLabel = UILabel()
    private let headerStackView = UIStackView()
    private let separator = UIView()

    private var bookmarksTableView: UITableView = UITableView()

    weak var delegate: BookmarksView?

    init(frame: CGRect, tableView: UITableView) {
        super.init(frame: frame)
        bookmarksTableView = tableView
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setupTable()
        setupButtons()
        setupLabel()
        setupStackView()
        setupSeparator()
        setupConstraints()
        setupTheme()
    }

    private func setupLabel() {
        addSubview(titleLabel)
        titleLabel.font = UIFont.preferredCustomFont(forTextStyle: .headline).bolded
        titleLabel.text = NSLocalizedString("ADD_BOOKMARKS_TITLE", comment: "")
        titleLabel.textAlignment = .center
    }

    private func setupTable() {
        addSubview(bookmarksTableView)
        bookmarksTableView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func setupButtons() {
        addSubview(closeButton)
        addSubview(addButton)
        closeButton.setImage(UIImage(named: "close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.layer.cornerRadius = 12
        closeButton.addTarget(self, action: #selector(closeView), for: .touchUpInside)

        addButton.setImage(UIImage(named: "add-bookmark")?.withRenderingMode(.alwaysTemplate), for: .normal)
        addButton.imageView?.contentMode = .scaleAspectFit
        addButton.addTarget(self, action: #selector(addBookmark), for: .touchUpInside)
    }

    private func setupSeparator() {
        addSubview(separator)
        separator.backgroundColor = .lightGray
    }

    private func setupStackView() {
        addSubview(headerStackView)
        headerStackView.axis = .horizontal
        headerStackView.distribution = .fill
        headerStackView.alignment = .center
        headerStackView.spacing = 20
        headerStackView.addArrangedSubview(closeButton)
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(addButton)
        headerStackView.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        headerStackView.isLayoutMarginsRelativeArrangement = true
    }

    private func setupTheme() {
        closeButton.tintColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        addButton.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        titleLabel.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        headerStackView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background.withAlphaComponent(0.6)
        bookmarksTableView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background.withAlphaComponent(0.6)
    }

    private func setupConstraints() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bookmarksTableView.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        separator.translatesAutoresizingMaskIntoConstraints = false

        let constraints: [NSLayoutConstraint] = [
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor),

            headerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            headerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            headerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            headerStackView.heightAnchor.constraint(equalToConstant: 50),

            separator.leadingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: 0),
            separator.trailingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 0),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: -1),

            bookmarksTableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            bookmarksTableView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            bookmarksTableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            bookmarksTableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc private func closeView() {
        delegate?.addBookmarksViewDidClose()
    }

    @objc private func addBookmark() {
        delegate?.addBookmarksViewAddBookmark()
    }

    func updateTableView() {
        setupTable()
        NSLayoutConstraint.activate([
            bookmarksTableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            bookmarksTableView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            bookmarksTableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            bookmarksTableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
}


class BookmarksView: UIView {
    private let addBookmarkButton = UIButton()
    private let addBookmarkAtTimeButton = UIButton()
    private let bookmarksTableView = UITableView()
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
        setupTable()
        setupConstraints()
        setupTheme()
    }

    func update() {
        bookmarksTableView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()
    }

    func setupTheme() {
        backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        bookmarksTableView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        update()
    }

    private func setupTable() {
        addSubview(bookmarksTableView)
        bookmarksTableView.delegate = self
        bookmarksTableView.dataSource = self
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

    private func setupConstraints() {
        bookmarksTableView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            bookmarksTableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            bookmarksTableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            bookmarksTableView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            bookmarksTableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc private func addBookmark() {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            let playbackService = PlaybackService.sharedInstance()
            let currentTime = playbackService.playedTime()
            let currentTimeInt64 = Int64(truncating: currentTime.value ?? 0)
            currentMedia.addBookmark(atTime: currentTimeInt64)
            if let bookmark = currentMedia.bookmark(atTime: currentTimeInt64) {
                bookmark.name = NSLocalizedString("BOOKMARK_DEFAULT_NAME", comment: "") + currentTime.stringValue
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
                        newName = NSLocalizedString("BOOKMARK_DEFAULT_NAME", comment: "") + time
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
        let cell = UITableViewCell()

        let row = indexPath.row

        cell.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background.withAlphaComponent(0)
        cell.textLabel?.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
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
        setupConstraints()
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
