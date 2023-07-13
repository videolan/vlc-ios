/*****************************************************************************
 * MediaScrubProgressBar.swift
 *
 * Copyright © 2019-2020 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *          Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc (VLCMediaScrubProgressBarDelegate)
protocol MediaScrubProgressBarDelegate {
    func mediaScrubProgressBarShouldResetIdleTimer()
}

@objc (VLCMediaScrubProgressBar)
class MediaScrubProgressBar: UIStackView {
    @objc weak var delegate: MediaScrubProgressBarDelegate?
    private var playbackService = PlaybackService.sharedInstance()
    private var positionSet: Bool = true
    private(set) var isScrubbing: Bool = false
    var shouldHideScrubLabels: Bool = false
    
    @objc lazy private(set) var progressSlider: VLCOBSlider = {
        var slider = VLCOBSlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.minimumTrackTintColor = PresentationTheme.current.colors.orangeUI
        slider.maximumTrackTintColor = UIColor(white: 1, alpha: 0.2)
        slider.setThumbImage(UIImage(named: "sliderThumb"), for: .normal)
        slider.setThumbImage(UIImage(named: "sliderThumbBig"), for: .highlighted)
        slider.isContinuous = true
        slider.semanticContentAttribute = .forceLeftToRight
        slider.accessibilityIdentifier = VLCAccessibilityIdentifier.videoPlayerScrubBar
        slider.addTarget(self, action: #selector(handleSlide(slider:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(progressSliderTouchDown), for: .touchDown)
        slider.addTarget(self, action: #selector(progressSliderTouchUp), for: .touchUpInside)
        slider.addTarget(self, action: #selector(progressSliderTouchUp), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(updateScrubLabel), for: .touchDragInside)
        slider.addTarget(self, action: #selector(updateScrubLabel), for: .touchDragOutside)
        return slider
    }()
    
    private lazy var elapsedTimeLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont.preferredCustomFont(forTextStyle: .subheadline).bolded
        label.textColor = PresentationTheme.current.colors.orangeUI
        label.text = "--:--"
        label.numberOfLines = 1
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.semanticContentAttribute = .forceLeftToRight
        return label
    }()
    
    private(set) lazy var remainingTimeButton: UIButton = {
        let remainingTimeButton = UIButton(type: .custom)
        remainingTimeButton.addTarget(self,
                                      action: #selector(handleTimeDisplay),
                                      for: .touchUpInside)
        remainingTimeButton.setTitle("--:--", for: .normal)
        remainingTimeButton.setTitleColor(.white, for: .normal)

        // Use a monospace variant for the digits so the width does not jitter as the numbers changes.
        remainingTimeButton.titleLabel?.font = UIFont.preferredCustomFont(forTextStyle: .subheadline).semibolded

        remainingTimeButton.semanticContentAttribute = .forceLeftToRight
        remainingTimeButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return remainingTimeButton
    }()

    private lazy var scrubbingIndicatorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.backgroundColor = UIColor(white: 0, alpha: 0.4)
        return label
    }()

    private lazy var scrubbingHelpLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white
        label.text = NSLocalizedString("PLAYBACK_SCRUB_HELP", comment: "")
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.backgroundColor = UIColor(white: 0, alpha: 0.4)
        label.textAlignment = .center
        return label
    }()

    private lazy var scrubInfoStackView: UIStackView = {
        let scrubInfoStackView = UIStackView(arrangedSubviews: [scrubbingIndicatorLabel, scrubbingHelpLabel])
        scrubInfoStackView.axis = .vertical
        scrubInfoStackView.isHidden = true
        return scrubInfoStackView
    }()
    
    // MARK: Initializers
    required init(coder: NSCoder) {
        fatalError("init(coder: NSCoder) not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()

        NotificationCenter.default.addObserver(self, selector: #selector(handleWillResignActive),
                                               name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc func updateInterfacePosition() {
        if !isScrubbing {
            progressSlider.value = playbackService.playbackPosition
        }
        elapsedTimeLabel.text = playbackService.playedTime().stringValue

        updateCurrentTime()

        elapsedTimeLabel.setNeedsLayout()
    }

    func updateCurrentTime() {
        let timeToDisplay = UserDefaults.standard.bool(forKey: kVLCShowRemainingTime)
            ? playbackService.remainingTime().stringValue
            : VLCTime(number: NSNumber.init(value:playbackService.mediaDuration)).stringValue

        remainingTimeButton.setTitle(timeToDisplay, for: .normal)
        remainingTimeButton.setNeedsLayout()
    }

    func updateSliderWithValue(value: Float) {
        perform(#selector(updatePlaybackPosition), with: nil, afterDelay: 0.3)
        progressSlider.value = value / Float(playbackService.mediaDuration)
        playbackService.playbackPosition = value / Float(playbackService.mediaDuration)

        let newPosition = VLCTime(number: NSNumber.init(value: value))
        elapsedTimeLabel.text = newPosition.stringValue
        elapsedTimeLabel.accessibilityLabel =
            String(format: "%@: %@",
                   NSLocalizedString("PLAYBACK_POSITION", comment: ""),
                   newPosition.stringValue)
        if UserDefaults.standard.bool(forKey: kVLCShowRemainingTime) {
            let newRemainingTime = Int(newPosition.intValue) - playbackService.mediaDuration
            remainingTimeButton.setTitle(VLCTime(number: NSNumber.init(value: newRemainingTime)).stringValue, for: .normal)
            remainingTimeButton.setNeedsLayout()
        }
        elapsedTimeLabel.setNeedsLayout()

        positionSet = false
        delegate?.mediaScrubProgressBarShouldResetIdleTimer()
    }

    func updateBackgroundAlpha(with alpha: CGFloat) {
        scrubbingIndicatorLabel.backgroundColor = UIColor(white: 0, alpha: alpha)
        scrubbingHelpLabel.backgroundColor = UIColor(white: 0, alpha: alpha)
    }
}

// MARK: -

private extension MediaScrubProgressBar {
    private func setupViews() {
        let horizontalStack = UIStackView(arrangedSubviews: [elapsedTimeLabel, remainingTimeButton])
        horizontalStack.distribution = .equalSpacing
        horizontalStack.semanticContentAttribute = .forceLeftToRight
        addArrangedSubview(scrubInfoStackView)
        addArrangedSubview(horizontalStack)
        addArrangedSubview(progressSlider)
        spacing = 5
        axis = .vertical
        translatesAutoresizingMaskIntoConstraints = false

        setVerticalHuggingAndCompressionResistance(to: .required, for: [
            scrubbingHelpLabel,
            scrubbingIndicatorLabel,
            elapsedTimeLabel,
            remainingTimeButton,
            scrubInfoStackView,
            horizontalStack,
            progressSlider
        ])

        elapsedTimeLabel.setContentHuggingPriority(.required, for: .vertical)
        remainingTimeButton.setContentHuggingPriority(.required, for: .vertical)
        scrubInfoStackView.setContentHuggingPriority(.required, for: .vertical)
        horizontalStack.setContentHuggingPriority(.required, for: .vertical)
        progressSlider.setContentHuggingPriority(.required, for: .vertical)
    }

    private func setVerticalHuggingAndCompressionResistance(to priority: UILayoutPriority, for views: [UIView]) {
        for view in views {
            view.setContentHuggingPriority(priority, for: .vertical)
            view.setContentCompressionResistancePriority(priority, for: .vertical)
        }
    }

    @objc private func updateScrubLabel() {
        guard !shouldHideScrubLabels else {
            return
        }

        let speed = progressSlider.scrubbingSpeed
        if  speed == 1 {
            scrubbingIndicatorLabel.text = NSLocalizedString("PLAYBACK_SCRUB_HIGH", comment:"")
        } else if speed == 0.5 {
            scrubbingIndicatorLabel.text = NSLocalizedString("PLAYBACK_SCRUB_HALF", comment: "")
        } else if speed == 0.25 {
            scrubbingIndicatorLabel.text = NSLocalizedString("PLAYBACK_SCRUB_QUARTER", comment: "")
        } else {
            scrubbingIndicatorLabel.text = NSLocalizedString("PLAYBACK_SCRUB_FINE", comment: "")
        }
    }

    @objc private func updatePlaybackPosition() {
        if !positionSet {
            playbackService.playbackPosition = progressSlider.value
            playbackService.setNeedsMetadataUpdate()
            positionSet = true
        }
    }

    // MARK: -

    @objc private func handleTimeDisplay() {
        let userDefault = UserDefaults.standard
        let currentSetting = userDefault.bool(forKey: kVLCShowRemainingTime)
        userDefault.set(!currentSetting, forKey: kVLCShowRemainingTime)

        updateCurrentTime()
        delegate?.mediaScrubProgressBarShouldResetIdleTimer()
    }

    // MARK: - Slider Methods

    @objc private func handleSlide(slider: UISlider) {
        /* we need to limit the number of events sent by the slider, since otherwise, the user
         * wouldn't see the I-frames when seeking on current mobile devices. This isn't a problem
         * within the Simulator, but especially on older ARMv7 devices, it's clearly noticeable. */
        perform(#selector(updatePlaybackPosition), with: nil, afterDelay: 0.3)
        if playbackService.mediaDuration > 0 {
            if !isScrubbing {
                progressSlider.value = playbackService.playbackPosition
            }

            let newPosition = VLCTime(number: NSNumber.init(value: slider.value * Float(playbackService.mediaDuration)))
            elapsedTimeLabel.text = newPosition.stringValue
            elapsedTimeLabel.accessibilityLabel =
                String(format: "%@: %@",
                       NSLocalizedString("PLAYBACK_POSITION", comment: ""),
                       newPosition.stringValue)
            // Update only remaining time and not media duration.
            if UserDefaults.standard.bool(forKey: kVLCShowRemainingTime) {
                let newRemainingTime = Int(newPosition.intValue) - playbackService.mediaDuration
                remainingTimeButton.setTitle(VLCTime(number: NSNumber.init(value:newRemainingTime)).stringValue,
                                             for: .normal)
                remainingTimeButton.setNeedsLayout()
            }

            elapsedTimeLabel.setNeedsLayout()
        }
        positionSet = false
        delegate?.mediaScrubProgressBarShouldResetIdleTimer()
    }

    @objc private func progressSliderTouchDown() {
        updateScrubLabel()
        isScrubbing = true
        scrubInfoStackView.isHidden = shouldHideScrubLabels ? true : !isScrubbing
    }

    @objc private func progressSliderTouchUp() {
        isScrubbing = false
        scrubInfoStackView.isHidden = shouldHideScrubLabels ? true : !isScrubbing
    }

    @objc private func handleWillResignActive() {
        progressSliderTouchUp()
    }
}
