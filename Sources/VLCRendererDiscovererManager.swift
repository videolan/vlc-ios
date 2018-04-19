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

class VLCRendererDiscovererManager: NSObject {
    @objc static let sharedInstance = VLCRendererDiscovererManager(presentingViewController: nil)

    // Array of RendererDiscoverers(Chromecast, UPnP, ...)
    @objc dynamic var discoverers: [VLCRendererDiscoverer] = [VLCRendererDiscoverer]()

    @objc lazy var actionSheet: VLCActionSheet = {
        let actionSheet = VLCActionSheet()
        actionSheet.delegate = self
        actionSheet.dataSource = self
        actionSheet.modalPresentationStyle = .custom
        actionSheet.addAction { [weak self] (item) in
            if let rendererItem = item as? VLCRendererItem {
                self?.setRendererItem(rendererItem: rendererItem)
            }
        }
        return actionSheet
    }()

    @objc var presentingViewController: UIViewController?

    @objc var rendererButttons: [UIButton] = [UIButton]()

    fileprivate init(presentingViewController: UIViewController?) {
        self.presentingViewController = presentingViewController
        super.init()
    }

    // Returns renderers of *all* discoverers
    @objc func getAllRenderers() -> [VLCRendererItem] {
        var renderers = [VLCRendererItem]()

        for discoverer in discoverers {
            renderers += discoverer.renderers
        }
        return renderers
    }

    fileprivate func isDuplicateDiscoverer(with description: VLCRendererDiscovererDescription) -> Bool {
        for discoverer in discoverers {
            if discoverer.name == description.name {
                return true
            }
        }
        return false
    }

    @discardableResult @objc func start() -> Bool {
        // Gather potential renderer discoverers
        guard let tmpDiscoverers: [VLCRendererDiscovererDescription] = VLCRendererDiscoverer.list() else {
            return false
        }
        for discoverer in tmpDiscoverers {
            if !isDuplicateDiscoverer(with: discoverer) {
                if let rendererDiscoverer = VLCRendererDiscoverer(name: discoverer.name) {
                    if rendererDiscoverer.start() {
                        rendererDiscoverer.delegate = self
                        discoverers.append(rendererDiscoverer)
                    } else {
                        print("Unable to start renderer discoverer with name: \(rendererDiscoverer.name)")
                    }
                } else {
                    print("Unable to instanciate renderer discoverer with name: \(discoverer.name)")
                }
            }
        }

        return true
    }

    @objc func stop() {
        for discoverer in discoverers {
            discoverer.stop()
        }
        discoverers.removeAll()
    }

    // MARK: VLCActionSheet
    @objc fileprivate func displayActionSheet() {
        if let presentingViewController = presentingViewController {
            // If only one renderer, choose it automatically
            if getAllRenderers().count == 1 {
                let indexPath = IndexPath(row: 0, section: 0)
                if let rendererItem = getAllRenderers().first {
                    actionSheet.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredVertically)
                    actionSheet(collectionView: actionSheet.collectionView, didSelectItem: rendererItem, At: indexPath)
                    setRendererItem(rendererItem: rendererItem)

                    if let movieViewController = presentingViewController as? VLCMovieViewController {
                        movieViewController.setupCastWithCurrentRenderer()
                    }
                }
            } else {
                presentingViewController.present(actionSheet, animated: false, completion: nil)
            }
        } else {
            print("VLCRendererDiscovererManager: Cannot display actionSheet, no viewController setted")
        }
    }

    fileprivate func setRendererItem(rendererItem: VLCRendererItem) {
        let vpcRenderer = VLCPlaybackController.sharedInstance().renderer

        if vpcRenderer != rendererItem {
            VLCPlaybackController.sharedInstance().renderer = rendererItem
            for button in rendererButttons {
                button.isSelected = true
            }
        } else {
            // Same renderer selected, removing selection
            VLCPlaybackController.sharedInstance().renderer = nil
            for button in rendererButttons {
                button.isSelected = false
            }
        }
    }

    @objc func addSelectionHandler(selectionHandler: ((_ rendererItem: VLCRendererItem) -> Void)?) {
        actionSheet.addAction { [weak self] (item) in
            if let rendererItem = item as? VLCRendererItem {
                self?.setRendererItem(rendererItem: rendererItem)
                if let handler = selectionHandler {
                    handler(rendererItem)
                }
            }
        }
    }

    /// Add the given button to VLCRendererDiscovererManager.
    /// The button state will be handled by the manager.
    ///
    /// - Returns: New `UIButton`
    @objc func setupRendererButton() -> UIButton {
        let button = UIButton()
        button.isHidden = getAllRenderers().isEmpty ? true : false
        button.setImage(UIImage(named: "renderer"), for: .normal)
        button.setImage(UIImage(named: "rendererFull"), for: .selected)
        button.addTarget(self, action: #selector(displayActionSheet), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("BUTTON_RENDERER", comment: "")
        button.accessibilityHint = NSLocalizedString("BUTTON_RENDERER_HINT", comment: "")
        rendererButttons.append(button)
        return button
    }
}

// MARK: VLCRendererDiscovererDelegate
extension VLCRendererDiscovererManager: VLCRendererDiscovererDelegate {
    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        for button in rendererButttons {
            if button.isHidden {
                UIView.animate(withDuration: 0.1) {
                    button.isHidden = false
                }
            }
        }
        actionSheet.collectionView.reloadData()
        actionSheet.updateViewConstraints()
    }

    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        if let playbackController = VLCPlaybackController.sharedInstance() {
            // Current renderer has been removed
            if playbackController.renderer == item {
                playbackController.renderer = nil
                if playbackController.isPlaying {
                    // If playing, fall back to local playback
                    if let movieViewController = presentingViewController as? VLCMovieViewController {
                        movieViewController.playingExternallyView.isHidden = true
                    }
                    playbackController.mediaPlayerSetRenderer(nil)
                }
                // Reset buttons state
                for button in rendererButttons {
                    button.isSelected = false
                }
            }
            actionSheet.collectionView.reloadData()
            actionSheet.updateViewConstraints()
        }

        // No more renderers to show
        if getAllRenderers().isEmpty {
            for button in rendererButttons {
                button.isHidden = true
            }
        }
    }
}

// MARK: VLCActionSheetDelegate
extension VLCRendererDiscovererManager: VLCActionSheetDelegate {
    func headerViewTitle() -> String? {
        return NSLocalizedString("HEADER_TITLE_RENDERER", comment: "")
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        let renderers = getAllRenderers()
        if indexPath.row < renderers.count {
            return renderers[indexPath.row]
        }
        return nil
    }

    func actionSheet(collectionView: UICollectionView, didSelectItem item: Any, At indexPath: IndexPath) {
        guard let renderer = item as? VLCRendererItem,
            let cell = collectionView.cellForItem(at: indexPath) as? VLCActionSheetCell else {
                return
        }
        // Handles the case when the same renderer is selected
        if renderer == VLCPlaybackController.sharedInstance().renderer {
            cell.icon.image = UIImage(named: "rendererBlack")
        } else {
            // Reset all cells
            collectionView.reloadData()
            cell.icon.image = UIImage(named: "rendererBlackFull")
            collectionView.layoutIfNeeded()
        }
    }
}

// MARK: VLCActionSheetDataSource
extension VLCRendererDiscovererManager: VLCActionSheetDataSource {
    func numberOfRows() -> Int {
        return getAllRenderers().count
    }

    func actionSheet(collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VLCActionSheetCell.identifier, for: indexPath) as? VLCActionSheetCell else {
                return UICollectionViewCell()
        }
        let renderers = getAllRenderers()
        if indexPath.row < renderers.count {
            let rendererName = renderers[indexPath.row].name
            cell.name.text = rendererName

            cell.icon.image = UIImage(named: "rendererGray")
            if renderers[indexPath.row] == VLCPlaybackController.sharedInstance().renderer {
                cell.icon.image = UIImage(named: "rendererFullOrange")
            }
        } else {
            assertionFailure("VLCRendererDiscovererManager: cellForItemAt: IndexPath out of range")
        }
        return cell
    }
}
