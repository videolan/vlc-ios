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

protocol ChapterViewDelegate: AnyObject {
    func chapterViewDelegateDidSelectChapter(_ chapterView: ChapterView)
}

class ChapterView: UIView {
    @IBOutlet weak var chapterTableView: UITableView!

    private lazy var playbackService = PlaybackService.sharedInstance()
    weak var delegate: ChapterViewDelegate?

    private lazy var isRightToLeft: Bool = {
        UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
    }()

    override func awakeFromNib() {
        setupChapterTable()
        setupTheme()
    }

    private func setupChapterTable() {
        chapterTableView.dataSource = self
        chapterTableView.delegate = self
    }

    private func update() {
        chapterTableView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()
    }

    func setupTheme() {
        backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        chapterTableView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        update()
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
            headerView.textLabel?.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
            headerView.contentView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

        let section = indexPath.section
        let row = indexPath.row

        cell.backgroundColor = PresentationTheme.currentExcludingWhite.colors.cellBackgroundA
        cell.textLabel?.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        cell.selectionStyle = .none

            if hasMultipleTitles() && section == 0 {
                let description = playbackService.titleDescriptionsDict(at: row)
                let name = description[VLCTitleDescriptionName] ?? ""
                let duration = VLCTime(number: description[VLCTitleDescriptionDuration] as? NSNumber).stringValue
                cell.textLabel?.text = isRightToLeft ? "(\(duration)) \(name)" : "\(name) (\(duration))"

                if playbackService.indexOfCurrentTitle == row {
                    cell.textLabel?.textColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
                }
            } else {
                let description = playbackService.chapterDescriptionsDict(at: row)
                let name = description[VLCChapterDescriptionName] ?? ""
                let duration = VLCTime(number: description[VLCChapterDescriptionDuration] as? NSNumber).stringValue
                cell.textLabel?.text = isRightToLeft ? "(\(duration)) \(name)" : "\(name) (\(duration))"
                if playbackService.indexOfCurrentChapter == row {
                    cell.textLabel?.textColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
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
