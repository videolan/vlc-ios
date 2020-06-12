/*****************************************************************************
 * PlaybaclSpeedView.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Carola Nitz <caro@videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc protocol PlaybackSpeedViewDelegate: NSObjectProtocol {
    func playbackSpeedViewShouldResetIdleTimer(_ playbackSpeedView: PlaybackSpeedView)
    func playbackSpeedViewSleepTimerHit(_ playbackSpeedView: PlaybackSpeedView)
}

class PlaybackSpeedView: VLCFrostedGlasView {

    @IBInspectable var nibName: String?
    @IBOutlet weak var playbackSpeedSlider: UISlider!
    @IBOutlet weak var playbackSpeedLabel: UILabel!
    @IBOutlet weak var playbackSpeedIndicator: UILabel!
    @IBOutlet weak var audioDelaySlider: UISlider!
    @IBOutlet weak var audioDelayLabel: UILabel!
    @IBOutlet weak var audioDelayIndicator: UILabel!
    @IBOutlet weak var spuDelaySlider: UISlider!
    @IBOutlet weak var spuDelayLabel: UILabel!
    @IBOutlet weak var spuDelayIndicator: UILabel!
    @IBOutlet weak var sleepTimerButton: UIButton!
    @objc weak var delegate: PlaybackSpeedViewDelegate?
    private var sleepCountDownTimer: Timer?

    let vpc = PlaybackService.sharedInstance()

    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
        playbackSpeedLabel.text = NSLocalizedString("PLAYBACK_SPEED", comment:"")
        playbackSpeedSlider.accessibilityLabel = playbackSpeedLabel.text
        audioDelayLabel.text = NSLocalizedString("AUDIO_DELAY", comment:"")
        audioDelaySlider.accessibilityLabel = audioDelayLabel.text
        spuDelayLabel.text = NSLocalizedString("SPU_DELAY", comment:"")
        spuDelaySlider.accessibilityLabel = spuDelayLabel.text
        sleepTimerButton.setTitle(NSLocalizedString("BUTTON_SLEEP_TIMER", comment:""), for: .normal)
        sleepTimerButton.accessibilityLabel = sleepTimerButton.title(for: .normal)
    }

    func xibSetup() {
        guard let view = loadViewFromNib() else { return }
        view.frame = bounds
        view.autoresizingMask =
            [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }

    func loadViewFromNib() -> PlaybackSpeedView? {
        guard let nibName = nibName else { return nil }
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(
            withOwner: self,
            options: nil).first as? PlaybackSpeedView
    }

    @objc func prepareForMediaPlayback(controller: PlaybackService) {
        let playbackRate = controller.playbackRate
        playbackSpeedSlider.value = log2(playbackRate)
        playbackSpeedIndicator.text = String(format: "%.2fx", playbackRate)

        let audioDelay = controller.audioDelay
        audioDelaySlider.value = audioDelay
        audioDelayIndicator.text = String(format: "%d ms", audioDelay)

        let subtitleDelay = controller.subtitleDelay
        spuDelaySlider.value = subtitleDelay
        spuDelayIndicator.text = String(format: "%d ms", subtitleDelay)
    }

    @objc func updateSleepTimerButton() {
        var title = NSLocalizedString("BUTTON_SLEEP_TIMER", comment:"")

        if vpc.sleepTimer.isValid {
            let remainSeconds = vpc.sleepTimer.fireDate.timeIntervalSinceNow
            let hour = remainSeconds / 3600
            let minute = (remainSeconds - hour * 3600) / 60
            let second = remainSeconds.truncatingRemainder(dividingBy: 60)
            title = title.appendingFormat("  %02d:%02d:%02d", hour, minute, second)
        } else {
            sleepCountDownTimer?.invalidate()
        }

        sleepTimerButton.setTitle(title, for: .normal)
    }

    @objc func setupSleepTimerIfNecessary() {
        if sleepCountDownTimer == nil || !sleepCountDownTimer!.isValid {
            sleepCountDownTimer = Timer(timeInterval: 1, target: self, selector: #selector(updateSleepTimerButton), userInfo: nil, repeats: true)
        }
    }

    @IBAction func sleepTimer(sender: UIButton) {
        delegate?.playbackSpeedViewSleepTimerHit(self)
    }

    @IBAction func playbackSliderAction(sender: UISlider) {
        if sender == playbackSpeedSlider {
            let speed = exp2(sender.value)
            vpc.playbackRate = speed
            playbackSpeedIndicator.text = String(format: "%.2fx", speed)
        } else if sender == audioDelaySlider {
            let delay = round(sender.value / 50) * 50
            vpc.audioDelay = delay
            sender.setValue(delay, animated: false)
            audioDelayIndicator.text = String(format: "%.0f ms", delay)
        } else if sender == spuDelaySlider {
            let delay = round(sender.value / 50) * 50
            vpc.subtitleDelay = delay
            sender.setValue(delay, animated: false)
            spuDelayIndicator.text = String(format: "%.0f ms", delay)
        }
        delegate?.playbackSpeedViewShouldResetIdleTimer(self)
    }

}
