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

@objc (VLCMediaMoreOptionsActionSheet)
class MediaMoreOptionsActionSheet: ActionSheet {
    
    // MARK: Private Instance Properties
    private var currentChildViewController: UIViewController?

    private var externalFrame: CGRect {
        get {
            let y = collectionView.frame.origin.y + headerView.cellHeight
            let w = collectionView.frame.size.width
            let h = collectionView.frame.size.height
            return CGRect(x: w, y: y, width: w, height: h)
        }
    }
    
    // To be removed when Designs are done for the Filters, Equalizer etc views are added to Figma
    lazy private var mockViewController: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .green
        let gestureTap = UITapGestureRecognizer(target: self, action: #selector(removeCurrentChild))
        vc.view.addGestureRecognizer(gestureTap)
        vc.view.frame = externalFrame
        return vc
    }()
    
    lazy private var cellItems: [ActionSheetCellItem] = {
        var items: [ActionSheetCellItem] = [
            ActionSheetCellItem(imageIdentifier:"playback", title:NSLocalizedString("PLAYBACK_SPEED", comment: ""), viewController: mockViewController),
            ActionSheetCellItem(imageIdentifier:"filter", title:NSLocalizedString("VIDEO_FILTER", comment: ""), viewController: mockViewController),
            ActionSheetCellItem(imageIdentifier:"equalizer", title:NSLocalizedString("EQUALIZER_CELL_TITLE", comment: ""), viewController: mockViewController),
            ActionSheetCellItem(imageIdentifier:"iconLock", title:NSLocalizedString("INTERFACE_LOCK_BUTTON", comment: ""), viewController: mockViewController),
            ActionSheetCellItem(imageIdentifier:"speedIcon", title:NSLocalizedString("BUTTON_SLEEP_TIMER", comment: ""), viewController: mockViewController)
        ]
        return items
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
            self.currentChildViewController = child
        }
    }
    
    private func remove(childViewController child: UIViewController) {
        child.didMove(toParent: nil)
        UIView.animate(withDuration: 0.3, animations: {
            child.view.frame = self.externalFrame
        }) { (completed) in
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    @objc func removeCurrentChild() {
        if let current = currentChildViewController {
            remove(childViewController: current)
        }
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
                assert(false, "MediaMoreOptionsActionSheet: Action:: Item's viewController is either nil or could not be instantiated")
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MediaMoreOptionsActionSheet: ActionSheetDataSource {
    
    func numberOfRows() -> Int {
        return cellItems.count
    }
    
    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActionSheetCell.identifier,
                                                         for: indexPath) as? ActionSheetCell {
                cell.cellItemModel = cellItems[indexPath.row]
                return cell
        }
        
        assert(false, "MediaMoreOptionsActionSheet: Could not dequeue reusable cell")
        return UICollectionViewCell()
    }
}

extension MediaMoreOptionsActionSheet: ActionSheetDelegate {
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        if indexPath.row < cellItems.count {
            return cellItems[indexPath.row].associatedViewController
        }
        return nil
    }
    
    func headerViewTitle() -> String? {
        return NSLocalizedString("MORE_OPTIONS_HEADER_TITLE", comment: "")
    }
}
