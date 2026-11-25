/*****************************************************************************
 * QueueViewController.swift
 *
 * Copyright © 2020-2026 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *          Edgar Fouillet <vlc # edgar.fouillet.eu>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *          Pratik Ray <raypratik365@gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension Notification.Name {
    static let VLCDidAppendMediaToQueue = Notification.Name("didAppendMediaToQueue")
    static let VLCDidRemoveMediaFromQueue = Notification.Name("didRemoveMediaFromQueue")
}

@objc(VLCQueueViewControllerDelegate)
protocol QueueViewControllerDelegate {
    @objc optional func queueViewControllerDidDisappear(_ queueViewController: QueueViewController?)
}

class QueueViewFlowLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        self.minimumLineSpacing = 10
        self.minimumInteritemSpacing = 0
        self.sectionHeadersPinToVisibleBounds = true
        self.scrollDirection = .vertical
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.width != collectionView?.bounds.width
    }

    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        if let context = context as? UICollectionViewFlowLayoutInvalidationContext,
           newBounds.width != collectionView?.bounds.width {
            context.invalidateFlowLayoutDelegateMetrics = true
        }
        return context
    }
}

@objc(VLCQueueViewController)
class QueueViewController: UIViewController {
    @IBOutlet weak var queueCollectionView: UICollectionView!
    @IBOutlet weak var artworkBlurView: UIVisualEffectView!

    private var scrolledCellIndex: IndexPath = IndexPath()

    private let sidePadding: CGFloat = 10
    private let topPadding: CGFloat = 8
    private let bottomPadding: CGFloat = 8
    private let liquidGlassSpacing: CGFloat = 8
    private let liquidGlassCornerRadius: CGFloat = 24
    private let legacyCornerRadius: CGFloat = 4
    private let cardWidth: CGFloat = 372
    private let cardSpacing: CGFloat = 8
    private let cardTransportSpacing: CGFloat = 12
    private let cardMinimumMargin: CGFloat = 16
    private let cardCornerRadius: CGFloat = 28
    private let collapsedCardScale: CGFloat = 0.5

    private let darkOverlayAlpha: CGFloat = 0.6

    private var playbackService: PlaybackService {
        get {
            PlaybackService.sharedInstance()
        }
    }

    private var mediaList: VLCMediaList {
        get {
            playbackService.isShuffleMode ? PlaybackService.sharedInstance().shuffledList : PlaybackService.sharedInstance().mediaList
        }
    }

    private var currentlyPlayingMedia: VLCMedia?

    private let medialibraryService: MediaLibraryService

    private lazy var collectionViewLayout = QueueViewFlowLayout()
    private var constraints: [NSLayoutConstraint] = []
    private var topConstraint: NSLayoutConstraint?
    var bottomConstraint: NSLayoutConstraint?

    private var darkOverlayView: UIView = UIView()
    private var darkOverlayViewConstraints: [NSLayoutConstraint] = []
    static var queueTextColor: UIColor {
        if #available(iOS 26.0, *) {
            return .label
        }
        return PresentationTheme.darkTheme.colors.cellTextColor
    }

    private static var queueDetailTextColor: UIColor {
        if #available(iOS 26.0, *) {
            return .secondaryLabel
        }
        return PresentationTheme.darkTheme.colors.cellDetailTextColor
    }

    private static var queueDragPreviewBackgroundColor: UIColor {
        if #available(iOS 26.0, *) {
            return .systemBackground
        }
        return PresentationTheme.darkTheme.colors.background
    }

    private var contentInset: CGFloat {
        if #available(iOS 26.0, *) {
            return liquidGlassSpacing
        }
        return 0
    }

    private var cornerRadius: CGFloat {
        if parent is VideoPlayerViewController {
            return cardCornerRadius
        }
        if #available(iOS 26.0, visionOS 26.0, *) {
            return liquidGlassCornerRadius
        }
        return legacyCornerRadius
    }

    private var darkOverlayColor: UIColor {
        if #available(iOS 26.0, *) {
            return .clear
        }
        return parent is VideoPlayerViewController ? .clear : .black
    }

    private var defaultBackgroundEffect: UIVisualEffect {
#if !os(visionOS)
        if #available(iOS 26.0, *) {
            return UIGlassEffect()
        }
#endif
        return UIBlurEffect(style: .dark)
    }

    private var collapsedCardTransform: CGAffineTransform {
        guard !UIAccessibility.isReduceMotionEnabled,
              let parent = parent as? VideoPlayerViewController,
              let superview = view.superview else {
            return .identity
        }

        let queueButton = parent.mediaNavigationBar.queueButton
        let origin = superview.convert(CGPoint(x: queueButton.bounds.midX, y: queueButton.bounds.midY),
                                       from: queueButton)
        let offset = CGPoint(x: origin.x - view.center.x, y: origin.y - view.center.y)
        return CGAffineTransform(translationX: offset.x, y: offset.y)
            .scaledBy(x: collapsedCardScale, y: collapsedCardScale)
            .translatedBy(x: -offset.x, y: -offset.y)
    }

    private let animationDuration = 0.2

    @objc weak var delegate: QueueViewControllerDelegate?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.darkTheme.colors.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()

        let defaultCenter: NotificationCenter = NotificationCenter.default
        defaultCenter.addObserver(self,
                                  selector: #selector(themeDidChange),
                                  name: .VLCThemeDidChangeNotification,
                                  object: nil)
        defaultCenter.addObserver(self,
                                  selector: #selector(configureAppearance),
                                  name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                                  object: nil)
        defaultCenter.addObserver(self,
                                  selector: #selector(reload),
                                  name: Notification.Name(VLCPlaybackServiceShuffleModeUpdated),
                                  object: nil)
        for name in [VLCPlaybackServicePlaybackDidMoveOnToNextItem,
                     VLCPlaybackServicePlaybackDidResume,
                     VLCPlaybackServicePlaybackDidPause] {
            defaultCenter.addObserver(self,
                                      selector: #selector(reload),
                                      name: Notification.Name(name),
                                      object: nil)
        }
        defaultCenter.addObserver(self,
                                  selector: #selector(queueMediaDidChange),
                                  name: VLCMedia.metaChangedNotification,
                                  object: nil)
        defaultCenter.addObserver(self,
                                  selector: #selector(queueMediaDidChange),
                                  name: Notification.Name(VLCPlaybackServiceMediaDurationDidChange),
                                  object: playbackService)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let delegate = delegate as? VideoPlayerViewController {
            delegate.queueViewControllerDidDisappear(self)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        view.alpha = 0.0
    }

    override func accessibilityPerformEscape() -> Bool {
        guard parent is VideoPlayerViewController else {
            return false
        }
        dismissPlayqueue()
        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didMove(toParent parent: UIViewController?) {
        if let parent = parent {
            darkOverlayView.backgroundColor = darkOverlayColor
            parent.view.addSubview(darkOverlayView)

            darkOverlayViewConstraints = [
                darkOverlayView.topAnchor.constraint(equalTo: parent.view.topAnchor),
                darkOverlayView.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
                darkOverlayView.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
                darkOverlayView.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor)
            ]

            var videoPlayer: VideoPlayerViewController?
            var audioPlayer: AudioPlayerViewController?
            if let parent = parent as? VideoPlayerViewController {
                topConstraint = view.topAnchor.constraint(equalTo: parent.mediaNavigationBar.queueButton.bottomAnchor,
                                                          constant: cardSpacing)
                if parent.isCompactPortraitLayout {
                    bottomConstraint = view.bottomAnchor.constraint(equalTo: parent.videoPlayerControls.transportControls.topAnchor,
                                                                    constant: -cardTransportSpacing)
                } else {
                    bottomConstraint = view.bottomAnchor.constraint(equalTo: parent.queueCardBottomLayoutGuide.bottomAnchor)
                }
                videoPlayer = parent
            } else if let parent = parent as? AudioPlayerViewController {
                topConstraint = view.topAnchor.constraint(equalTo: parent.audioPlayerView.playqueueView.topAnchor)
                bottomConstraint = view.bottomAnchor.constraint(equalTo: parent.audioPlayerView.playqueueView.bottomAnchor)
                darkOverlayView.isHidden = true
                audioPlayer = parent
            }

            parent.view.addSubview(view)

            let safeArea = parent.view.safeAreaLayoutGuide
            view.overrideUserInterfaceStyle = .dark
            configureAppearance()

            if let videoPlayer, videoPlayer.isCompactPortraitLayout {
                constraints = [
                    view.leftAnchor.constraint(equalTo: videoPlayer.mediaNavigationBar.leftAnchor),
                    view.rightAnchor.constraint(equalTo: videoPlayer.mediaNavigationBar.rightAnchor)
                ]
            } else if let videoPlayer {
                let preferredWidth = view.widthAnchor.constraint(equalToConstant: cardWidth)
                preferredWidth.priority = .defaultHigh
                constraints = [
                    view.trailingAnchor.constraint(equalTo: videoPlayer.controlsAreaLayoutGuide.trailingAnchor),
                    view.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor, constant: cardMinimumMargin),
                    preferredWidth
                ]
            } else if let audioPlayer {
                let column = audioPlayer.audioPlayerView.playqueueView
                let fillColumn = view.widthAnchor.constraint(equalTo: column.widthAnchor, constant: -2 * contentInset)
                fillColumn.priority = .defaultHigh
                constraints = [
                    view.centerXAnchor.constraint(equalTo: column.centerXAnchor),
                    view.widthAnchor.constraint(lessThanOrEqualToConstant: LayoutWidth.compact.rawValue),
                    fillColumn
                ]
            }

            if let topConstraint = topConstraint {
                constraints.append(topConstraint)
            }
            if let bottomConstraint = bottomConstraint {
                constraints.append(bottomConstraint)
            }

            NSLayoutConstraint.activate(darkOverlayViewConstraints)
            NSLayoutConstraint.activate(constraints)
            view.layoutIfNeeded()
            reload()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        reload()
    }

    @objc init(medialibraryService: MediaLibraryService) {
        self.medialibraryService = medialibraryService
        super.init(nibName: nil, bundle: nil)
        view.alpha = 0.0
    }

    func show() {
        let isVideoPlayerCard = parent is VideoPlayerViewController
        if isVideoPlayerCard {
            // Materialize the glass rather than fading its ancestor.
            artworkBlurView.effect = nil
            artworkBlurView.backgroundColor = .clear
            queueCollectionView.alpha = 0.0
            view.alpha = 1.0
        }
        view.transform = collapsedCardTransform
        UIView.animate(withDuration: animationDuration, animations: {
            if isVideoPlayerCard {
                self.artworkBlurView.applyOverlayBackgroundStyle()
                self.queueCollectionView.alpha = 1.0
            } else {
                self.view.alpha = 1.0
            }
            self.view.transform = .identity
            self.darkOverlayView.isHidden = false
        }) { _ in
            self.scrollToCurrentlyPlaying()
        }
    }

    func hide() {
        UIView.animate(withDuration: animationDuration, animations: {
            self.view.alpha = 0.0
            self.darkOverlayView.isHidden = true
        })
    }

    private func scrollToCurrentlyPlaying() {
        guard let currentMedia = playbackService.currentlyPlayingMedia else {
            return
        }

        let currentIndex = mediaList.index(of: currentMedia)

        guard currentIndex != NSNotFound else {
            return
        }

        guard currentIndex < mediaList.count else {
            return
        }

        let currentIndexPath = IndexPath(row: Int(currentIndex), section: 0)

        // Dispatch the scrolling operation to the main queue to ensure UI updates are processed first
        DispatchQueue.main.async {
            self.queueCollectionView.scrollToItem(at: currentIndexPath, at: .centeredVertically, animated: true)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func dismissFromAudioPlayer() {
        UIView.animate(withDuration: animationDuration, animations: {
            self.view.alpha = 0.0
        }, completion: { _ in
            self.view.removeFromSuperview()
            self.removeFromParent()
        })
    }

    @objc func dismissPlayqueue() {
        if let parent = parent as? VideoPlayerViewController {
            UIView.animate(withDuration: animationDuration, animations: {
                self.artworkBlurView.effect = nil
                self.artworkBlurView.backgroundColor = .clear
                self.queueCollectionView.alpha = 0.0
                self.view.transform = self.collapsedCardTransform
            }, completion: { _ in
                self.view.transform = .identity
                self.dismissPlayqueueCompletion(in: parent)
                self.queueCollectionView.alpha = 1.0
            })
            return
        }

        if let parent = parent {
            bottomConstraint?.constant = view.frame.height - view.safeAreaInsets.bottom
            UIView.animate(withDuration: animationDuration, animations: {
                parent.view.layoutIfNeeded()
            }, completion: { _ in
                self.dismissPlayqueueCompletion(in: parent)
            })
        }
    }

    func dismissPlayqueueCompletion(in parent: UIViewController) {
        view.alpha = 0.0
        view.removeFromSuperview()
        removeFromParent()
        darkOverlayView.isHidden = true
    }

    @objc func reload() {
        currentlyPlayingMedia = playbackService.currentlyPlayingMedia
        queueCollectionView.reloadData()
        queueCollectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - Private initializers

private extension QueueViewController {
    private func initViews() {
        Bundle.main.loadNibNamed("QueueView", owner: self, options: nil)

        view.backgroundColor = .clear

        view.translatesAutoresizingMaskIntoConstraints = false
        initDarkOverlayView()
        initQueueCollectionView()
        themeDidChange()
    }

    private func initDarkOverlayView() {
        darkOverlayView.alpha = darkOverlayAlpha
        darkOverlayView.isHidden = true
        darkOverlayView.isUserInteractionEnabled = true
        darkOverlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPlayqueue)))
        darkOverlayView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func initQueueCollectionView() {
        view.layer.masksToBounds = true
        view.layer.cornerRadius = legacyCornerRadius
        queueCollectionView.translatesAutoresizingMaskIntoConstraints = false
        let cellNib = UINib(nibName: MediaCollectionViewCell.nibName, bundle: nil)
        queueCollectionView.register(cellNib,
                                     forCellWithReuseIdentifier: MediaCollectionViewCell.defaultReuseIdentifier)
        queueCollectionView.delegate = self
        queueCollectionView.dataSource = self
        queueCollectionView.dragDelegate = self
        queueCollectionView.dropDelegate = self
        queueCollectionView.dragInteractionEnabled = true
        queueCollectionView.collectionViewLayout = collectionViewLayout
        queueCollectionView.backgroundColor = .clear
    }

    @objc private func configureAppearance() {
        if parent is VideoPlayerViewController {
            artworkBlurView.applyOverlayBackgroundStyle()
        } else {
            artworkBlurView.backgroundColor = .clear
            artworkBlurView.effect = defaultBackgroundEffect
        }

        if #available(iOS 26.0, visionOS 26.0, *) {
            let corners = UICornerConfiguration.uniformCorners(radius: .fixed(cornerRadius))
            artworkBlurView.cornerConfiguration = corners
            queueCollectionView.cornerConfiguration = corners
            view.cornerConfiguration = corners
            view.layer.cornerRadius = 0
            view.layer.masksToBounds = false
            return
        }

        view.layer.masksToBounds = true
        view.layer.cornerRadius = cornerRadius
        queueCollectionView.layer.cornerRadius = 0
    }
}

// MARK: - Private handlers

private extension QueueViewController {
    @objc private func queueMediaDidChange(_ notification: Notification) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.queueMediaDidChange(notification)
            }
            return
        }
        guard let changedMedia = (notification.userInfo?["media"] ?? notification.object) as? VLCMedia else {
            return
        }

        let list = mediaList
        guard list.index(of: changedMedia) != NSNotFound else {
            return
        }
        if notification.name == VLCMedia.metaChangedNotification {
            let canonicalList = playbackService.mediaList
            clearMetadata(for: changedMedia, in: canonicalList)
            if playbackService.isShuffleMode {
                let shuffledList = playbackService.shuffledList
                if shuffledList !== canonicalList {
                    clearMetadata(for: changedMedia, in: shuffledList)
                }
            }
        }
        for indexPath in queueCollectionView.indexPathsForVisibleItems {
            guard indexPath.item < list.count,
                  let media = list.media(at: UInt(indexPath.item)),
                  media.isEqual(changedMedia),
                  let cell = queueCollectionView.cellForItem(at: indexPath) as? MediaCollectionViewCell else {
                continue
            }
            configureQueueMetadata(cell, for: media, libraryMedia: medialibraryService.fetchMedia(with: media.url))
        }
    }

    private func clearMetadata(for changedMedia: VLCMedia, in list: VLCMediaList?) {
        guard let list = list, list.index(of: changedMedia) != NSNotFound else {
            return
        }
        list.lock()
        defer { list.unlock() }
        for index in 0..<list.count {
            if let media = list.media(at: UInt(index)), media.isEqual(changedMedia) {
                media.metaData.clearCache()
            }
        }
    }

    private func configureQueueMetadata(_ cell: MediaCollectionViewCell,
                                        for media: VLCMedia,
                                        libraryMedia: VLCMLMedia?) {
        let title = playbackService.queueTitle(for: media, libraryMedia: libraryMedia, libraryTitle: libraryMedia?.title())

        var details: [String] = []
        if let libraryMedia = libraryMedia, libraryMedia.subtype() == .albumTrack {
            let artist = libraryMedia.albumTrackArtistName()
            if !artist.isEmpty {
                details.append(artist)
            }
            if let album = libraryMedia.album?.title, !album.isEmpty {
                details.append(album)
            }
        }
        let duration = playbackService.queueDuration(for: media, libraryMedia: libraryMedia)
        if !duration.isEmpty {
            details.append(duration)
        }

        cell.titleLabel.text = title
        cell.sizeDescriptionLabel.text = details.joined(separator: " · ")
        cell.accessibilityLabel = ([title] + details).filter { !$0.isEmpty }.joined(separator: ", ")
    }

    @objc private func themeDidChange() {
#if os(iOS)
        setNeedsStatusBarAppearanceUpdate()
#endif
    }

    private func updateCollectionViewCellAppearance(_ cell: MediaCollectionViewCell) {
        let detailTextColor = QueueViewController.queueDetailTextColor

        cell.tintColor = cell.isMediaBeingPlayed ? PresentationTheme.current.colors.orangeUI : detailTextColor
        cell.sizeDescriptionLabel.textColor = detailTextColor
        cell.dragIndicatorImageView.tintColor = detailTextColor

        cell.titleLabel.backgroundColor = .clear
        cell.sizeDescriptionLabel.backgroundColor = .clear
    }

    private func dragPreviewParameters(for indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = queueCollectionView.cellForItem(at: indexPath) else {
            return nil
        }

        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = QueueViewController.queueDragPreviewBackgroundColor.resolvedColor(with: cell.traitCollection)
        return parameters
    }
}

// MARK: - UICollectionViewFlowLayout

extension QueueViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = sidePadding + 5.0 + MediaCollectionViewCell.edgePadding + 2 * MediaCollectionViewCell.interItemPadding
        let height = MediaCollectionViewCell.cellSizeForWidth(collectionView.frame.width,
                                                              safeAreaInsets: collectionView.safeAreaInsets).height
        return CGSize(width: max(floor(collectionView.frame.width - padding), 1), height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        let leftInset = 5.0
        return UIEdgeInsets(top: topPadding, left: leftInset, bottom: bottomPadding, right: sidePadding)
    }
}

// MARK: - UICollectionViewDelegate / MediaCollectionViewCellDelegate

extension QueueViewController: UICollectionViewDelegate, MediaCollectionViewCellDelegate {
    private func selectedItem(in collectionView: UICollectionView, at indexPath: IndexPath) {
        guard indexPath.row < mediaList.count else {
            assertionFailure("QueueViewController: didSelectItemAt: IndexPath out of range.")
            return
        }

        playbackService.playItem(at: UInt(indexPath.row))

        guard let cell = collectionView.cellForItem(at: indexPath) as? MediaCollectionViewCell else {
            assertionFailure("QueueViewController: didSelectItemAt: Cell not a MediaCollectionViewCell")
            return
        }

        cell.setNowPlaying(true)
        reload()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedItem(in: collectionView, at: indexPath)
    }

    func mediaCollectionViewCellHandleDelete(of cell: MediaCollectionViewCell) {
        guard let indexPath = queueCollectionView.indexPath(for: cell) else {
            return
        }
        resetScrollView({ _ in
            let removedMedia = VLCMLMedia(forPlaying: self.mediaList.media(at: UInt(indexPath.row)))

            NotificationCenter.default.post(name: .VLCDidRemoveMediaFromQueue, object: nil)

            self.handleRemoveCurrentMediaIfNeeded(removedMedia, at: indexPath)
        })
    }

    func mediaCollectionViewCellMediaTapped(in cell: MediaCollectionViewCell) {
        guard let indexPath = queueCollectionView.indexPath(for: cell) else {
            return
        }
        selectedItem(in: queueCollectionView, at: indexPath)
    }

    func mediaCollectionViewCellSetScrolledCellIndex(of cell: MediaCollectionViewCell?) {
        if let cell = cell {
            guard let indexPath = queueCollectionView.indexPath(for: cell) else {
                return
            }

            scrolledCellIndex = indexPath
        }
    }

    func mediaCollectionViewCellGetScrolledCell() -> MediaCollectionViewCell? {
        if scrolledCellIndex.isEmpty {
            return nil
        }

        let cell = queueCollectionView.cellForItem(at: scrolledCellIndex)
        if let cell = cell as? MediaCollectionViewCell {
            return cell
        }

        return nil
    }

    func mediaCollectionViewCellGetModel() -> MediaLibraryBaseModel? {
        return nil
    }
}

// MARK: - UIScrollViewDelegate

extension QueueViewController: UIScrollViewDelegate {
    private func resetScrollView(_ completion: ((Bool) -> Void)? = nil) {
        if let mediaCell = mediaCollectionViewCellGetScrolledCell() {
            mediaCell.resetScrollView(completion)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        resetScrollView()
    }
}

// MARK: - UICollectionViewDataSource

extension QueueViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return mediaList.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell =
                collectionView.dequeueReusableCell(withReuseIdentifier: MediaCollectionViewCell.defaultReuseIdentifier,
                                                   for: indexPath) as? MediaCollectionViewCell else {
            return UICollectionViewCell()
        }

        guard indexPath.row < mediaList.count else {
            assertionFailure("QueueViewController: cellForItemAt: IndexPath out of range.")
            return UICollectionViewCell()
        }

        cell.delegate = self

        cell.thumbnailWidth.constant = MediaCollectionViewCell.getDefaultConstant()

        cell.ignoreThemeDidChange = true
        cell.setTheme(to: PresentationTheme.darkTheme)
        cell.backgroundColor = .clear
        cell.scrollContentView.backgroundColor = .clear

        cell.isEditing = false
        cell.dragIndicatorImageView.isHidden = collectionView.numberOfItems(inSection: 0) <= 1
        guard let media = mediaList.media(at: UInt(indexPath.row)),
              let safeURL = media.url else {
            assertionFailure("QueueViewController: cellForItemAt: Failed to fetch media url")
            return cell
        }
        let libraryMedia = medialibraryService.fetchOrCreateMedia(with: safeURL)
        if let libraryMedia = libraryMedia {
            cell.media = libraryMedia
        }
        configureQueueMetadata(cell, for: media, libraryMedia: libraryMedia)

        let isCurrentlyPlaying = media == currentlyPlayingMedia
        cell.setNowPlaying(isCurrentlyPlaying)
        updateCollectionViewCellAppearance(cell)
        cell.newLabel.isHidden = true

        return cell
    }
}

// MARK: - UICollectionViewDragDelegate

extension QueueViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        guard mediaList.count > 1 else {
            return []
        }

        return [UIDragItem(itemProvider: NSItemProvider())]
    }

    func collectionView(_ collectionView: UICollectionView,
                        dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView,
                        dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return dragPreviewParameters(for: indexPath)
    }
}

// MARK: - UICollectionViewDropDelegate

extension QueueViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.localDragSession != nil
    }

    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard collectionView.hasActiveDrag else {
            return UICollectionViewDropProposal(operation: .cancel)
        }

        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else {
            return
        }

        let mediaList = self.mediaList
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: mediaList.count - 1, section: 0)
        guard sourceIndexPath.row < mediaList.count,
              destinationIndexPath.row < mediaList.count else {
            return
        }

        collectionView.performBatchUpdates({
            mediaList.lock()
            defer { mediaList.unlock() }
            guard let media = mediaList.media(at: UInt(sourceIndexPath.row)),
                  mediaList.removeMedia(at: UInt(sourceIndexPath.row)) else {
                return
            }
            mediaList.insert(media, at: UInt(destinationIndexPath.row))
            collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
        })
        playbackService.setNeedsMediaListSave()

        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath).addCompletion { _ in
            (collectionView.cellForItem(at: destinationIndexPath) as? MediaCollectionViewCell)?.animateCurrentlyPlayingState()
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return dragPreviewParameters(for: indexPath)
    }
}

// MARK: - Media Collection View Cell Queue Remove/ Empty Media List handler

extension QueueViewController {
    func handleRemoveCurrentMediaIfNeeded(_ media: VLCMLMedia?, at index: IndexPath) {
        guard mediaList.count > 1,
              let currentMedia = playbackService.currentlyPlayingLibraryMedia,
              let mlMedia = media,
              mlMedia.identifier() == currentMedia.identifier() else {
            performDeleteMediaFromQueue(at: index)
            return
        }

        let repeatMode = playbackService.repeatMode

        // avoiding UI Crash when removing the last index in the media list
        if (repeatMode == .doNotRepeat || repeatMode == .repeatCurrentItem) &&
            index.row == mediaList.count - 1 {
            performDeleteMediaFromQueue(at: index, isLastMedia: true)
        } else {
            performDeleteMediaFromQueue(at: index)
        }
    }

    func performDeleteMediaFromQueue(at index: IndexPath, isLastMedia: Bool = false) {
        // handle removing last media
        if isLastMedia {
            // cases of doNotReapeat and repeatCurrentItem using the next() method causes wrong updates in the collection view which breaks the UI.
            // playing the index - 1 is the solution for this case
            playbackService.playItem(at: UInt(index.row - 1))
            playbackService.removeMediaFromMediaList(at: UInt(index.row))
        } else {
            // removes the media form the media list and updates the currentIndex, then plays the next
            playbackService.removeMediaFromMediaList(at: UInt(index.row))
        }
    }
}
