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
    
    // MARK: Initializers
    override init() {
        super.init()
        delegate = self
        dataSource = self
        modalPresentationStyle = .custom
        setAction { (item) in
            if let item = item as? UIViewController {
                self.remove(childViewController: self.children[0])
                self.add(childViewController: item)
            } else {
                assert(false, "MediaMoreOptionsActionSheet: Failure in set Action")
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Private Instance Properties
    private var currentConstraints: [NSLayoutConstraint] = [NSLayoutConstraint]()
    
    lazy private var cellItems: [ActionSheetCellItem] = {
        var items: [ActionSheetCellItem] = [
            ActionSheetCellItem(imageIdentifier:"playback", title:NSLocalizedString("PLAYBACK_SPEED", comment: "")),
            ActionSheetCellItem(imageIdentifier:"filter", title:NSLocalizedString("VIDEO_FILTER", comment: "")),
            ActionSheetCellItem(imageIdentifier:"equalizer", title:NSLocalizedString("EQUALIZER_CELL_TITLE", comment: "")),
            ActionSheetCellItem(imageIdentifier:"iconLock", title:NSLocalizedString("INTERFACE_LOCK_BUTTON", comment: "")),
            ActionSheetCellItem(imageIdentifier:"speedIcon", title:NSLocalizedString("BUTTON_SLEEP_TIMER", comment: ""))
        ]
        return items
    }()
    
    lazy fileprivate var greenView: UIViewController = {
       let gView = UIViewController()
        gView.view.backgroundColor = .green
        gView.view.frame = CGRect(x: 0, y: 200, width: 375, height: 175)
        add(childViewController: gView)
        return gView
    }()
    
    lazy fileprivate var blueView: UIViewController = {
        let bView = UIViewController()
        bView.view.backgroundColor = .blue
        bView.view.frame = CGRect(x: 0, y: 200, width: 375, height: 175)
        add(childViewController: bView)
        return bView
    }()
    
    // MARK: Private Methods
    private func add(childViewController child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        setupConstraints(ofSubview: child.view)
        child.didMove(toParent: self)
    }
    
    private func remove(childViewController child: UIViewController) {
        child.didMove(toParent: nil)
        NSLayoutConstraint.deactivate(currentConstraints)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }
    
    private func setupConstraints(ofSubview subview: UIView) {
        currentConstraints = [
            subview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subview.topAnchor.constraint(equalTo: view.topAnchor),
            subview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(currentConstraints)
    }
}

extension MediaMoreOptionsActionSheet: ActionSheetDataSource {
    
    func numberOfRows() -> Int {
        return cellItems.count
    }
    
    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActionSheetCell.identifier,
                                                         for: indexPath) as? ActionSheetCell {
                let cellItem = cellItems[indexPath.row]
                cell.name.text = cellItem.title
                cell.icon.image = UIImage(named: cellItem.imageIdentifier)?.withRenderingMode(.alwaysTemplate)
                cell.icon.tintColor = PresentationTheme.current.colors.cellTextColor
                return cell
        }
        
        assert(false, "MediaMoreOptionsActionSheet: Could not dequeue reusable cell")
        return UICollectionViewCell()
    }
}

extension MediaMoreOptionsActionSheet: ActionSheetDelegate {
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        let row: Int = indexPath.row % 2
        if row == 0 {
            return greenView
        }
        return blueView
    }
    
    func headerViewTitle() -> String? {
        return NSLocalizedString("MORE_OPTIONS_HEADER_TITLE", comment: "")
    }
}
