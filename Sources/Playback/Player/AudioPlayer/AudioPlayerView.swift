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
    func audioPlayerViewDelegateGetBrightnessSlider(_ audioPlayerView: AudioPlayerView) -> BrightnessControlView
    func audioPlayerViewDeleagteGetVolumeSlider(_ audioPlayerView: AudioPlayerView) -> VolumeControlView
}

class AudioPlayerView: UIView {
    // MARK: - Properties

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var thumbnailView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playqueueView: UIView!
    @IBOutlet weak var controlsStackView: UIStackView!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!

    @IBOutlet weak var progressionView: UIView!

    @IBOutlet weak var thumbnailImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var thumbnailImageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressionViewBottomConstraint: NSLayoutConstraint!

    weak var delegate: AudioPlayerViewDelegate?

    // MARK: - Init

    override func awakeFromNib() {
        overlayView.backgroundColor = .black.withAlphaComponent(0.4)
        setupLabels()
        applyCornerRadius()
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

        let factor: CGFloat
        var constant: CGFloat = 30.0
        let width = UIScreen.main.bounds.width
        if width <= DeviceDimensions.iPhone4sPortrait.rawValue {
            if UIScreen.main.bounds.height == DeviceDimensions.iPhone5Landscape.rawValue {
                factor = 0.5
            } else {
                factor = 0.2
            }
        } else if width <= DeviceDimensions.iPhone6Portrait.rawValue {
            factor = 0.65
        } else {
            factor = 0.8
            constant = 40.0
        }

        thumbnailImageViewWidthConstraint.constant = width * factor
        thumbnailImageViewBottomConstraint.constant = constant
    }

    func setupBackgroundColor() {
        backgroundView.backgroundColor = thumbnailImageView.image?.averageColor
    }

    func setupLabels() {
        titleLabel.textColor = .white
        artistLabel.textColor = .white
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
        backwardButton.tintColor = .white

        previousButton.contentMode = .scaleAspectFit
        previousButton.imageView?.contentMode = .scaleAspectFit
        previousButton.setTitle("", for: .normal)
        previousButton.tintColor = .white

        playButton.contentMode = .scaleAspectFit
        playButton.imageView?.contentMode = .scaleAspectFit
        playButton.setTitle("", for: .normal)
        playButton.tintColor = .white

        nextButton.contentMode = .scaleAspectFit
        nextButton.imageView?.contentMode = .scaleAspectFit
        nextButton.setTitle("", for: .normal)
        nextButton.tintColor = .white

        forwardButton.contentMode = .scaleAspectFit
        forwardButton.imageView?.contentMode = .scaleAspectFit
        forwardButton.setTitle("", for: .normal)
        forwardButton.tintColor = .white

        setupSliders()
    }

    func setupProgressView(with view: MediaScrubProgressBar) {
        let constant: CGFloat
        if UIScreen.main.bounds.width <= DeviceDimensions.iPhone4sPortrait.rawValue {
            constant = 40
        } else {
            constant = 60
        }

        progressionViewBottomConstraint.constant = constant

        let padding: CGFloat = 25.0
        view.translatesAutoresizingMaskIntoConstraints = false
        progressionView.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor, constant: padding),
            view.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor, constant: -padding),
            view.bottomAnchor.constraint(equalTo: progressionView.bottomAnchor),
        ])
    }

    func setupExternalOutputView(with externalOutputView: UIView) {
        addSubview(externalOutputView)

        let constant: CGFloat = 320
        NSLayoutConstraint.activate([
            externalOutputView.heightAnchor.constraint(equalToConstant: constant),
            externalOutputView.widthAnchor.constraint(equalToConstant: constant),
            externalOutputView.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
            externalOutputView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
        ])
    }

    func updateLabels(title: String?, artist: String?, isQueueHidden: Bool) {
        if isQueueHidden {
            titleLabel.isHidden = false
            artistLabel.isHidden = false

            titleLabel.text = title
            artistLabel.text = artist
        } else {
            titleLabel.isHidden = true
            artistLabel.isHidden = true
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

    // MARK: - Private methods

    private func setupCommonSliderConstraints(for slider: UIView) {
        let heightConstraint = slider.heightAnchor.constraint(lessThanOrEqualToConstant: 170)
        let topConstraint = slider.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor)
        let bottomConstraint = slider.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -10)
        let yConstraint = slider.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor)

        heightConstraint.priority = .required
        topConstraint.priority = .defaultHigh
        bottomConstraint.priority = .defaultHigh
        yConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            heightConstraint,
            topConstraint,
            bottomConstraint,
            slider.widthAnchor.constraint(equalToConstant: 50),
            yConstraint,
        ])
    }

    private func setupSliders() {
        let brightnessControlView = delegate?.audioPlayerViewDelegateGetBrightnessSlider(self)
        let volumeControlView = delegate?.audioPlayerViewDeleagteGetVolumeSlider(self)

        if let brightnessControlView = brightnessControlView,
           let volumeControlView = volumeControlView {
            thumbnailView.addSubview(brightnessControlView)
            thumbnailView.addSubview(volumeControlView)

            setupCommonSliderConstraints(for: brightnessControlView)
            setupCommonSliderConstraints(for: volumeControlView)

            NSLayoutConstraint.activate([
                brightnessControlView.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor),
                volumeControlView.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor)
            ])
        }
    }

    private func applyCornerRadius() {
        let cornerRadius = UIScreen.main.displayCornerRadius
        overlayView.layer.cornerRadius = cornerRadius
        backgroundView.layer.cornerRadius = cornerRadius
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
