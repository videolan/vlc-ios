/*****************************************************************************
 * MediaScrubProgressBar.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc (VLCMediaProgressBarDelegate)
protocol MediaScrubProgressBarDelegate {
    func didMoveMediaScrubProgressSlider(_ progressBar: MediaScrubProgressBar, sender: UISlider)
}

@objc (VLCMediaProgressBar)
@objcMembers class MediaScrubProgressBar: UIView {
    
    // MARK: Instance Variables
    weak var delegate: MediaScrubProgressBarDelegate?
    
    lazy var progressSlider: UISlider = {
        var slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.minimumTrackTintColor = .orange
        slider.maximumTrackTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
        slider.setThumbImage(UIImage(named: "sliderThumb"), for: .normal)
        slider.thumbTintColor = .orange
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(moveSliderThumb), for: .touchUpInside)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    var elapsedTimeLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Bold", size: 12)
        label.textColor = .orange
        label.text = "000:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var remainingTimeLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Bold", size: 12)
        label.text = "-0000:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: Initializers
    required init(coder: NSCoder) {
        fatalError("init(coder: NSCoder) not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    // MARK: Private Instance Methods
    private func setupConstraints() {
        let margin: CGFloat = 30
        NSLayoutConstraint.activate([
            progressSlider.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressSlider.centerXAnchor.constraint(equalTo: centerXAnchor),
            elapsedTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            elapsedTimeLabel.trailingAnchor.constraint(equalTo: progressSlider.leadingAnchor, constant: margin),
            elapsedTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            remainingTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            remainingTimeLabel.leadingAnchor.constraint(equalTo: progressSlider.trailingAnchor, constant: margin),
            remainingTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: margin),
        ])
    }
    
    private func setupViews() {
        addSubview(elapsedTimeLabel)
        addSubview(progressSlider)
        addSubview(remainingTimeLabel)
    }
    
    // MARK: Slider Action Function
    @objc private func moveSliderThumb() {
        assert(delegate != nil, "Delegate not set for MediaProgressBar")
        delegate?.didMoveMediaScrubProgressSlider(self, sender: progressSlider)
    }
}
