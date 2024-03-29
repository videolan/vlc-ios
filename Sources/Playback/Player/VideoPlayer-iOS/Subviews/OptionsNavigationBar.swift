/*****************************************************************************
 * OptionsNavigationBar.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 * Copyright © 2020 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import AVKit

@objc enum OptionsNavigationBarIdentifier: Int {
    case videoFilters
    case playbackSpeed
    case equalizer
    case sleepTimer
    case abRepeat
    case abRepeatMarks
}

protocol OptionsNavigationBarDelegate: AnyObject {
    func optionsNavigationBarDisplayAlert(title: String, message: String, button: UIButton)
    func optionsNavigationBarGetRemainingTime() -> String
}

class OptionsNavigationBar: UIStackView {
    // MARK: - Instance Variables
    weak var delegate: OptionsNavigationBarDelegate?

    lazy var videoFiltersButton: UIButton = {
        var videoFiltersButton = UIButton(type: .system)
        videoFiltersButton.addTarget(self, action: #selector(handleVideoFiltersTap), for: .touchUpInside)
        let image = UIImage(named: "filter")?.withRenderingMode(.alwaysTemplate)
        videoFiltersButton.setImage(image, for: .normal)
        videoFiltersButton.tintColor = PresentationTheme.current.colors.orangeUI
        videoFiltersButton.imageView?.contentMode = .scaleAspectFit
        videoFiltersButton.accessibilityLabel = NSLocalizedString("VIDEO_FILTER", comment: "")
        videoFiltersButton.contentHorizontalAlignment = .right
        videoFiltersButton.isHidden = true
        videoFiltersButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return videoFiltersButton
    }()

    lazy var playbackSpeedButton: UIButton = {
        var playbackSpeedButton = UIButton(type: .system)
        playbackSpeedButton.addTarget(self, action: #selector(handlePlaybackSpeedTap), for: .touchUpInside)
        let image = UIImage(named: "playback")?.withRenderingMode(.alwaysTemplate)
        playbackSpeedButton.setImage(image, for: .normal)
        playbackSpeedButton.tintColor = PresentationTheme.current.colors.orangeUI
        playbackSpeedButton.imageView?.contentMode = .scaleAspectFit
        playbackSpeedButton.accessibilityLabel = NSLocalizedString("PLAYBACK_SPEED", comment: "")
        playbackSpeedButton.contentHorizontalAlignment = .right
        playbackSpeedButton.isHidden = true
        playbackSpeedButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return playbackSpeedButton
    }()

    lazy var equalizerButton: UIButton = {
        var equalizerButton = UIButton(type: .system)
        equalizerButton.addTarget(self, action: #selector(handleEqualizerTap), for: .touchUpInside)
        let image = UIImage(named: "equalizer")?.withRenderingMode(.alwaysTemplate)
        equalizerButton.setImage(image, for: .normal)
        equalizerButton.tintColor = PresentationTheme.current.colors.orangeUI
        equalizerButton.imageView?.contentMode = .scaleAspectFit
        equalizerButton.accessibilityLabel = NSLocalizedString("EQUALIZER_CELL_TITLE", comment: "")
        equalizerButton.contentHorizontalAlignment = .right
        equalizerButton.isHidden = true
        equalizerButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return equalizerButton
    }()

    lazy var sleepTimerButton: UIButton = {
        var sleepTimerButton = UIButton(type: .system)
        sleepTimerButton.addTarget(self, action: #selector(handleSleepTimerTap), for: .touchUpInside)
        let image = UIImage(named: "sleepTimer")?.withRenderingMode(.alwaysTemplate)
        sleepTimerButton.setImage(image, for: .normal)
        sleepTimerButton.tintColor = PresentationTheme.current.colors.orangeUI
        sleepTimerButton.imageView?.contentMode = .scaleAspectFit
        sleepTimerButton.accessibilityLabel = NSLocalizedString("BUTTON_SLEEP_TIMER", comment: "")
        sleepTimerButton.contentHorizontalAlignment = .right
        sleepTimerButton.isHidden = true
        sleepTimerButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return sleepTimerButton
    }()

    lazy var abRepeatButton: UIButton = {
        var abRepeatButton = UIButton(type: .system)
        abRepeatButton.addTarget(self, action: #selector(handleABRepeatTap), for: .touchUpInside)
        let image = UIImage(named: "abRepeat")?.withRenderingMode(.alwaysTemplate)
        abRepeatButton.setImage(image, for: .normal)
        abRepeatButton.tintColor = PresentationTheme.current.colors.orangeUI
        abRepeatButton.imageView?.contentMode = .scaleAspectFit
        abRepeatButton.accessibilityLabel = NSLocalizedString("AB_LOOP", comment: "")
        abRepeatButton.contentHorizontalAlignment = .right
        abRepeatButton.isHidden = true
        abRepeatButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return abRepeatButton
    }()

    lazy var abRepeatMarksButton: UIButton = {
        var abRepeatMarksButton = UIButton(type: .system)
        abRepeatMarksButton.addTarget(self, action: #selector(handleABRepeatMarksTap), for: .touchUpInside)
        let image = UIImage(named: "abRepeatMarker")?.withRenderingMode(.alwaysTemplate)
        abRepeatMarksButton.setImage(image, for: .normal)
        abRepeatMarksButton.tintColor = PresentationTheme.current.colors.orangeUI
        abRepeatMarksButton.imageView?.contentMode = .scaleAspectFit
        abRepeatMarksButton.accessibilityLabel = NSLocalizedString("AB_LOOP_MARKS", comment: "")
        abRepeatMarksButton.contentHorizontalAlignment = .right
        abRepeatMarksButton.isHidden = true
        abRepeatMarksButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return abRepeatMarksButton
    }()

    // MARK: - Initializers
    required init(coder: NSCoder) {
        fatalError("init(coder: NsCoder) not implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    // MARK: - Instance Methods
    private func setupViews() {
        spacing = 20.0
        axis = .horizontal
        alignment = .fill
        translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(videoFiltersButton)
        addArrangedSubview(playbackSpeedButton)
        addArrangedSubview(equalizerButton)
        addArrangedSubview(sleepTimerButton)
        addArrangedSubview(abRepeatMarksButton)
        addArrangedSubview(abRepeatButton)
    }

    // MARK: - Button Actions
    @objc private func handleVideoFiltersTap() {
        let title = NSLocalizedString("VIDEO_FILTER", comment: "")
        let message = NSLocalizedString("RESET_VIDEO_FILTERS", comment: "")
        delegate?.optionsNavigationBarDisplayAlert(title: title, message: message, button: videoFiltersButton)
    }

    @objc private func handlePlaybackSpeedTap() {
        let title = NSLocalizedString("PLAYBACK_SPEED", comment: "")
        let message = NSLocalizedString("RESET_PLAYBACK_SPEED", comment: "")
        delegate?.optionsNavigationBarDisplayAlert(title: title, message: message, button: playbackSpeedButton)
    }

    @objc private func handleEqualizerTap() {
        let title = NSLocalizedString("EQUALIZER_CELL_TITLE", comment: "")
        let message = NSLocalizedString("RESET_EQUALIZER", comment: "")
        delegate?.optionsNavigationBarDisplayAlert(title: title, message: message, button: equalizerButton)
    }

    @objc private func handleSleepTimerTap() {
        let title = NSLocalizedString("BUTTON_SLEEP_TIMER", comment: "")
        let firstLine = delegate?.optionsNavigationBarGetRemainingTime() ?? ""
        let secondLine = NSLocalizedString("RESET_SLEEP_TIMER", comment: "")
        let message = firstLine + secondLine
        delegate?.optionsNavigationBarDisplayAlert(title: title, message: message, button: sleepTimerButton)
    }

    @objc private func handleABRepeatTap() {
        let title = NSLocalizedString("AB_LOOP", comment: "")
        let message = NSLocalizedString("RESET_AB_LOOP", comment: "")
        delegate?.optionsNavigationBarDisplayAlert(title: title, message: message, button: abRepeatButton)
    }

    @objc private func handleABRepeatMarksTap() {
        let title = NSLocalizedString("AB_LOOP_MARKS", comment: "")
        let message = NSLocalizedString("RESET_AB_LOOP_MARKS", comment: "")
        delegate?.optionsNavigationBarDisplayAlert(title: title, message: message, button: abRepeatMarksButton)
    }
}
