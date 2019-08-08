/*****************************************************************************
 * MediaPlayerActionSheet.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

enum MediaPlayerActionSheetCellIdentifier {
    case filter
    case playback
    case equalizer
    case sleepTimer
    case interfaceLock

    var description: String {
        switch self {
        case .filter:
            return NSLocalizedString("VIDEO_FILTER", comment: "")
        case .playback:
            return NSLocalizedString("PLAYBACK_SPEED", comment: "")
        case .equalizer:
            return NSLocalizedString("EQUALIZER_CELL_TITLE", comment: "")
        case .interfaceLock:
            return NSLocalizedString("BUTTON_SLEEP_TIMER", comment: "")
        case .sleepTimer:
            return NSLocalizedString("INTERFACE_LOCK_BUTTON", comment: "")
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
    private weak var currentChildViewController: UIViewController?
    @objc weak var mediaPlayerActionSheetDelegate: MediaPlayerActionSheetDelegate?
    @objc weak var mediaPlayerActionSheetDataSource: MediaPlayerActionSheetDataSource?
    
    var externalFrame: CGRect {
        let y = collectionView.frame.origin.y + headerView.cellHeight
        let w = collectionView.frame.size.width
        let h = collectionView.frame.size.height
        return CGRect(x: w, y: y, width: w, height: h)
    }
    
    private var leftToRightGesture: UIPanGestureRecognizer {
        let leftToRight = UIPanGestureRecognizer(target: self, action: #selector(draggedRight(panGesture:)))
        return leftToRight
    }

    // MARK: Private Methods
    private func add(childViewController child: UIViewController) {
        addChild(child)
        UIView.animate(withDuration: 0.3, animations: {
            child.view.frame = self.collectionView.frame
            self.addChildToStackView(child.view)
        }) {
            (completed) in
            child.didMove(toParent: self)
            child.view.addGestureRecognizer(self.leftToRightGesture)
            self.currentChildViewController = child
        }
    }
    
    private func remove(childViewController child: UIViewController) {
        child.didMove(toParent: nil)
        UIView.animate(withDuration: 0.3, animations: {
            child.view.frame = self.externalFrame
        }) { (completed) in
            child.view.removeFromSuperview()
            child.view.removeGestureRecognizer(self.leftToRightGesture)
            child.removeFromParent()
        }
    }
    
    @objc func removeCurrentChild() {
        if let current = currentChildViewController {
            remove(childViewController: current)
        }
    }

    func setTheme() {
        let darkColors = PresentationTheme.darkTheme.colors
        collectionView.backgroundColor = darkColors.background
        headerView.backgroundColor = darkColors.background
        headerView.title.textColor = darkColors.cellTextColor
        for cell in collectionView.visibleCells {
            if let cell = cell as? ActionSheetCell {
                cell.backgroundColor = darkColors.background
                cell.name.textColor = darkColors.cellTextColor
                cell.icon.tintColor = .orange
                // toggleSwitch's tintColor should not be changed
                if cell.accessoryType == .disclosureChevron {
                    cell.accessoryView.tintColor = darkColors.cellDetailTextColor
                } else if cell.accessoryType == .checkmark {
                    cell.accessoryView.tintColor = .orange
                }
            }
        }
        collectionView.layoutIfNeeded()
    }

    /// Animates the removal of the `currentChildViewController` when it is dragged from its left edge to the right
    @objc private func draggedRight(panGesture: UIPanGestureRecognizer) {
        if let current = currentChildViewController {

            let translation = panGesture.translation(in: view)
            let x = translation.x + current.view.center.x
            let halfWidth = current.view.frame.size.width / 2
            panGesture.setTranslation(.zero, in: view)

            if panGesture.state == .began || panGesture.state == .changed {
                // only enable left-to-right drags
                if current.view.frame.minX + translation.x >= 0 {
                    current.view.center = CGPoint(x: x, y: current.view.center.y)
                }
            } else if panGesture.state == .ended {
                if current.view.frame.minX > halfWidth {
                    removeCurrentChild()
                } else {
                    UIView.animate(withDuration: 0.3) {
                        current.view.frame = self.collectionView.frame
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Remove the themeDidChangeNotification set in the superclass
        // MovieViewController Video Options should be dark at all times
        NotificationCenter.default.removeObserver(self, name: .VLCThemeDidChangeNotification, object: nil)
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
            if let item = item as? UIViewController {
               self.add(childViewController: item)
            }
        }
        setTheme()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MediaPlayerActionSheet: ActionSheetDataSource {
    func numberOfRows() -> Int {
//        guard let source = mediaPlayerActionSheetDataSource else {
//            preconditionFailure("MediaPlayerActionSheet: mediaPlayerActionSheetDataSource not set")
//            return 0
//        }

        return mediaPlayerActionSheetDataSource?.configurableCellModels.count ?? 0
    }
    
    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let source = mediaPlayerActionSheetDataSource {
            if indexPath.row >= source.configurableCellModels.count {
                return ActionSheetCell()
            }

            var sheetCell: ActionSheetCell
            let cellModel = source.configurableCellModels[indexPath.row]

            if let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ActionSheetCell.identifier,
                for: indexPath) as? ActionSheetCell {
                sheetCell = cell
                sheetCell.configure(withModel: cellModel)
            } else {
                assertionFailure("MediaMoreOptionsActionSheet: Could not dequeue reusable cell")
                sheetCell = ActionSheetCell(withCellModel: cellModel)
            }
            sheetCell.accessoryView.tintColor = PresentationTheme.darkTheme.colors.cellDetailTextColor
            sheetCell.delegate = self
            return sheetCell
        }
        preconditionFailure("MediaPlayerActionSheet: mediaPlayerActionSheetDataSource not set")
        return UICollectionViewCell()
    }
}

extension MediaPlayerActionSheet: ActionSheetDelegate {
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        guard let source = mediaPlayerActionSheetDataSource,
            indexPath.row < source.configurableCellModels.count else {
                preconditionFailure("MediaPlayerActionSheet: mediaPlayerActionSheetDataSource not set")
                return nil
        }

        let cellModel = source.configurableCellModels[indexPath.row]
        return cellModel.viewControllerToPresent
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
