/*****************************************************************************
 * TitleSelectionView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2022 VideoLAN. All rights reserved.
 * Copyright © 2022 Videolabs
 *
 * Author: Soomin Lee  <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@objc protocol TitleSelectionViewDelegate: AnyObject {
    func titleSelectionViewDelegateDidSelectTrack(_ titleSelectionView: TitleSelectionView)
    func titleSelectionViewDelegateDidSelectDownloadSPU(_ titleSelectionView: TitleSelectionView)
    func titleSelectionViewDelegateDidSelectFromFiles(_ titleSelectionView: TitleSelectionView)
    @objc optional func shouldHideTitleSelectionView(_ titleSelectionView: TitleSelectionView)
}

class TitleSelectionTableViewCell: UITableViewCell {
    static let identifier: String = "TitleSelectionTableViewCell"

    static let size: CGFloat = 44.0

    private let mainStackView: UIStackView = {
        let mainStackView: UIStackView = UIStackView()
        mainStackView.distribution = .fill
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        return mainStackView
    }()

    private(set) var checkImageView: UIImageView = {
        let checkmarkImage = UIImage(named: "checkmark")?.withAlignmentRectInsets(UIEdgeInsets(top: -10, left: -10,
                                                                                               bottom: -10, right: -10))

        let checkImageView: UIImageView = UIImageView(image: checkmarkImage)
        checkImageView.alpha = 0
        checkImageView.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        return checkImageView
    }()

    private(set) var contentLabel: UILabel = {
        let contentLabel: UILabel = UILabel()
        contentLabel.textColor = PresentationTheme.darkTheme.colors.cellTextColor
        contentLabel.font = .preferredFont(forTextStyle: .callout)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        return contentLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentLabel.text = ""
        checkImageView.alpha = 0
    }

    private func setupView() {
        backgroundColor = .clear
        addSubview(mainStackView)
        mainStackView.addArrangedSubview(checkImageView)
        mainStackView.addArrangedSubview(contentLabel)

        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                                   constant: 5),
            mainStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor,
                                                    constant: -5),
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            checkImageView.widthAnchor.constraint(equalToConstant: 44),
            checkImageView.heightAnchor.constraint(equalTo: checkImageView.widthAnchor),
        ])
    }
}

class TitleSelectionView: UIView {
    // MARK: - Properties

    private var viewConfigured: Bool = false

    weak var delegate: TitleSelectionViewDelegate?

    private lazy var playbackService = PlaybackService.sharedInstance()

    private lazy var backgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.frame = self.frame
        backgroundView.isAccessibilityElement = true
        backgroundView.accessibilityLabel = NSLocalizedString("TITLESELECTION_BACKGROUND_LABEL",
                                                              comment: "")
        backgroundView.accessibilityHint = NSLocalizedString("TITLESELECTION_BACKGROUND_HINT",
                                                             comment: "")

        backgroundView.accessibilityTraits = .allowsDirectInteraction
        backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                   action: #selector(self.removeView)))
        return backgroundView
    }()

    // MARK: - Interface Properties

    private(set) lazy var mainStackView: UIStackView = {
        let mainStackView: UIStackView = UIStackView()
        mainStackView.distribution = .fill
        mainStackView.axis = .vertical
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        return mainStackView
    }()

    private lazy var audioTableView: UITableView = {
        let audioTableView: UITableView = UITableView(frame: .zero, style: .plain)
        audioTableView.delegate = self
        audioTableView.dataSource = self
        audioTableView.translatesAutoresizingMaskIntoConstraints = false
        audioTableView.contentInsetAdjustmentBehavior = .never
        audioTableView.sectionIndexBackgroundColor = .clear
        return audioTableView
    }()

    private lazy var subtitleTableView: UITableView = {
        let subtitleTableView: UITableView = UITableView(frame: .zero, style: .plain)
        subtitleTableView.delegate = self
        subtitleTableView.dataSource = self
        subtitleTableView.translatesAutoresizingMaskIntoConstraints = false
        subtitleTableView.contentInsetAdjustmentBehavior = .never
        subtitleTableView.sectionIndexBackgroundColor = .clear
        return subtitleTableView
    }()

    private var audioTableViewHeight: CGFloat {
        let rowsCount: CGFloat = CGFloat(playbackService.numberOfAudioTracks)
        let tableViewHeight = (rowsCount * TitleSelectionTableViewCell.size) + TitleSelectionTableViewCell.size
        return tableViewHeight + safeAreaInsets.bottom
    }

    private var subtitleTableViewHeight: CGFloat {
        let rowsCount: CGFloat = CGFloat(playbackService.numberOfVideoSubtitlesIndexes)
        let tableViewHeight = (rowsCount * TitleSelectionTableViewCell.size) + TitleSelectionTableViewCell.size
        return tableViewHeight + safeAreaInsets.bottom
    }

    private lazy var audioTableViewHeightConstraint = audioTableView.heightAnchor.constraint(equalToConstant: audioTableViewHeight)

    private lazy var subtitleTableViewHeightConstraint = subtitleTableView.heightAnchor.constraint(equalToConstant: subtitleTableViewHeight)

    // MARK: - Init

    init(frame: CGRect, orientation: NSLayoutConstraint.Axis = .vertical) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        addSubview(mainStackView)
        mainStackView.axis = orientation
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reload() {
        if !viewConfigured {
            setupStackView()
            setupTableViews()
            setupConstraints()
            viewConfigured = true
        }
        audioTableView.reloadData()
        subtitleTableView.reloadData()
    }

    @objc func removeView() {
        delegate?.shouldHideTitleSelectionView?(self)
    }

    func updateHeightConstraints() {
        audioTableViewHeightConstraint.constant = audioTableViewHeight
        subtitleTableViewHeightConstraint.constant = subtitleTableViewHeight
        subtitleTableView.setNeedsLayout()
        audioTableView.setNeedsLayout()
        mainStackView.setNeedsLayout()
        audioTableView.layoutIfNeeded()
        subtitleTableView.layoutIfNeeded()
        mainStackView.layoutIfNeeded()
    }
}

// MARK: - Setup

private extension TitleSelectionView {
    private func setupStackView() {
        mainStackView.backgroundColor = .clear
        mainStackView.addArrangedSubview(audioTableView)
        mainStackView.addArrangedSubview(subtitleTableView)
    }

    private func setupTableViews() {
        if #available(iOS 15, *) {
            audioTableView.sectionHeaderTopPadding = 0
            subtitleTableView.sectionHeaderTopPadding = 0
        }

        audioTableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: audioTableView.frame.size.width, height: 1))
        audioTableView.delegate = self
        audioTableView.register(TitleSelectionTableViewCell.self,
                                forCellReuseIdentifier: TitleSelectionTableViewCell.identifier)
        audioTableView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        audioTableView.verticalScrollIndicatorInsets.top = TitleSelectionTableViewCell.size

        subtitleTableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: subtitleTableView.frame.size.width, height: 1))
        subtitleTableView.delegate = self
        subtitleTableView.register(TitleSelectionTableViewCell.self,
                                   forCellReuseIdentifier: TitleSelectionTableViewCell.identifier)
        subtitleTableView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        subtitleTableView.verticalScrollIndicatorInsets.top = TitleSelectionTableViewCell.size
    }

    private func setupConstraints() {
        let limitTopConstraint = mainStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor,
                                                                    constant: 150)

        let minSubtitleConstraint = subtitleTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: TitleSelectionTableViewCell.size * 2)
        minSubtitleConstraint.priority = .required

        let minAudioConstraint = audioTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: TitleSelectionTableViewCell.size * 1.5)
        minAudioConstraint.priority = .required

        audioTableViewHeightConstraint.priority = .defaultHigh
        subtitleTableViewHeightConstraint.priority = .defaultHigh
        limitTopConstraint.priority = .required

        NSLayoutConstraint.activate([
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            audioTableViewHeightConstraint,
            subtitleTableViewHeightConstraint,
            limitTopConstraint,
            minAudioConstraint,
            minSubtitleConstraint,
        ])
    }
}

extension TitleSelectionView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == audioTableView {
            return playbackService.numberOfAudioTracks
        } else {
            return playbackService.numberOfVideoSubtitlesIndexes
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleSelectionTableViewCell.identifier,
                                                       for: indexPath) as? TitleSelectionTableViewCell else {
            return UITableViewCell()
        }

        cell.checkImageView.alpha = 0
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        var cellTitle: String = ""
        var textColor: UIColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor

        let currentAudioTrackIndex = playbackService.indexOfCurrentAudioTrack
        let currentSubtitlesTrackIndex = playbackService.indexOfCurrentSubtitleTrack

        if indexPath.row == 0 {
            cellTitle = NSLocalizedString("DISABLE_LABEL", comment: "")
            if (tableView == audioTableView && currentAudioTrackIndex == -1) ||
                (tableView == subtitleTableView && currentSubtitlesTrackIndex == -1) {
                textColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
                cell.checkImageView.alpha = 1
            }
        } else if tableView == audioTableView {
            if currentAudioTrackIndex + 1 == indexPath.row {
                textColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
                cell.checkImageView.alpha = 1
            }

            cellTitle = playbackService.audioTrackName(at: indexPath.row - 1)
        } else {
            if currentSubtitlesTrackIndex + 1 == indexPath.row {
                textColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
                cell.checkImageView.alpha = 1
            }

            let count = playbackService.numberOfVideoSubtitlesIndexes
            cellTitle = indexPath.row == count - 1 ? NSLocalizedString("DOWNLOAD_SUBS_FROM_OSO", comment: "") :
                        playbackService.videoSubtitleName(at: indexPath.row - 1)
        }

        cell.contentLabel.text = cellTitle
        cell.contentLabel.textColor = textColor
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let currentCell = tableView.cellForRow(at: indexPath) as? TitleSelectionTableViewCell
        currentCell?.checkImageView.alpha = 1

        if tableView == audioTableView {
            if indexPath.row == 0 {
                playbackService.disableAudio()
                delegate?.titleSelectionViewDelegateDidSelectTrack(self)
            } else if indexPath.row == playbackService.numberOfAudioTracks - 1 {
                currentCell?.checkImageView.alpha = 0
                delegate?.titleSelectionViewDelegateDidSelectFromFiles(self)
            } else {
                playbackService.selectAudioTrack(at: indexPath.row - 1)
                delegate?.titleSelectionViewDelegateDidSelectTrack(self)
            }
        } else {
            if indexPath.row == 0 {
                playbackService.disableSubtitles()
                delegate?.titleSelectionViewDelegateDidSelectTrack(self)
            } else if indexPath.row == playbackService.numberOfVideoSubtitlesIndexes - 2 {
                currentCell?.checkImageView.alpha = 0
                delegate?.titleSelectionViewDelegateDidSelectFromFiles(self)
            } else if indexPath.row == playbackService.numberOfVideoSubtitlesIndexes - 1 {
                currentCell?.checkImageView.alpha = 0
                delegate?.titleSelectionViewDelegateDidSelectDownloadSPU(self)
            } else {
                playbackService.selectVideoSubtitle(at: indexPath.row - 1)
                delegate?.titleSelectionViewDelegateDidSelectTrack(self)
            }
        }
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TitleSelectionTableViewCell.size
    }

    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        return TitleSelectionTableViewCell.size
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView: TitleSelectionTableViewHeaderView = TitleSelectionTableViewHeaderView(
            title: tableView == audioTableView ? NSLocalizedString("AUDIO", comment: "").capitalized : 
            NSLocalizedString("SUBTITLES", comment: "").capitalized
        )
        
        return headerView
    }
}

// MARK: - TitleSelectionTableViewHeaderView
fileprivate final class TitleSelectionTableViewHeaderView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()

    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(separator)

        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor, constant: 5),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerYAnchor),

            separator.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
}
