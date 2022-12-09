/*****************************************************************************
 * AudioPlayerView.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2022 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol AudioPlayerViewDelegate: AnyObject {
    func audioPlayerViewDelegateGetThumbnail(_ audioPlayerView: AudioPlayerView) -> UIImage?
    func audioPlayerViewDelegateDidTapBackwardButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapPreviousButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapPlayButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapNextButton(_ audioPlayerView: AudioPlayerView)
    func audioPlayerViewDelegateDidTapForwardButton(_ audioPlayerView: AudioPlayerView)
}

class AudioPlayerView: UIView {
    // MARK: - Properties

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var thumbnailView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playqueueView: UIView!
    @IBOutlet weak var controlsStackView: UIStackView!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!

    @IBOutlet weak var progressionView: UIView!

    weak var delegate: AudioPlayerViewDelegate?

    // MARK: - Init

    override func awakeFromNib() {
        overlayView.backgroundColor = .black.withAlphaComponent(0.4)
        setupTitleLabel()
    }

    // MARK: - Public methods

    func setupNavigationBar(with view: MediaNavigationBar) {
        let padding: CGFloat = 10.0

        navigationBarView.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: navigationBarView.centerXAnchor),
            view.leadingAnchor.constraint(equalTo: navigationBarView.leadingAnchor, constant: padding),
            view.trailingAnchor.constraint(equalTo: navigationBarView.trailingAnchor, constant: -padding),
            view.topAnchor.constraint(equalTo: navigationBarView.topAnchor, constant: padding)
        ])
    }

    func setupThumbnailView() {
        thumbnailImageView.image = delegate?.audioPlayerViewDelegateGetThumbnail(self)
        thumbnailImageView.clipsToBounds = true
    }

    func setupBackgroundColor() {
        backgroundView.backgroundColor = thumbnailImageView.image?.averageColor
    }

    func setupTitleLabel() {
        titleLabel.textColor = .white
    }

    func setupPlayqueueView(with qvc: UIView) {
        playqueueView.addSubview(qvc)
        playqueueView.bringSubviewToFront(qvc)
        NSLayoutConstraint.activate([
            qvc.topAnchor.constraint(equalTo: playqueueView.topAnchor),
            qvc.leadingAnchor.constraint(equalTo: playqueueView.leadingAnchor),
            qvc.trailingAnchor.constraint(equalTo: playqueueView.trailingAnchor),
            qvc.bottomAnchor.constraint(equalTo: playqueueView.bottomAnchor)
        ])
    }

    func setupPlayerControls() {
        backwardButton.contentMode = .scaleAspectFit
        backwardButton.imageView?.contentMode = .scaleAspectFit
        backwardButton.setTitle("", for: .normal)

        previousButton.contentMode = .scaleAspectFit
        previousButton.imageView?.contentMode = .scaleAspectFit
        previousButton.setTitle("", for: .normal)

        playButton.contentMode = .scaleAspectFit
        playButton.imageView?.contentMode = .scaleAspectFit
        playButton.setTitle("", for: .normal)

        nextButton.contentMode = .scaleAspectFit
        nextButton.imageView?.contentMode = .scaleAspectFit
        nextButton.setTitle("", for: .normal)

        forwardButton.contentMode = .scaleAspectFit
        forwardButton.imageView?.contentMode = .scaleAspectFit
        forwardButton.setTitle("", for: .normal)
    }

    func setupProgressView(with view: MediaScrubProgressBar) {
        let padding: CGFloat = 25.0

        view.translatesAutoresizingMaskIntoConstraints = false
        progressionView.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor, constant: padding),
            view.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor, constant: -padding),
            view.bottomAnchor.constraint(equalTo: progressionView.bottomAnchor),
        ])
    }

    func updateTitleLabel(with title: String?, isQueueHidden: Bool) {
        if isQueueHidden {
            titleLabel.isHidden = false
            titleLabel.text = title
        } else {
            titleLabel.isHidden = true
        }
    }

    func updatePlayButton(isPlaying: Bool) {
        let icon: UIImage? = isPlaying ? UIImage(named: "iconPauseLarge") : UIImage(named: "iconPlayLarge")
        playButton.setImage(icon, for: .normal)
    }

    func setControlsEnabled(_ enabled: Bool) {
        backwardButton.isEnabled = enabled
        backwardButton.alpha = enabled ? 1.0 : 0.5

        previousButton.isEnabled = enabled
        previousButton.alpha = enabled ? 1.0 : 0.5

        playButton.isEnabled = enabled
        playButton.alpha = enabled ? 1.0 : 0.5

        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1.0 : 0.5

        forwardButton.isEnabled = enabled
        forwardButton.alpha = enabled ? 1.0 : 0.5
    }

    // MARK: - Buttons handlers

    @IBAction func handleBackwardButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapBackwardButton(self)
    }

    @IBAction func handlePreviousButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapPreviousButton(self)
    }

    @IBAction func handlePlayButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapPlayButton(self)
    }

    @IBAction func handleNextButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapNextButton(self)
    }

    @IBAction func handleForwardButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapForwardButton(self)
    }
}
