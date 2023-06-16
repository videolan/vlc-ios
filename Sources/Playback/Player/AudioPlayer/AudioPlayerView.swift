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
    func audioPlayerViewDelegateGetVolumeSlider(_ audioPlayerView: AudioPlayerView) -> VolumeControlView
}

class AudioPlayerView: UIView {
    // MARK: - Properties

    private lazy var backgroundView: UIView = UIView()

    private lazy var overlayView: UIView = UIView()

    lazy var navigationBarView: UIView = UIView()

    lazy var thumbnailView: UIView = UIView()

    lazy var thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.contentMode = .scaleAspectFit
        return thumbnailImageView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = .boldSystemFont(ofSize: 17.0)
        return titleLabel
    }()

    private lazy var artistLabel: UILabel = {
        let artistLabel = UILabel()
        artistLabel.textAlignment = .center
        artistLabel.font = .systemFont(ofSize: 16.0)
        return artistLabel
    }()

    lazy var playqueueView: UIView = UIView()

    lazy var controlsStackView: UIStackView = UIStackView()

    private lazy var backwardButton: UIButton = {
        let backwardButton = UIButton(type: .system)
        backwardButton.setImage(UIImage(named: "iconSkipBack"), for: .normal)
        backwardButton.contentMode = .scaleAspectFit
        backwardButton.imageView?.contentMode = .scaleAspectFit
        backwardButton.tintColor = .white
        backwardButton.addTarget(self, action: #selector(handleBackwardButton(_:)), for: .touchUpInside)
        return backwardButton
    }()

    private lazy var previousButton: UIButton = {
        let previousButton = UIButton(type: .system)
        previousButton.setImage(UIImage(named: "previous-media"), for: .normal)
        previousButton.contentMode = .scaleAspectFit
        previousButton.imageView?.contentMode = .scaleAspectFit
        previousButton.tintColor = .white
        previousButton.addTarget(self, action: #selector(handlePreviousButton(_:)), for: .touchUpInside)
        return previousButton
    }()

    private lazy var playButton: UIButton = {
        let playButton = UIButton()
        playButton.setImage(UIImage(named: "iconPlayLarge"), for: .normal)
        playButton.contentMode = .scaleAspectFit
        playButton.imageView?.contentMode = .scaleAspectFit
        playButton.tintColor = .white
        playButton.addTarget(self, action: #selector(handlePlayButton(_:)), for: .touchUpInside)
        return playButton
    }()

    private lazy var nextButton: UIButton = {
        let nextButton = UIButton(type: .system)
        nextButton.setImage(UIImage(named: "next-media"), for: .normal)
        nextButton.contentMode = .scaleAspectFit
        nextButton.imageView?.contentMode = .scaleAspectFit
        nextButton.tintColor = .white
        nextButton.addTarget(self, action: #selector(handleNextButton(_:)), for: .touchUpInside)
        return nextButton
    }()

    private lazy var forwardButton: UIButton = {
        let forwardButton = UIButton(type: .system)
        forwardButton.setImage(UIImage(named: "iconSkipForward"), for: .normal)
        forwardButton.contentMode = .scaleAspectFit
        forwardButton.imageView?.contentMode = .scaleAspectFit
        forwardButton.tintColor = .white
        forwardButton.addTarget(self, action: #selector(handleForwardButton(_:)), for: .touchUpInside)
        return forwardButton
    }()

    lazy var progressionView: UIView = UIView()

    private lazy var layoutGuide: UILayoutGuide = {
        var layoutGuide = layoutMarginsGuide

        if #available(iOS 11.0, *) {
            layoutGuide = safeAreaLayoutGuide
        }

        return layoutGuide
    }()

    private var thumbnailImageViewWidthConstant: CGFloat = 270.0

    private lazy var progressionViewBottomConstant: CGFloat = {
        let isSmallerScreen: Bool = UIScreen.main.bounds.width <= DeviceDimensions.iPhone4sPortrait.rawValue
        return isSmallerScreen ? 40 : 60
    }()

    private lazy var progressionViewBottomConstraint: NSLayoutConstraint = {
        let progressionViewBottomConstraint = progressionView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -progressionViewBottomConstant)
        return progressionViewBottomConstraint
    }()

    weak var delegate: AudioPlayerViewDelegate?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLabels()
        applyCornerRadius()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    func setupViews() {
        setupBackgroundView()
        setupOverlayView()
        setupNavigationBarView()
        setupThumbnailView()
        setupPlayqueueView()
        setupControlsStackView()
        setupProgressionView()
    }

    func setupNavigationBar(with view: MediaNavigationBar) {
        view.translatesAutoresizingMaskIntoConstraints = false

        navigationBarView.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: navigationBarView.leadingAnchor),
            view.topAnchor.constraint(equalTo: navigationBarView.topAnchor),
            view.trailingAnchor.constraint(equalTo: navigationBarView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: navigationBarView.bottomAnchor)
        ])
    }

    func updateThumbnailImageView() {
        thumbnailImageView.image = delegate?.audioPlayerViewDelegateGetThumbnail(self)
        thumbnailImageView.clipsToBounds = true
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

    func setupProgressView(with view: MediaScrubProgressBar) {
        view.translatesAutoresizingMaskIntoConstraints = false
        progressionView.addSubview(view)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: progressionView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: progressionView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: progressionView.bottomAnchor)
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

    func setupSliders() {
        let brightnessControlView = delegate?.audioPlayerViewDelegateGetBrightnessSlider(self)
        let volumeControlView = delegate?.audioPlayerViewDelegateGetVolumeSlider(self)

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

    private func setupBackgroundView() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupOverlayView() {
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .black.withAlphaComponent(0.4)

        addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            overlayView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            overlayView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
    }

    private func setupNavigationBarView() {
        let padding: CGFloat = 10.0
        navigationBarView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(navigationBarView)
        NSLayoutConstraint.activate([
            navigationBarView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: padding),
            navigationBarView.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: padding),
            navigationBarView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -padding)
        ])
    }

    private func setupThumbnailView() {
        let padding: CGFloat = 35.0
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(thumbnailView)
        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            thumbnailView.topAnchor.constraint(equalTo: navigationBarView.bottomAnchor, constant: padding),
            thumbnailView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
        ])

        setupThumbnailSubviews()
    }

    private func setupThumbnailSubviews() {
        let padding: CGFloat = 20.0
        let thumbnailImageViewEdgesPadding: CGFloat = 40.0

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.translatesAutoresizingMaskIntoConstraints = false

        thumbnailView.addSubview(thumbnailImageView)
        thumbnailView.addSubview(titleLabel)
        thumbnailView.addSubview(artistLabel)

        let thumbnailViewHeightConstraint = thumbnailView.heightAnchor.constraint(equalToConstant: thumbnailImageView.frame.height + titleLabel.font.lineHeight + artistLabel.font.lineHeight)
        thumbnailViewHeightConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: thumbnailView.topAnchor, constant: padding),
            thumbnailImageView.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: thumbnailImageViewEdgesPadding),
            thumbnailImageView.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -thumbnailImageViewEdgesPadding),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -padding),
            titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.lineHeight),

            artistLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            artistLabel.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: padding),
            artistLabel.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -padding),
            artistLabel.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -padding),
            artistLabel.heightAnchor.constraint(equalToConstant: artistLabel.font.lineHeight),

            thumbnailViewHeightConstraint
        ])
    }

    private func setupPlayqueueView() {
        playqueueView.translatesAutoresizingMaskIntoConstraints = false
        playqueueView.isHidden = true

        addSubview(playqueueView)
        NSLayoutConstraint.activate([
            playqueueView.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor),
            playqueueView.topAnchor.constraint(equalTo: thumbnailView.topAnchor),
            playqueueView.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor),
            playqueueView.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor)
        ])
    }

    private func setupControlsStackView() {
        let padding: CGFloat = 50.0
        let topPadding: CGFloat = 20.0

        controlsStackView.translatesAutoresizingMaskIntoConstraints = false
        controlsStackView.alignment = .fill
        controlsStackView.distribution = .fillEqually

        addSubview(controlsStackView)
        NSLayoutConstraint.activate([
            controlsStackView.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: topPadding),
            controlsStackView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: padding),
            controlsStackView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -padding),
            controlsStackView.heightAnchor.constraint(equalToConstant: 50.0)
        ])

        controlsStackView.addArrangedSubview(backwardButton)
        controlsStackView.addArrangedSubview(previousButton)
        controlsStackView.addArrangedSubview(playButton)
        controlsStackView.addArrangedSubview(nextButton)
        controlsStackView.addArrangedSubview(forwardButton)
    }

    private func setupProgressionView() {
        let isSmallerScreen: Bool = UIScreen.main.bounds.width <= DeviceDimensions.iPhone4sPortrait.rawValue
        let padding: CGFloat = isSmallerScreen ? 10.0 : 25.0

        progressionView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(progressionView)
        NSLayoutConstraint.activate([
            progressionView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: padding),
            progressionView.topAnchor.constraint(equalTo: controlsStackView.bottomAnchor, constant: padding),
            progressionView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -padding),
            progressionViewBottomConstraint,
            progressionView.heightAnchor.constraint(equalToConstant: 70)
        ])
    }

    private func applyCornerRadius() {
        let cornerRadius = UIScreen.main.displayCornerRadius
        overlayView.layer.cornerRadius = cornerRadius
        backgroundView.layer.cornerRadius = cornerRadius
    }

    // MARK: - Buttons handlers

    @objc func handleBackwardButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapBackwardButton(self)
    }

    @objc func handlePreviousButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapPreviousButton(self)
    }

    @objc func handlePlayButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapPlayButton(self)
    }

    @objc func handleNextButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapNextButton(self)
    }

    @objc func handleForwardButton(_ sender: Any) {
        delegate?.audioPlayerViewDelegateDidTapForwardButton(self)
    }
}
