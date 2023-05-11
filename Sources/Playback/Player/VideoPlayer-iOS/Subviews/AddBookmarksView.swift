/*****************************************************************************
 * AddBookmarksView.swift
 *
 * Copyright © 2022 VLC authors and VideoLAN
 * Copyright © 2022 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

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
        let colors = PresentationTheme.currentExcludingWhite.colors
        closeButton.tintColor = colors.cellTextColor
        addButton.tintColor = colors.orangeUI
        titleLabel.textColor = colors.cellTextColor
        headerStackView.backgroundColor = colors.background.withAlphaComponent(0.6)
        bookmarksTableView.backgroundColor = headerStackView.backgroundColor
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
