/*****************************************************************************
 * ChapterView.swift
 *
 * Copyright © 2022 VLC authors and VideoLAN
 * Copyright © 2022 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *          Felix Paul Kühne <fkuehne@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol ChapterViewDelegate: AnyObject {
    func chapterViewDelegateDidSelectChapter(_ chapterView: ChapterView)
}

class ChapterView: UIView {
    private var chapterTableView: UITableView!
    private let chapterTitleViewCellIdentifier = "chapterTitleViewCellIdentifier"

    private lazy var playbackService = PlaybackService.sharedInstance()
    weak var delegate: ChapterViewDelegate?

    private lazy var isRightToLeft: Bool = {
        UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContent() {
        if chapterTableView == nil {
            setupTableView()
            setupTheme()
        }
        chapterTableView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func setupTableView() {
        chapterTableView = UITableView.init(frame: frame)
        chapterTableView.dataSource = self
        chapterTableView.delegate = self
        chapterTableView.autoresizesSubviews = false
        chapterTableView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(chapterTableView)
        let chapterTableViewConstraints = [
            chapterTableView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            chapterTableView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            chapterTableView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 10),
            chapterTableView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 5)
        ]
        NSLayoutConstraint.activate(chapterTableViewConstraints)
        chapterTableView.register(UITableViewCell.self, forCellReuseIdentifier: chapterTitleViewCellIdentifier)
    }

    func setupTheme() {
        let colors = PresentationTheme.currentExcludingWhite.colors
        backgroundColor = colors.background
        chapterTableView?.backgroundColor = colors.background
    }

    private func hasMultipleTitles() -> Bool {
        return playbackService.numberOfTitles > 1
    }

    private func hasMultipleChapters() -> Bool {
        return playbackService.numberOfChaptersForCurrentTitle > 1
    }

    private func reload(_ tableView: UITableView) {
        let resetOffset = CGPoint(x: 0, y: 0)
        UIView.transition(with: tableView, duration: 0.55, options: .curveEaseIn, animations: {
            tableView.setContentOffset(resetOffset, animated: true)
        }, completion: { _ in
            tableView.reloadData()
            tableView.layoutIfNeeded()
        })
    }
}

extension ChapterView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 0

        if hasMultipleTitles() {
            sections += 1
        }
        if hasMultipleChapters() {
            sections += 1
        }

        return sections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hasMultipleTitles() && section == 0 {
            return playbackService.numberOfTitles
        }
        return playbackService.numberOfChaptersForCurrentTitle
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if hasMultipleTitles() && section == 0 {
            return NSLocalizedString("CHOOSE_TITLE", comment: "")
        }
        if hasMultipleChapters() {
            return NSLocalizedString("CHOOSE_CHAPTER", comment: "")
        }
        return NSLocalizedString("UNKNOWN_TRACK_TYPE", comment: "")
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            let colors = PresentationTheme.currentExcludingWhite.colors
            headerView.textLabel?.textColor = colors.cellTextColor
            headerView.contentView.backgroundColor = colors.background
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: chapterTitleViewCellIdentifier, for: indexPath)

        let section = indexPath.section
        let row = indexPath.row
        let colors = PresentationTheme.currentExcludingWhite.colors

        cell.backgroundColor = colors.cellBackgroundA
        cell.textLabel?.textColor = colors.cellTextColor
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none

        if hasMultipleTitles() && section == 0 {
            let description = playbackService.titleDescriptionsDict(at: row)
            let name = description[VLCTitleDescriptionName] ?? ""
            let duration = VLCTime(number: description[VLCTitleDescriptionDuration] as? NSNumber).stringValue
            cell.textLabel?.text = isRightToLeft ? "(\(duration)) \(name)" : "\(name) (\(duration))"

            if playbackService.indexOfCurrentTitle == row {
                cell.textLabel?.textColor = colors.orangeUI
            }
        } else {
            let description = playbackService.chapterDescriptionsDict(at: row)
            let name = description[VLCChapterDescriptionName] ?? ""
            let duration = VLCTime(number: description[VLCChapterDescriptionDuration] as? NSNumber).stringValue
            cell.textLabel?.text = isRightToLeft ? "(\(duration)) \(name)" : "\(name) (\(duration))"
            if playbackService.indexOfCurrentChapter == row {
                cell.textLabel?.textColor = colors.orangeUI
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let section = indexPath.section
        let row = indexPath.row

        if hasMultipleTitles() && section == 0 {
            playbackService.selectTitle(at: row)
        } else {
            playbackService.selectChapter(at: row)
            delegate?.chapterViewDelegateDidSelectChapter(self)
        }

        reload(tableView)
    }
}
