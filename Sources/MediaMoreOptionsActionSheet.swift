/*****************************************************************************
 * MediaMoreOptionsActionSheet.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

enum MediaPlayerActionSheetCellIdentifier: String, CustomStringConvertible, CaseIterable {
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
        case .sleepTimer:
            return NSLocalizedString("BUTTON_SLEEP_TIMER", comment: "")
        case .interfaceLock:
            return NSLocalizedString("INTERFACE_LOCK_BUTTON", comment: "")
        }
    }
}

@objc (VLCMediaMoreOptionsActionSheetDelegate)
protocol MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsDidToggleInterfaceLock(state: Bool)
}

@objc (VLCMediaMoreOptionsActionSheet)
class MediaMoreOptionsActionSheet: ActionSheet {
    
    // MARK: Private Instance Properties
    private weak var currentChildView: UIView?
    @objc weak var moreOptionsDelegate: MediaMoreOptionsActionSheetDelegate?

    @objc var interfaceDisabled: Bool = false {
        didSet {
            collectionView.visibleCells.forEach {
                if let cell = $0 as? ActionSheetCell, let id = cell.identifier {
                    if id == .interfaceLock {
                        cell.setToggleSwitch(state: interfaceDisabled)
                    } else {
                        cell.alpha = interfaceDisabled ? 0.5 : 1
                    }
                }
            }
            collectionView.allowsSelection = !interfaceDisabled
        }
    }

    private var offScreenFrame: CGRect {
        let y = collectionView.frame.origin.y + headerView.cellHeight
        let w = collectionView.frame.size.width
        let h = collectionView.frame.size.height
        return CGRect(x: w, y: y, width: w, height: h)
    }
    
    private var leftToRightGesture: UIPanGestureRecognizer {
        let leftToRight = UIPanGestureRecognizer(target: self, action: #selector(draggedRight(panGesture:)))
        return leftToRight
    }
    
    // To be removed when Designs are done for the Filters, Equalizer etc views are added to Figma
    lazy private var mockView: UIView = {
        let v = UIView()
        v.backgroundColor = .green
        v.frame = offScreenFrame
        return v
    }()
    
    lazy private var cellModels: [ActionSheetCellModel] = {
        var models: [ActionSheetCellModel] = []
        MediaPlayerActionSheetCellIdentifier.allCases.forEach {
            var cellModel = ActionSheetCellModel(
                title: String(describing: $0),
                imageIdentifier: $0.rawValue,
                viewToPresent: mockView,
                cellIdentifier: $0
            )
            if $0 == .interfaceLock {
                cellModel.accessoryType = .toggleSwitch
                cellModel.viewToPresent = nil
            }
            models.append(cellModel)
        }
        return models
    }()
    
    // MARK: Private Methods
    private func add(childView child: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            child.frame = self.collectionView.frame
            self.addChildToStackView(child)
        }) {
            (completed) in
            child.addGestureRecognizer(self.leftToRightGesture)
            self.currentChildView = child
        }
    }
    
    private func remove(childView child: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            child.frame = self.offScreenFrame
        }) { (completed) in
            child.removeFromSuperview()
            child.removeGestureRecognizer(self.leftToRightGesture)
        }
    }
    
    @objc func removeCurrentChild() {
        if let current = currentChildView {
            remove(childView: current)
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
                        current.frame = self.collectionView.frame
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
               self.add(childView: item)
            } else {
                preconditionFailure("MediaMoreOptionsActionSheet: Cell item could not be casted as UIView")
            }
        }
        setTheme()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MediaMoreOptionsActionSheet: ActionSheetDataSource {
    func numberOfRows() -> Int {
        return cellModels.count
    }
    
    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard indexPath.row < cellModels.count else {
            assertionFailure("MediaMoreOptionsActionSheet")
            return ActionSheetCell()
        }

        var sheetCell: ActionSheetCell

        if let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ActionSheetCell.identifier,
            for: indexPath) as? ActionSheetCell {
            sheetCell = cell
            sheetCell.configure(withModel: cellModels[indexPath.row])
        } else {
            assertionFailure("MediaMoreOptionsActionSheet: Could not dequeue reusable cell")
            sheetCell = ActionSheetCell(withCellModel: cellModels[indexPath.row])
        }
        sheetCell.accessoryView.tintColor = PresentationTheme.darkTheme.colors.cellDetailTextColor
        sheetCell.delegate = self
        return sheetCell
    }
}

extension MediaMoreOptionsActionSheet: ActionSheetDelegate {
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        if indexPath.row < cellModels.count {
            return cellModels[indexPath.row].viewToPresent
        }
        return nil
    }
    
    func headerViewTitle() -> String? {
        return NSLocalizedString("MORE_OPTIONS_HEADER_TITLE", comment: "")
    }
}

extension MediaMoreOptionsActionSheet: ActionSheetCellDelegate {
    func actionSheetCellShouldUpdateColors() -> Bool {
        return false
    }

    func actionSheetCellDidToggleSwitch(for cell: ActionSheetCell, state: Bool) {
        assert(moreOptionsDelegate != nil, "MediaMoreOptionsActionSheet: Delegate not set.")
        if let identifier = cell.identifier {
            if identifier == .interfaceLock {
                moreOptionsDelegate?.mediaMoreOptionsDidToggleInterfaceLock(state: state)
            }
        }
    }
}
