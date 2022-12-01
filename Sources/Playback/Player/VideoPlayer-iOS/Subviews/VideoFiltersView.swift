/*****************************************************************************
 * VideoFiltersView.swift
 *
 * Copyright © 2020-2022 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *          Maxime Chapelet <umxprime # videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol VideoFiltersViewDelegate: AnyObject {
    func videoFiltersViewShowIcon()
    func videoFiltersViewHideIcon()
}

class VideoFiltersView: UIView {

    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var brightnessSlider: VLCSlider!
    @IBOutlet weak var contrastLabel: UILabel!
    @IBOutlet weak var contrastSlider: VLCSlider!
    @IBOutlet weak var hueLabel: UILabel!
    @IBOutlet weak var hueSlider: VLCSlider!
    @IBOutlet weak var saturationLabel: UILabel!
    @IBOutlet weak var saturationSlider: VLCSlider!
    @IBOutlet weak var gammaLabel: UILabel!
    @IBOutlet weak var gammaSlider: VLCSlider!
    private let resetButton = UIButton()

    weak var delegate: VideoFiltersViewDelegate?

    let vpc = PlaybackService.sharedInstance()


    override func awakeFromNib() {
        setupLabels()
        setupResetButton()
        setupSliders()
        setupTheme()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        guard newSuperview != nil else {
            return
        }
        vpc.adjustFilter.isEnabled ? delegate?.videoFiltersViewShowIcon() : delegate?.videoFiltersViewHideIcon()
        setupSliders()
    }

    func setupTheme() {
        backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        brightnessLabel.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        brightnessSlider.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        contrastLabel.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        contrastSlider.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        hueLabel.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        hueSlider.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        saturationLabel.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        saturationSlider.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        gammaLabel.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        gammaSlider.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
    }

    private func setupLabels() {
        brightnessLabel.text = NSLocalizedString("VFILTER_BRIGHTNESS", comment: "")
        contrastLabel.text = NSLocalizedString("VFILTER_CONTRAST", comment: "")
        hueLabel.text = NSLocalizedString("VFILTER_HUE", comment: "")
        saturationLabel.text = NSLocalizedString("VFILTER_SATURATION", comment: "")
        gammaLabel.text = NSLocalizedString("VFILTER_GAMMA", comment: "")
    }

    private func setupResetButton() {
        resetButton.setImage(UIImage(named: "reset"), for: .normal)
        resetButton.imageView?.contentMode = .scaleAspectFit
        resetButton.tintColor = PresentationTheme.darkTheme.colors.orangeUI
        resetButton.accessibilityLabel = NSLocalizedString("VIDEO_FILTER_RESET_BUTTON", comment: "")
        resetButton.addTarget(self, action: #selector(self.handleResetButton(_:)), for: .touchUpInside)
        resetButton.setContentHuggingPriority(.required, for: .horizontal)
        resetButton.setContentHuggingPriority(.required, for: .vertical)
        resetButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupSlider(_ slider: VLCSlider, _ parameter: PlaybackServiceAdjustFilter.Parameter) {
        slider.minimumValue = parameter.minValue
        slider.maximumValue = parameter.maxValue
        slider.tintColor = PresentationTheme.darkTheme.colors.orangeUI
        slider.setValue(parameter.value, animated: true)
    }

    private func setupSliders() {
        setupSlider(brightnessSlider, vpc.adjustFilter.brightness)
        setupSlider(contrastSlider, vpc.adjustFilter.contrast)
        setupSlider(hueSlider, vpc.adjustFilter.hue)
        setupSlider(saturationSlider, vpc.adjustFilter.saturation)
        setupSlider(gammaSlider, vpc.adjustFilter.gamma)
    }

    func resetIfNeeded() {
        if vpc.adjustFilter.resetParametersIfNeeded() {
            vpc.adjustFilter.isEnabled = false
            setupSliders()
            delegate?.videoFiltersViewHideIcon()
        }
    }

    @IBAction func handleSliderChange(_ sender: VLCSlider) {
        let newValue = sender.value
        if sender.tag == 1 {
            vpc.adjustFilter.brightness.value = newValue
        } else if sender.tag == 2 {
            vpc.adjustFilter.contrast.value = newValue
        } else if sender.tag == 3 {
            vpc.adjustFilter.hue.value = newValue
        } else if sender.tag == 4 {
            vpc.adjustFilter.saturation.value = newValue
        } else if sender.tag == 5 {
            vpc.adjustFilter.gamma.value = newValue
        }
        delegate?.videoFiltersViewShowIcon()
    }

    @objc func handleResetButton(_ sender: UIButton) {
        resetIfNeeded()
    }
}

extension VideoFiltersView: ActionSheetAccessoryViewsDelegate {
    func actionSheetAccessoryViews(_ actionSheet: ActionSheetSectionHeader) -> [UIView] {
        return [resetButton]
    }
}
