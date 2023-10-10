/*****************************************************************************
 * PlaybackSpeedView.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 * Copyright © 2020 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol PlaybackSpeedViewDelegate: AnyObject {
    func playbackSpeedViewHandleOptionChange(title: String)
    func playbackSpeedViewShowIcon()
    func playbackSpeedViewHideIcon()
    func playbackSpeedViewCanDisplayShortcutView() -> Bool
    func playbackSpeedViewHandleShortcutSwitchChange(displayView: Bool)
}

class PlaybackSpeedView: UIView {

    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var currentButton: UIButton!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var speedSlider: VLCSlider!
    @IBOutlet weak var increaseSpeedButton: UIButton!
    @IBOutlet weak var decreaseSpeedButton: UIButton!
    @IBOutlet weak var optionsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var shortcutView: UIView!
    @IBOutlet weak var shortcutLabel: UILabel!
    @IBOutlet weak var shortcutSwitch: UISwitch!
    private let resetButton = UIButton()

    weak var delegate: PlaybackSpeedViewDelegate?

    private let minDelay: Float = -30000.0
    private let maxDelay: Float = 30000.0
    private let minSpeed: Float = 0.25
    private let maxSpeed: Float = 8.00

    private let increaseDelay: Float = 50.0
    private let decreaseDelay: Float = -50.0
    private let increaseSpeed: Float = 0.05
    private let decreaseSpeed: Float = -0.05

    private var currentSubtitlesDelay: Float = 0.0
    private var currentAudioDelay: Float = 0.0
    private var currentSpeed: Float = 1.0

    private let defaultDelay: Float = 0.0
    private var defaultSpeed: Float = UserDefaults.standard.float(forKey: kVLCSettingPlaybackSpeedDefaultValue)

    let vpc = PlaybackService.sharedInstance()
    let notificationCenter = NotificationCenter.default

    override func awakeFromNib() {
        super.awakeFromNib()

        setupResetButton()
        setupSegmentedControl()
        setupTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(playbackSpeedHasChanged(_:)), name: Notification.Name("ChangePlaybackSpeed"), object: nil)
    }

    func setupTheme() {
        backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        resetButton.setTitleColor(PresentationTheme.currentExcludingWhite.colors.orangeUI, for: .normal)
        resetButton.setTitleColor(PresentationTheme.currentExcludingWhite.colors.orangeUI.withAlphaComponent(0.5), for: .highlighted)
        optionsSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: PresentationTheme.currentExcludingWhite.colors.cellTextColor], for: .normal)
        minLabel.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        currentButton.setTitleColor(PresentationTheme.currentExcludingWhite.colors.orangeUI, for: .normal)
        maxLabel.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        speedSlider.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        increaseSpeedButton.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        decreaseSpeedButton.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
    }

    private func setupResetButton() {
        resetButton.setTitle(NSLocalizedString("BUTTON_RESET", comment: ""), for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 17.0, weight: .semibold)
        resetButton.addTarget(self, action: #selector(self.handleResetTap(_:)), for: .touchUpInside)
        resetButton.setContentHuggingPriority(.required, for: .horizontal)
        resetButton.setContentHuggingPriority(.required, for: .vertical)
        resetButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupSegmentedControl() {
        optionsSegmentedControl.setTitle(NSLocalizedString("PLAYBACK_SPEED", comment: ""), forSegmentAt: 0)
        optionsSegmentedControl.setTitle(NSLocalizedString("SPU_DELAY", comment: ""), forSegmentAt: 1)
        optionsSegmentedControl.setTitle(NSLocalizedString("AUDIO_DELAY", comment: ""), forSegmentAt: 2)
        if vpc.metadata.isAudioOnly {
            optionsSegmentedControl.removeSegment(at: 1, animated: false)
        }
        optionsSegmentedControl.extendAndHyphenateLabels()

        optionsSegmentedControl.selectedSegmentIndex = 0

        optionsSegmentedControl.addTarget(self, action: #selector(self.handleSegmentedControlChange(_:)), for: .valueChanged)
        handleSegmentedControlChange(optionsSegmentedControl)
    }

    private func setupSliderAndButtons() {
        let selectedIndex = optionsSegmentedControl.selectedSegmentIndex
        var currentButtonText: String = ""
        var increaseAccessibilityHint: String = ""
        var decreaseAccessibilityHint: String = ""
        var hideShortcutView: Bool = false

        if selectedIndex == 0 {
            speedSlider.minimumValue = minSpeed
            speedSlider.maximumValue = maxSpeed
            currentSpeed = vpc.playbackRate
            speedSlider.setValue(currentSpeed, animated: true)
            minLabel.text = String(minSpeed)
            maxLabel.text = String(maxSpeed)
            currentButtonText = String(format: "%.2fx", speedSlider.value)
            increaseAccessibilityHint = NSLocalizedString("INCREASE_PLAYBACK_SPEED", comment: "")
            decreaseAccessibilityHint = NSLocalizedString("DECREASE_PLAYBACK_SPEED", comment: "")
        } else {
            speedSlider.minimumValue = minDelay
            speedSlider.maximumValue = maxDelay
            minLabel.text = String(minDelay)
            maxLabel.text = String(maxDelay)

            if selectedIndex == 1 {
                speedSlider.setValue(currentSubtitlesDelay, animated: true)
                increaseAccessibilityHint = NSLocalizedString("INCREASE_SUBTITLES_DELAY", comment: "")
                decreaseAccessibilityHint = NSLocalizedString("DECREASE_SUBTITLES_DELAY", comment: "")
            } else {
                speedSlider.setValue(currentAudioDelay, animated: true)
                increaseAccessibilityHint = NSLocalizedString("INCREASE_AUDIO_DELAY", comment: "")
                decreaseAccessibilityHint = NSLocalizedString("DECREASE_AUDIO_DELAY", comment: "")
            }

            currentButtonText = String(format: "%.0f ms", speedSlider.value)
            hideShortcutView = true
        }

        currentButton.setTitle(currentButtonText, for: .normal)
        increaseSpeedButton.accessibilityLabel = NSLocalizedString("INCREASE_BUTTON", comment: "")
        increaseSpeedButton.accessibilityHint = increaseAccessibilityHint
        decreaseSpeedButton.accessibilityLabel = NSLocalizedString("DECREASE_BUTTON", comment: "")
        decreaseSpeedButton.accessibilityHint = decreaseAccessibilityHint

        if let canDisplayShortcutView = delegate?.playbackSpeedViewCanDisplayShortcutView(),
           canDisplayShortcutView {
            UIView.animate(withDuration: 0.3) {
                self.shortcutView.isHidden = hideShortcutView
                self.shortcutSwitch.isHidden = hideShortcutView
                self.shortcutLabel.isHidden = hideShortcutView
            }
        }
    }

    func setupShortcutView() {
        guard let canDisplayShortcutView = delegate?.playbackSpeedViewCanDisplayShortcutView(), canDisplayShortcutView else {
            shortcutView.isHidden = true
            return
        }

        shortcutView.isHidden = false
        shortcutLabel.text = NSLocalizedString("DISPLAY_PLAYBACK_SPEED_SHORTCUT", comment: "")
        shortcutLabel.accessibilityLabel = NSLocalizedString("DISPLAY_PLAYBACK_SPEED_SHORTCUT", comment: "")
        shortcutLabel.accessibilityHint = NSLocalizedString("DISPLAY_PLAYBACK_SPEED_SHORTCUT_HINT", comment: "")
        shortcutSwitch.isOn = UserDefaults.standard.bool(forKey: kVLCPlayerShowPlaybackSpeedShortcut)
    }

    @objc func playbackSpeedHasChanged(_ notification: NSNotification) {
        setupSliderAndButtons()
    }

    @objc func handleSegmentedControlChange(_ control: UISegmentedControl) {
        let selectedIndex = control.selectedSegmentIndex
        delegate?.playbackSpeedViewHandleOptionChange(title: optionsSegmentedControl.titleForSegment(at: selectedIndex)!)
        setupSliderAndButtons()
    }

    @IBAction func handleSliderMovement(_ sender: VLCSlider) {
        let selectedIndex = optionsSegmentedControl.selectedSegmentIndex
        var currentValue: Float = speedSlider.value
        var currentButtonText: String = ""
        var showIcon: Bool = true

        if selectedIndex == 0 {
            currentSpeed = sender.value
            currentValue = currentSpeed
            currentButtonText = String(format: "%.2fx", currentValue)
            vpc.playbackRate = currentValue
            notificationCenter.post(name: Notification.Name("ChangePlaybackSpeed"), object: nil)
            if currentValue == defaultSpeed {
                showIcon = false
            }
        } else if selectedIndex == 1 {
            currentSubtitlesDelay = sender.value
            currentValue = currentSubtitlesDelay
            currentButtonText = String(format: "%.0f ms", currentValue)
            vpc.subtitleDelay = currentValue

            if currentValue == defaultDelay {
                showIcon = false
            }
        } else {
            currentAudioDelay = sender.value
            currentValue = currentAudioDelay
            currentButtonText = String(format: "%.0f ms", currentValue)
            vpc.audioDelay = currentValue

            if currentValue == defaultDelay {
                showIcon = false
            }
        }

        UIView.performWithoutAnimation {
            currentButton.setTitle(currentButtonText, for: .normal)
            speedSlider.setValue(currentValue, animated: true)
            layoutIfNeeded()
        }

        if showIcon {
            delegate?.playbackSpeedViewShowIcon()
        }
    }

    func resetSlidersIfNeeded() {
        if vpc.playbackRate != currentSpeed ||
           round(vpc.subtitleDelay) != round(currentSubtitlesDelay) ||
           round(vpc.audioDelay) != round(currentAudioDelay) {
            optionsSegmentedControl.selectedSegmentIndex = 0

            currentSpeed = vpc.playbackRate
            currentSubtitlesDelay = defaultDelay
            currentAudioDelay = defaultDelay
            setupSliderAndButtons()

            delegate?.playbackSpeedViewHideIcon()
        }
    }

    @IBAction func handleResetTap(_ sender: UIButton) {
        let selectedIndex = optionsSegmentedControl.selectedSegmentIndex
        if selectedIndex == 0 {
            currentSpeed = defaultSpeed
            vpc.playbackRate = defaultSpeed
            currentButton.setTitle(String(format: "%.2fx", currentSpeed), for: .normal)
            speedSlider.setValue(currentSpeed, animated: true)
            notificationCenter.post(name: Notification.Name("ChangePlaybackSpeed"), object: nil)
        } else if selectedIndex == 1 {
            currentSubtitlesDelay = defaultDelay
            vpc.subtitleDelay = defaultDelay
            currentButton.setTitle(String(format: "%.0f ms", currentSubtitlesDelay), for: .normal)
            speedSlider.setValue(currentSubtitlesDelay, animated: true)
        } else {
            currentAudioDelay = defaultDelay
            vpc.audioDelay = defaultDelay
            currentButton.setTitle(String(format: "%.0f ms", currentAudioDelay), for: .normal)
            speedSlider.setValue(currentAudioDelay, animated: true)
        }

        if currentSpeed == defaultSpeed && currentSubtitlesDelay == defaultDelay && currentAudioDelay == defaultDelay {
            delegate?.playbackSpeedViewHideIcon()
        }
    }

    func reset() {
        defaultSpeed = UserDefaults.standard.float(forKey: kVLCSettingPlaybackSpeedDefaultValue)
        currentSpeed = defaultSpeed
        vpc.playbackRate = currentSpeed
        notificationCenter.post(name: Notification.Name("ChangePlaybackSpeed"), object: nil)

        currentSubtitlesDelay = defaultDelay
        vpc.subtitleDelay = currentSubtitlesDelay

        currentAudioDelay = defaultDelay
        vpc.audioDelay = currentAudioDelay

        setupSliderAndButtons()
    }


    private func computeValue(currentValue: Float, offset: Float, lowerBound: Float, upperBound: Float) -> Float {
        let finalValue: Float = currentValue + offset
        if finalValue >= lowerBound && finalValue <= upperBound {
            return finalValue
        }

        return offset < 0 ? lowerBound : upperBound
    }


    @IBAction func handleIncreaseDecreaseButton(_ sender: UIButton) {
        let selectedIndex = optionsSegmentedControl.selectedSegmentIndex
        var currentValue: Float = speedSlider.value
        var currentButtonText: String = ""

        let speedOffset: Float = sender.tag == 1 ? increaseSpeed : decreaseSpeed
        let delayOffset: Float = sender.tag == 1 ? increaseDelay : decreaseDelay

        var showIcon: Bool = true

        if selectedIndex == 0 {
            currentSpeed = computeValue(currentValue: currentValue, offset: speedOffset, lowerBound: minSpeed, upperBound: maxSpeed)
            currentValue = currentSpeed
            currentButtonText = String(format: "%.2fx", currentValue)
            vpc.playbackRate = currentValue
            notificationCenter.post(name: Notification.Name("ChangePlaybackSpeed"), object: nil)
            if currentValue == defaultSpeed {
                showIcon = false
            }
        } else {
            let finalValue = computeValue(currentValue: currentValue, offset: delayOffset, lowerBound: minDelay, upperBound: maxDelay)

            if selectedIndex == 1 {
                currentSubtitlesDelay = finalValue
                currentValue = currentSubtitlesDelay
                vpc.subtitleDelay = currentValue
            } else {
                currentAudioDelay = finalValue
                currentValue = currentAudioDelay
                vpc.audioDelay = currentValue
            }

            currentButtonText = String(format: "%.0f ms", currentValue)

            if currentValue == defaultDelay {
                showIcon = false
            }
        }

        UIView.performWithoutAnimation {
            currentButton.setTitle(currentButtonText, for: .normal)
            speedSlider.setValue(currentValue, animated: true)
            layoutIfNeeded()
        }

        if showIcon {
            delegate?.playbackSpeedViewShowIcon()
        }

        if currentSpeed == defaultSpeed && currentSubtitlesDelay == defaultDelay && currentAudioDelay == defaultDelay {
            delegate?.playbackSpeedViewHideIcon()
        }
    }

    @IBAction func handleShortcutSwitch(_ sender: Any) {
        let isSwitchOn: Bool = shortcutSwitch.isOn
        UserDefaults.standard.setValue(isSwitchOn, forKey: kVLCPlayerShowPlaybackSpeedShortcut)
        delegate?.playbackSpeedViewHandleShortcutSwitchChange(displayView: isSwitchOn)
    }
}

extension PlaybackSpeedView: ActionSheetAccessoryViewsDelegate {
    func actionSheetAccessoryViews(_ actionSheet: ActionSheetSectionHeader) -> [UIView] {
        return [resetButton]
    }
}
