/*****************************************************************************
 * MediaPlayerActionSheet.swift
 *
 * Copyright © 2019-2022 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *          Maxime Chapelet <umxprime # videolabs.io>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

enum MediaPlayerActionSheetCellIdentifier: String, CustomStringConvertible, CaseIterable {
    case filter
    case playback
    case sleepTimer
    case equalizer
    case interfaceLock
    case chapters
    case bookmarks
    case addBookmarks

    var description: String {
        switch self {
        case .filter:
            return NSLocalizedString("VIDEO_FILTER", comment: "")
        case .playback:
            return NSLocalizedString("PLAYBACK_SPEED", comment: "")
        case .equalizer:
            return NSLocalizedString("EQUALIZER_CELL_TITLE", comment: "")
        case .sleepTimer:
            return NSLocalizedString("BUTTON_SLEEP_TIMER", comment: "")
        case .interfaceLock:
            return NSLocalizedString("INTERFACE_LOCK_BUTTON", comment: "")
        case .chapters:
            return NSLocalizedString("CHAPTER_SELECTION_TITLE", comment: "")
        case .bookmarks:
            return NSLocalizedString("BOOKMARKS_TITLE", comment: "")
        case .addBookmarks:
            return NSLocalizedString("ADD_BOOKMARKS_TITLE", comment: "")
        }
    }
}

@objc (VLCMediaPlayerActionSheetDataSource)
protocol MediaPlayerActionSheetDataSource {
    var configurableCellModels: [ActionSheetCellModel] { get }
}

@objc (VLCMediaPlayerActionSheetDelegate)
protocol MediaPlayerActionSheetDelegate {
    func mediaPlayerActionSheetHeaderTitle() -> String?
    @objc optional func mediaPlayerDidToggleSwitch(for cell: ActionSheetCell, state: Bool)
}

@objc (VLCMediaPlayerActionSheet)
class MediaPlayerActionSheet: ActionSheet {
    
    // MARK: Private Instance Properties
    private weak var currentChildView: UIView?
    @objc weak var mediaPlayerActionSheetDelegate: MediaPlayerActionSheetDelegate?
    @objc weak var mediaPlayerActionSheetDataSource: MediaPlayerActionSheetDataSource?
    
    private lazy var leftToRightGesture: UIPanGestureRecognizer = {
        let leftToRight = UIPanGestureRecognizer(target: self, action: #selector(draggedRight(panGesture:)))
        return leftToRight
    }()

    // MARK: Private Methods
    private func getTitle(of childView: UIView) -> String {
        if childView is VideoFiltersView {
            return MediaPlayerActionSheetCellIdentifier.filter.description
        } else if childView is NewPlaybackSpeedView {
            return MediaPlayerActionSheetCellIdentifier.playback.description
        } else if childView is SleepTimerView {
            return MediaPlayerActionSheetCellIdentifier.sleepTimer.description
        } else if childView is EqualizerView {
            return MediaPlayerActionSheetCellIdentifier.equalizer.description
        } else if childView is ChapterView {
            return MediaPlayerActionSheetCellIdentifier.chapters.description
        } else if childView is BookmarksView {
            return MediaPlayerActionSheetCellIdentifier.bookmarks.description
        } else {
            return NSLocalizedString("MORE_OPTIONS_HEADER_TITLE", comment: "")
        }
    }

    private func changeBackground(alpha: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView.backgroundColor = UIColor.black.withAlphaComponent(alpha)
        })
    }

    private func add(childView child: UIView) {
        child.frame = self.offScreenFrame
        self.addChildToStackView(child)
        child.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        child.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, animations: {
            child.frame = self.collectionWrapperView.frame
            self.headerView.previousButton.isHidden = false
            self.headerView.title.text = self.getTitle(of: child)
            if let child = child as? ActionSheetAccessoryViewsDelegate {
                self.headerView.accessoryViewsDelegate = child
            }
            if child is BookmarksView {
                self.leftToRightGesture.delegate = self
                self.updateDragDownGestureDelegate(to: self)
            }
        }) {
            (completed) in
            child.addGestureRecognizer(self.leftToRightGesture)
            self.currentChildView = child
            if child is VideoFiltersView {
                self.changeBackground(alpha: 0)
            }

            self.headerView.previousButton.addTarget(self, action: #selector(self.removeCurrentChild), for: .touchUpInside)
        }
    }

    private func remove(childView child: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            child.frame = self.offScreenFrame
            self.headerView.accessoryViewsDelegate = nil
            self.headerView.updateAccessoryViews()
            self.headerView.previousButton.isHidden = true
            self.headerView.title.text = NSLocalizedString("MORE_OPTIONS_HEADER_TITLE", comment: "")
            if child is BookmarksView {
                self.leftToRightGesture.delegate = nil
                self.updateDragDownGestureDelegate(to: nil)
            }
        }) { (completed) in
            child.removeFromSuperview()
            child.removeGestureRecognizer(self.leftToRightGesture)

            if child is VideoFiltersView {
                self.changeBackground(alpha: 0.6)
            }
        }
    }

    @objc func removeCurrentChild() {
        if let current = currentChildView {
            remove(childView: current)
        }
    }

    func openOptionView(_ view: UIView) {
        add(childView: view)
    }

    func setTheme() {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        collectionWrapperView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        collectionView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        headerView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        headerView.title.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        headerView.title.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
    }

    /// Animates the removal of the `currentChildViewController` when it is dragged from its left edge to the right
    @objc private func draggedRight(panGesture: UIPanGestureRecognizer) {
        if let current = currentChildView {

            let translation = panGesture.translation(in: view)
            let x = translation.x + current.center.x
            let halfWidth = current.frame.size.width / 2
            panGesture.setTranslation(.zero, in: view)

            if panGesture.state == .began || panGesture.state == .changed {
                // only enable left-to-right drags
                if current.frame.minX + translation.x >= 0 {
                    current.center = CGPoint(x: x, y: current.center.y)
                }
            } else if panGesture.state == .ended {
                if current.frame.minX > halfWidth {
                    removeCurrentChild()
                } else {
                    UIView.animate(withDuration: 0.3) {
                        current.frame = self.collectionWrapperView.frame
                    }
                }
            }
        }
    }
    
    // MARK: Overridden superclass methods

    // Removed the automatic dismissal of the view when a cell is selected
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = delegate {
            if let item = delegate.itemAtIndexPath(indexPath) {
                delegate.actionSheet?(collectionView: collectionView, didSelectItem: item, At: indexPath)
                action?(item)
            }
            if let cell = collectionView.cellForItem(at: indexPath) as? ActionSheetCell, cell.accessoryType == .checkmark {
                removeActionSheet()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTheme()
    }

    // MARK: Initializers
    override init() {
        super.init()
        delegate = self
        dataSource = self
        modalPresentationStyle = .custom
        setAction { (item) in
            if let item = item as? UIView {
                if let equalizerView = item as? EqualizerView {
                    if let actionSheet = self as? MediaMoreOptionsActionSheet {
                        equalizerView.willShow()
                        actionSheet.moreOptionsDelegate?.mediaMoreOptionsActionSheetPresentPopupView(withChild: equalizerView)
                        self.removeActionSheet()
                    }
                } else {
                    self.add(childView: item)
                }
            } else {
                preconditionFailure("MediaMoreOptionsActionSheet: Action:: Item's could not be cased as UIView")
            }
        }
        setTheme()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func shouldDisablePanGesture(_ disable: Bool) {
        leftToRightGesture.isEnabled = !disable
    }
}

extension MediaPlayerActionSheet: ActionSheetDataSource {
    func numberOfRows() -> Int {
        return mediaPlayerActionSheetDataSource?.configurableCellModels.count ?? 0
    }
    
    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let source = mediaPlayerActionSheetDataSource,
            indexPath.row < source.configurableCellModels.count else {
            preconditionFailure("MediaPlayerActionSheet: mediaPlayerActionSheetDataSource or invalid indexPath")
        }

        var sheetCell: ActionSheetCell
        let cellModel = source.configurableCellModels[indexPath.row]

        if let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ActionSheetCell.identifier,
            for: indexPath) as? ActionSheetCell {
            sheetCell = cell
            sheetCell.configure(withModel: cellModel, isFromMediaPlayerActionSheet: true)

            sheetCell.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
            sheetCell.name.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
            sheetCell.icon.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI

            if sheetCell.accessoryType == .disclosureChevron {
                cell.accessoryView.tintColor = PresentationTheme.currentExcludingWhite.colors.cellDetailTextColor
            } else {
                sheetCell.accessoryView.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
            }
        } else {
            assertionFailure("MediaMoreOptionsActionSheet: Could not dequeue reusable cell")
            sheetCell = ActionSheetCell(withCellModel: cellModel)
        }

        sheetCell.accessoryView.tintColor = PresentationTheme.currentExcludingWhite.colors.cellDetailTextColor
        sheetCell.delegate = self
        return sheetCell
    }
}

extension MediaPlayerActionSheet: ActionSheetDelegate {
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        guard let source = mediaPlayerActionSheetDataSource,
            indexPath.row < source.configurableCellModels.count else {
                preconditionFailure("MediaPlayerActionSheet: mediaPlayerActionSheetDataSource not set")
        }

        let cellModel = source.configurableCellModels[indexPath.row]
        return cellModel.viewToPresent
    }
    
    func headerViewTitle() -> String? {
        return mediaPlayerActionSheetDelegate?.mediaPlayerActionSheetHeaderTitle()
    }
}

extension MediaPlayerActionSheet: ActionSheetCellDelegate {
    func actionSheetCellShouldUpdateColors() -> Bool {
        return false
    }

    func actionSheetCellDidToggleSwitch(for cell: ActionSheetCell, state: Bool) {
        guard let mediaDelegate = mediaPlayerActionSheetDelegate else {
            preconditionFailure("MediaPlayerActionSheet: mediaPlayerActionSheetDelegate not set")
        }

        mediaDelegate.mediaPlayerDidToggleSwitch?(for: cell, state: state)
    }
}
