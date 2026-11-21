/*****************************************************************************
 * VLCRendererDiscovererManager.swift
 *
 * Copyright © 2018-2026 VLC authors and VideoLAN
 * Copyright © 2018-2026 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension Notification.Name {
    static let VLCRenderersDidChangeNotification = Notification.Name("VLCRenderersDidChangeNotification")
}

@objc protocol VLCRendererDiscovererManagerDelegate {
    @objc optional func selectedRendererItem(_ item: VLCRendererItem?)
    @objc optional func removedCurrentRendererItem(_ item: VLCRendererItem)
}

class VLCRendererDiscovererManager: NSObject {
    // Array of RendererDiscoverers(Chromecast, UPnP, ...)
    @objc var discoverers: [VLCRendererDiscoverer] = [VLCRendererDiscoverer]()

    @objc weak var delegate: VLCRendererDiscovererManagerDelegate?

    private let rendererButtons = NSHashTable<UIButton>.weakObjects()

    private var rendererItems = [VLCRendererItem]()

    // Returns renderers of *all* discoverers
    @objc func getAllRenderers() -> [VLCRendererItem] {
        return rendererItems
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
            rendererDiscoverer.delegate = self
            guard rendererDiscoverer.start() else {
                print("VLCRendererDiscovererManager: Unable to start renderer discoverer with name: \(rendererDiscoverer.name)")
                continue
            }
            discoverers.append(rendererDiscoverer)
        }
    }

    @objc func stop() {
        for discoverer in discoverers {
            discoverer.stop()
        }
        discoverers.removeAll()
        rendererItems.removeAll()
    }

    // MARK: Renderer menu

    private func rendererMenu() -> UIMenu {
        let renderers = UIDeferredMenuElement.uncached { [weak self] completion in
            completion(self?.rendererActions() ?? [])
        }
        return UIMenu(title: NSLocalizedString("HEADER_TITLE_RENDERER", comment: ""), children: [renderers])
    }

    private func rendererActions() -> [UIMenuElement] {
        let currentRenderer = PlaybackService.sharedInstance().renderer
        return getAllRenderers().map { rendererItem in
            let isCurrentRenderer = rendererItem == currentRenderer
            return UIAction(title: rendererItem.name,
                            image: UIImage(named: "renderer"),
                            state: isCurrentRenderer ? .on : .off) { [weak self] _ in
                self?.selectRenderer(rendererItem)
            }
        }
    }

    private func updateRendererButtons() {
        let showsMenu = getAllRenderers().count > 1
        for button in rendererButtons.allObjects {
            button.showsMenuAsPrimaryAction = showsMenu
            button.contextMenuInteraction?.updateVisibleMenu { $0.replacingChildren(rendererActions()) }
        }
    }

    @objc fileprivate func selectOnlyRenderer() {
        let renderers = getAllRenderers()
        if renderers.count == 1, let rendererItem = renderers.first {
            selectRenderer(rendererItem)
        }
    }

    private func selectRenderer(_ rendererItem: VLCRendererItem) {
        //if we select the same renderer we want to disconnect
        let oldRenderer = PlaybackService.sharedInstance().renderer
        setRendererItem(rendererItem: rendererItem)
        delegate?.selectedRendererItem?(oldRenderer == rendererItem ? nil : rendererItem)
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
        for button in rendererButtons.allObjects {
            button.isSelected = isSelected
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
        button.menu = rendererMenu()
        button.showsMenuAsPrimaryAction = getAllRenderers().count > 1
        button.addTarget(self, action: #selector(selectOnlyRenderer), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("BUTTON_RENDERER", comment: "")
        button.accessibilityHint = NSLocalizedString("BUTTON_RENDERER_HINT", comment: "")
        rendererButtons.add(button)
        return button
    }
}

// MARK: VLCRendererDiscovererDelegate

extension VLCRendererDiscovererManager: VLCRendererDiscovererDelegate {
    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        DispatchQueue.main.async {
            self.rendererItems.append(item)
            for button in self.rendererButtons.allObjects {
                UIView.animate(withDuration: 0.1) {
                    button.isHidden = false
                }
            }
            self.updateRendererButtons()
            NotificationCenter.default.post(name: .VLCRenderersDidChangeNotification, object: self)
        }
    }

    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        DispatchQueue.main.async {
            self.rendererItems.removeAll { $0 == item }
            let playbackController = PlaybackService.sharedInstance()
            // Current renderer has been removed
            if playbackController.renderer == item {
                playbackController.renderer = nil
                self.delegate?.removedCurrentRendererItem?(item)
                // Reset buttons state
                for button in self.rendererButtons.allObjects {
                    button.isSelected = false
                }
            }
            // No more renderers to show
            if self.getAllRenderers().isEmpty {
                for button in self.rendererButtons.allObjects {
                    UIView.animate(withDuration: 0.1) {
                        button.isHidden = true
                    }
                }
            }
            self.updateRendererButtons()
            NotificationCenter.default.post(name: .VLCRenderersDidChangeNotification, object: self)
        }
    }
}
