/*****************************************************************************
 * VLCRendererDiscovererManager.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc protocol VLCRendererDiscovererManagerDelegate {
    @objc optional func removedCurrentRendererItem(_ item: VLCRendererItem)
    @objc optional func addedRendererItem()
    @objc optional func removedRendererItem()
}

class VLCRendererDiscovererManager: NSObject {
    // Array of RendererDiscoverers(Chromecast, UPnP, ...)
    @objc var discoverers: [VLCRendererDiscoverer] = [VLCRendererDiscoverer]()

    @objc weak var delegate: VLCRendererDiscovererManagerDelegate?

    @objc lazy var actionSheet: ActionSheet = {
        let actionSheet = ActionSheet()
        actionSheet.delegate = self
        actionSheet.dataSource = self
        actionSheet.modalPresentationStyle = .custom
        actionSheet.setAction { [weak self] (item) in
            if let rendererItem = item as? VLCRendererItem {
                self?.setRendererItem(rendererItem: rendererItem)
            }
        }
        return actionSheet
    }()

    @objc var presentingViewController: UIViewController?

    @objc var rendererButtons: [UIButton] = [UIButton]()

    @objc init(presentingViewController: UIViewController?) {
        self.presentingViewController = presentingViewController
        super.init()
    }

    // Returns renderers of *all* discoverers
    @objc func getAllRenderers() -> [VLCRendererItem] {
        return discoverers.flatMap { $0.renderers }
    }

    fileprivate func isDuplicateDiscoverer(with description: VLCRendererDiscovererDescription) -> Bool {
        for discoverer in discoverers where discoverer.name == description.name {
            return true
        }
        return false
    }

    @objc func start() {
        // Gather potential renderer discoverers
        guard let tmpDiscoverersDescription: [VLCRendererDiscovererDescription] = VLCRendererDiscoverer.list() else {
            print("VLCRendererDiscovererManager: Unable to retrieve list of VLCRendererDiscovererDescription")
            return
        }
        for discovererDescription in tmpDiscoverersDescription where !isDuplicateDiscoverer(with: discovererDescription) {
            guard let rendererDiscoverer = VLCRendererDiscoverer(name: discovererDescription.name) else {
                print("VLCRendererDiscovererManager: Unable to instanciate renderer discoverer with name: \(discovererDescription.name)")
                continue
            }
            guard rendererDiscoverer.start() else {
                print("VLCRendererDiscovererManager: Unable to start renderer discoverer with name: \(rendererDiscoverer.name)")
                continue
            }
            rendererDiscoverer.delegate = self
            discoverers.append(rendererDiscoverer)
        }
    }

    @objc func stop() {
        for discoverer in discoverers {
            discoverer.stop()
        }
        discoverers.removeAll()
    }

    // MARK: VLCActionSheet

    @objc fileprivate func displayActionSheet() {
        guard let presentingViewController = presentingViewController else {
            assertionFailure("VLCRendererDiscovererManager: Cannot display actionSheet, no viewController setted")
            return
        }
        // If only one renderer, choose it automatically
        if getAllRenderers().count == 1, let rendererItem = getAllRenderers().first {
            let indexPath = IndexPath(row: 0, section: 0)
            actionSheet.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredVertically)
            actionSheet(collectionView: actionSheet.collectionView, cellForItemAt: indexPath)
            actionSheet.action?(rendererItem)
        } else {
            presentingViewController.present(actionSheet, animated: false, completion: nil)
        }
    }

    fileprivate func setRendererItem(rendererItem: VLCRendererItem) {
        let vpcRenderer = PlaybackService.sharedInstance().renderer
        var finalRendererItem: VLCRendererItem?
        var isSelected: Bool = false

        if vpcRenderer != rendererItem {
            finalRendererItem = rendererItem
            isSelected = true
        }

        PlaybackService.sharedInstance().renderer = finalRendererItem
        for button in rendererButtons {
            button.isSelected = isSelected
        }
    }

    @objc func addSelectionHandler(_ selectionHandler: ((_ rendererItem: VLCRendererItem?) -> Void)?) {
        actionSheet.setAction { [weak self] (item) in
            if let rendererItem = item as? VLCRendererItem {
                //if we select the same renderer we want to disconnect
                let oldRenderer = PlaybackService.sharedInstance().renderer
                self?.setRendererItem(rendererItem: rendererItem)
                if let handler = selectionHandler {
                    handler(oldRenderer == rendererItem ? nil : rendererItem)
                }
            }
        }
    }

    /// Add the given button to VLCRendererDiscovererManager.
    /// The button state will be handled by the manager.
    ///
    /// - Returns: New `UIButton`
    @objc func setupRendererButton() -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.isHidden = getAllRenderers().isEmpty
        button.tintColor = PresentationTheme.current.colors.orangeUI
        button.setImage(UIImage(named: "renderer"), for: .normal)
        button.setImage(UIImage(named: "rendererFull"), for: .selected)
        button.addTarget(self, action: #selector(displayActionSheet), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("BUTTON_RENDERER", comment: "")
        button.accessibilityHint = NSLocalizedString("BUTTON_RENDERER_HINT", comment: "")
        rendererButtons.append(button)
        return button
    }
}

// MARK: VLCRendererDiscovererDelegate

extension VLCRendererDiscovererManager: VLCRendererDiscovererDelegate {
    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        for button in rendererButtons {
            UIView.animate(withDuration: 0.1) {
                button.isHidden = false
            }
        }

        if actionSheet.viewIfLoaded?.window != nil {
            actionSheet.collectionView.reloadData()
            actionSheet.updateViewConstraints()
        }
        delegate?.addedRendererItem?()
    }

    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        let playbackController = PlaybackService.sharedInstance()
        // Current renderer has been removed
        if playbackController.renderer == item {
            playbackController.renderer = nil
            delegate?.removedCurrentRendererItem?(item)
            // Reset buttons state
            for button in rendererButtons {
                button.isSelected = false
            }
        }
        if actionSheet.viewIfLoaded?.window != nil {
            actionSheet.collectionView.reloadData()
            actionSheet.updateViewConstraints()
        }
        // No more renderers to show
        if getAllRenderers().isEmpty {
            for button in rendererButtons {
                UIView.animate(withDuration: 0.1) {
                    button.isHidden = true
                }
            }
            actionSheet.removeActionSheet()
        }
        delegate?.removedRendererItem?()
    }

    fileprivate func updateCollectionViewCellApparence(cell: ActionSheetCell, highlighted: Bool) {
        var image = UIImage(named: "renderer")
        var textColor = PresentationTheme.current.colors.cellTextColor
        var tintColor = PresentationTheme.current.colors.cellDetailTextColor

        if highlighted {
            image = UIImage(named: "rendererFull")
            textColor = PresentationTheme.current.colors.orangeUI
            tintColor = PresentationTheme.current.colors.orangeUI
        }

        cell.tintColor = tintColor
        cell.icon.image = image
        cell.name.textColor = textColor
    }
}

// MARK: VLCActionSheetDelegate

extension VLCRendererDiscovererManager: ActionSheetDelegate {
    func headerViewTitle() -> String? {
        return NSLocalizedString("HEADER_TITLE_RENDERER", comment: "")
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        let renderers = getAllRenderers()
        if indexPath.row < renderers.count {
            return renderers[indexPath.row]
        }
        assertionFailure("VLCRendererDiscovererManager: VLCActionSheetDelegate: IndexPath out of range")
        return nil
    }

    func actionSheet(collectionView: UICollectionView, didSelectItem item: Any, At indexPath: IndexPath) {
        guard let renderer = item as? VLCRendererItem,
            let cell = collectionView.cellForItem(at: indexPath) as? ActionSheetCell else {
            assertionFailure("VLCRendererDiscovererManager: VLCActionSheetDelegate: Cell is not a VLCActionSheetCell")
            return
        }
        let isCurrentlySelectedRenderer = renderer == PlaybackService.sharedInstance().renderer

        if !isCurrentlySelectedRenderer {
            collectionView.reloadData()
        } else {
            delegate?.removedCurrentRendererItem?(renderer)
        }
        updateCollectionViewCellApparence(cell: cell, highlighted: isCurrentlySelectedRenderer)
    }
}

// MARK: VLCActionSheetDataSource

extension VLCRendererDiscovererManager: ActionSheetDataSource {
    func numberOfRows() -> Int {
        return getAllRenderers().count
    }

    @discardableResult
    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ActionSheetCell.identifier, for: indexPath) as? ActionSheetCell else {
            assertionFailure("VLCRendererDiscovererManager: VLCActionSheetDataSource: Unable to dequeue reusable cell")
            return UICollectionViewCell()
        }
        let renderers = getAllRenderers()
        if indexPath.row < renderers.count {
            cell.name.text = renderers[indexPath.row].name
            let isSelectedRenderer = renderers[indexPath.row] == PlaybackService.sharedInstance().renderer ? true : false
            updateCollectionViewCellApparence(cell: cell, highlighted: isSelectedRenderer)
        } else {
            assertionFailure("VLCRendererDiscovererManager: VLCActionSheetDataSource: IndexPath out of range")
        }
        return cell
    }
}
