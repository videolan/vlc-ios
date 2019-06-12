/*****************************************************************************
 * QueueViewController.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

enum QueueViewControllerSectionType: Int, CaseIterable, CustomStringConvertible {
    case currentlyPlaying
    case mediaList

    var description: String {
        switch self {
        case .currentlyPlaying:
            return NSLocalizedString("QUEUE_CURRENT_MEDIA", comment: "")
        case .mediaList:
            return NSLocalizedString("QUEUE_MEDIA_LIST", comment: "")
        }
    }
}

@objc(VLCQueueViewController)
class QueueViewController: UIViewController {
    @IBOutlet private weak var queueCollectionView: UICollectionView!
    @IBOutlet private weak var playerView: UIView!

    private let cellHeight: CGFloat = 56
    private let sectionHeaderHeight: CGFloat = 35

    private let sidePadding: CGFloat = 20
    private let topPadding: CGFloat = 8
    private let bottomPadding: CGFloat = 8

    private lazy var playbackController = VLCPlaybackController.sharedInstance()

    private let medialibraryService: MediaLibraryService

    private lazy var mediaList: VLCMediaList = playbackController.mediaList

    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumLineSpacing = 10
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.sectionHeadersPinToVisibleBounds = true
        collectionViewLayout.headerReferenceSize = CGSize(width: queueCollectionView.frame.width,
                                                          height: sectionHeaderHeight)
        return collectionViewLayout
    }()

    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let longPressGesture = UILongPressGestureRecognizer(target: self,
                                                            action: #selector(handleLongPress))
        return longPressGesture
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification,
                                               object: nil)
        title = NSLocalizedString("QUEUE_TITLE", comment: "")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        navigationController?.navigationBar.isTranslucent = false
        mediaList = playbackController.mediaList
        queueCollectionView.reloadData()
        playbackController.delegate = self
    }

    @objc init(_ medialibraryService: MediaLibraryService) {
        self.medialibraryService = medialibraryService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private initializers

private extension QueueViewController {
    private func initViews() {
        Bundle.main.loadNibNamed("QueueView", owner: self, options: nil)
        view.backgroundColor = PresentationTheme.current.colors.background
        playerView.isHidden = true
        initQueueCollectionView()
        setupNavigationBar()
    }

    private func initQueueCollectionView() {
        let cellNib = UINib(nibName: MediaCollectionViewCell.nibName, bundle: nil)
        queueCollectionView.register(cellNib,
                                     forCellWithReuseIdentifier: MediaCollectionViewCell.defaultReuseIdentifier)
        queueCollectionView.register(QueueCollectionViewSectionHeader.self,
                                     forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                     withReuseIdentifier: QueueCollectionViewSectionHeader.identifier)
        queueCollectionView.delegate = self
        queueCollectionView.dataSource = self
        queueCollectionView.addGestureRecognizer(longPressGesture)
        queueCollectionView.collectionViewLayout = collectionViewLayout
        queueCollectionView.backgroundColor = PresentationTheme.current.colors.background
    }

    private func setupNavigationBar() {
        let crossButtonItem = UIBarButtonItem(image: UIImage(named: "cross"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(dismissView))
        crossButtonItem.accessibilityLabel = NSLocalizedString("BUTTON_DISMISS",
                                                               comment: "")
        crossButtonItem.accessibilityHint = NSLocalizedString("QUEUE_DISMISS_HINT",
                                                              comment: "")
        navigationItem.leftBarButtonItem = crossButtonItem
        navigationItem.leftBarButtonItem?.tintColor = PresentationTheme.current.colors.orangeUI
    }
}

// MARK: - Private handlers

private extension QueueViewController {
    @objc private func themeDidChange() {
        view.backgroundColor = PresentationTheme.current.colors.background
        queueCollectionView.backgroundColor = PresentationTheme.current.colors.background
        setNeedsStatusBarAppearanceUpdate()
    }

    private func updateCollectionViewCellApparence(_ cell: MediaCollectionViewCell, isSelected: Bool) {
        var textColor = PresentationTheme.current.colors.cellTextColor
        var tintColor = PresentationTheme.current.colors.cellDetailTextColor

        if isSelected {
            textColor = PresentationTheme.current.colors.orangeUI
            tintColor = PresentationTheme.current.colors.orangeUI
        }

        cell.tintColor = tintColor
        cell.titleLabel.textColor = textColor
    }

    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let selectedIndexPath = queueCollectionView.indexPathForItem(at:
                gesture.location(in: queueCollectionView)) else {
                    break
            }
            queueCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            queueCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in:
                gesture.view!))
        case .ended:
            queueCollectionView.endInteractiveMovement()
        default:
            queueCollectionView.cancelInteractiveMovement()
        }
    }

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewFlowLayout

extension QueueViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - (sidePadding * 2), height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: topPadding, left: sidePadding, bottom: bottomPadding, right: sidePadding)
    }
}

// MARK: - UICollectionViewDelegate

extension QueueViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == QueueViewControllerSectionType.currentlyPlaying.rawValue {
            // Selected the currently playing item in the currentlyPlaying section: no-op
            return
        }

        guard indexPath.row <= mediaList.count else {
            assertionFailure("QueueViewController: didSelectItemAt: IndexPath out of range.")
            return
        }
        playbackController.playItem(at: UInt(indexPath.row))
        guard let cell = collectionView.cellForItem(at: indexPath) as? MediaCollectionViewCell else {
            assertionFailure("QueueViewController: didSelectItemAt: Cell not a MediaCollectionViewCell")
            return
        }
        updateCollectionViewCellApparence(cell, isSelected: true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath,
                        toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        if proposedIndexPath.section == QueueViewControllerSectionType.currentlyPlaying.rawValue {
            return originalIndexPath
        }
        return proposedIndexPath
    }
}

// MARK: - UICollectionViewDataSource

extension QueueViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // If there is only one item, we only need the "Currently Playing" section
        if mediaList.count == 1 {
            return 1
        }
        return QueueViewControllerSectionType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        switch section {
        case QueueViewControllerSectionType.currentlyPlaying.rawValue:
            return 1
        case QueueViewControllerSectionType.mediaList.rawValue:
            return mediaList.count
        default:
            assertionFailure("QueueViewController: Unknown section header")
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        canMoveItemAt indexPath: IndexPath) -> Bool {
        if indexPath.section == QueueViewControllerSectionType.mediaList.rawValue {
            return true
        }
        return false
    }

    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        guard sourceIndexPath.row <= mediaList.count
            && destinationIndexPath.row <= mediaList.count else {
            assertionFailure("QueueViewController: moveItemAt: IndexPath out of range.")
            return
        }
        let currentMedia = mediaList.media(at: UInt(sourceIndexPath.row))
        mediaList.removeMedia(at: UInt(sourceIndexPath.row))
        mediaList.insert(currentMedia, at: UInt(destinationIndexPath.row))
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell =
            collectionView.dequeueReusableCell(withReuseIdentifier: MediaCollectionViewCell.defaultReuseIdentifier,
                                               for: indexPath) as? MediaCollectionViewCell else {
                                                return UICollectionViewCell()
        }

        guard indexPath.row <= mediaList.count else {
            assertionFailure("QueueViewController: cellForItemAt: IndexPath out of range.")
            return UICollectionViewCell()
        }

        var media: VLCMedia?

        if indexPath.section == QueueViewControllerSectionType.currentlyPlaying.rawValue {
            media = playbackController.currentlyPlayingMedia
            updateCollectionViewCellApparence(cell, isSelected: false)
        } else {
            cell.newLabel.isHidden = true
            media = mediaList.media(at: UInt(indexPath.row))

            let isSelected = playbackController.currentlyPlayingMedia == media
            updateCollectionViewCellApparence(cell, isSelected: isSelected)
        }

        guard let safeMedia = media else {
            assertionFailure("QueueViewController: cellForItemAt: Failed to fetch media")
            return cell
        }
        cell.media = medialibraryService.fetchMedia(with: safeMedia.url)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard let sectionHeader =
            collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                            withReuseIdentifier: QueueCollectionViewSectionHeader.identifier,
                                                            for: indexPath) as? QueueCollectionViewSectionHeader  else {
                                                                return UICollectionReusableView()

        }
        let sectionTypes = QueueViewControllerSectionType.allCases

        guard indexPath.section <= sectionTypes.count else {
            assertionFailure("QueueViewController: viewForSupplementaryElementOfKind: IndexPath out of range.")
            return UICollectionReusableView()
        }

        sectionHeader.title.text = String(describing: sectionTypes[indexPath.section])
        return sectionHeader
    }
}

// MARK: - VLCPlaybackControllerDelegate

extension QueueViewController: VLCPlaybackControllerDelegate {
    func savePlaybackState(_ controller: VLCPlaybackController) {
        medialibraryService.savePlaybackState(from: controller)
    }

    func media(forPlaying media: VLCMedia) -> VLCMLMedia? {
        return medialibraryService.fetchMedia(with: media.url)
    }

    func playbackController(_ playbackController: VLCPlaybackController,
                            nextMedia media: VLCMedia) {
        // Reset only the first cell of the first section, resetting the whole section leads to
        // a header animation which we do not want.
        queueCollectionView.reloadItems(at:
            [IndexPath(item: 0,
                       section: QueueViewControllerSectionType.currentlyPlaying.rawValue)])

        UIView.performWithoutAnimation {
            queueCollectionView.reloadSections(IndexSet(integer: QueueViewControllerSectionType.mediaList.rawValue))
        }
    }
}
