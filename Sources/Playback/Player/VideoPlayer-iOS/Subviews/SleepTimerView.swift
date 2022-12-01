/*****************************************************************************
 * SleepTimerView.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 * Copyright © 2020 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol SleepTimerViewDelegate: AnyObject {
    func sleepTimerViewCloseActionSheet()
    func sleepTimerViewShowAlert(message: String, seconds: Double)
    func sleepTimerViewHideAlertIfNecessary()
    func sleepTimerViewShowIcon()
    func sleepTimerViewHideIcon()
}

class SleepTimerView: UIView {

    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var setButton: UIButton!

    weak var delegate: SleepTimerViewDelegate?

    private var sleepCountDownTimer: Timer?

    let vpc = PlaybackService.sharedInstance()


    override func awakeFromNib() {
        setupButtons()
        setupTheme()
    }

    func setupTheme() {
        timePicker.setValue(PresentationTheme.currentExcludingWhite.colors.cellTextColor, forKey: "textColor")
        backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        resetButton.setTitleColor(PresentationTheme.currentExcludingWhite.colors.orangeUI, for: .normal)
        setButton.setTitleColor(PresentationTheme.currentExcludingWhite.colors.orangeUI, for: .normal)
    }

    private func setupButtons() {
        resetButton.setTitle(NSLocalizedString("BUTTON_RESET", comment: ""), for: .normal)
        setButton.setTitle(NSLocalizedString("BUTTON_SET", comment: ""), for: .normal)

        if !vpc.sleepTimer.isValid {
            resetButton.isHidden = true
        }

        resetButton.accessibilityLabel = NSLocalizedString("BUTTON_RESET", comment: "")
        resetButton.accessibilityHint = NSLocalizedString("BUTTON_RESET", comment: "")
        setButton.accessibilityLabel = NSLocalizedString("BUTTON_SET", comment: "")
        setButton.accessibilityHint = NSLocalizedString("BUTTON_SET", comment: "")
    }

    func remainingTime() -> String {
        if let timer = sleepCountDownTimer {
            let timeInterval = timer.fireDate
            let remaining = NSInteger(timeInterval.timeIntervalSinceNow)

            let hours = remaining / 3600
            let minutes = (remaining / 60) % 60
            let seconds = remaining % 60

            return String(format: "Remaining time: %0.2d:%0.2d:%0.2d\n", hours, minutes, seconds)
        } else {
            return ""
        }
    }

    @IBAction func handleReset(_ sender: UIButton) {
        sleepCountDownTimer?.invalidate()
        sleepCountDownTimer = nil

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
                        self.resetButton.isHidden = true
                       },
                       completion: { _ in
                        self.delegate?.sleepTimerViewShowAlert(message: NSLocalizedString("SLEEP_TIMER_UPDATED", comment: ""), seconds: 0.5)
                        self.delegate?.sleepTimerViewHideIcon()
                       })
    }

    func reset() {
        sleepCountDownTimer?.invalidate()
        sleepCountDownTimer = nil
        resetButton.isHidden = true
    }


    @objc func timerFiring() {
        delegate?.sleepTimerViewHideAlertIfNecessary()
        delegate?.sleepTimerViewCloseActionSheet()
        delegate?.sleepTimerViewHideIcon()
        resetButton.isHidden = true
        sleepCountDownTimer = nil
        vpc.stopPlayback()
    }

    @IBAction func valueDidChange(_ sender: Any) {
        if #available(iOS 10.0, *) {
            let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            impactFeedbackGenerator.prepare()
            impactFeedbackGenerator.impactOccurred()
        }
    }

    private func updateTimer(interval: TimeInterval) {
        sleepCountDownTimer?.invalidate()
        sleepCountDownTimer = nil

        DispatchQueue.main.async {
            self.sleepCountDownTimer = Timer.scheduledTimer(timeInterval: interval,
                                                            target: self,
                                                            selector: #selector(self.timerFiring),
                                                            userInfo: nil,
                                                            repeats: false)

            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: .curveEaseInOut,
                           animations: {
                            self.resetButton.isHidden = false
                           },
                           completion: { _ in
                            self.delegate?.sleepTimerViewShowAlert(message: NSLocalizedString("SLEEP_TIMER_UPDATED", comment: ""),
                                                                      seconds: 0.5)
                           })
        }
    }


    @IBAction func handleSet(_ sender: UIButton) {
        let timeInSeconds = timePicker.countDownDuration

        updateTimer(interval: timeInSeconds)

        delegate?.sleepTimerViewShowIcon()
    }
}
