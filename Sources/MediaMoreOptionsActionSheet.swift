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

enum MediaPlayerActionSheetCellIdentifier {
    case filter
    case playback
    case equalizer
    case sleepTimer
    case interfaceLock
}

@objc (VLCMediaMoreOptionsActionSheetDelegate)
protocol MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsDidToggleInterfaceLock(state: Bool)
}

@objc (VLCMediaMoreOptionsActionSheet)
class MediaMoreOptionsActionSheet: ActionSheet {
    
    // MARK: Private Instance Properties
    private weak var currentChildViewController: UIViewController?
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

    private var externalFrame: CGRect {
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
    lazy private var mockViewController: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .green
        vc.view.frame = externalFrame
        return vc
    }()
    
    lazy private var cellModels: [ActionSheetCellModel] = {
        let models: [ActionSheetCellModel] = [
            ActionSheetCellModel(
                title:NSLocalizedString("VIDEO_FILTER", comment: ""),
                imageIdentifier:"filter",
                viewControllerToPresent: mockViewController,
                cellIdentifier: .filter
            ),
            ActionSheetCellModel(
                title:NSLocalizedString("PLAYBACK_SPEED", comment: ""),
                imageIdentifier:"playback",
                viewControllerToPresent: mockViewController,
                cellIdentifier: .playback
            ),
            ActionSheetCellModel(
                title:NSLocalizedString("EQUALIZER_CELL_TITLE", comment: ""),
                imageIdentifier:"equalizer",
                viewControllerToPresent: mockViewController,
                cellIdentifier: .equalizer
            ),
            ActionSheetCellModel(
                title:NSLocalizedString("BUTTON_SLEEP_TIMER", comment: ""),
                imageIdentifier:"speedIcon",
                viewControllerToPresent: mockViewController,
                cellIdentifier: .sleepTimer
            ),
            ActionSheetCellModel(
                title:NSLocalizedString("INTERFACE_LOCK_BUTTON", comment: ""),
                imageIdentifier:"iconLock",
                accessoryType: .toggleSwitch,
                cellIdentifier: .interfaceLock
            )
        ]
        return models
    }()
    
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
            } else {
                preconditionFailure("MediaMoreOptionsActionSheet: Action:: Item's could not be cased as UIViewController")
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
        var sheetCell: ActionSheetCell
        
        if indexPath.row >= cellModels.count {
            return ActionSheetCell()
        }
        
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
            return cellModels[indexPath.row].viewControllerToPresent
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
