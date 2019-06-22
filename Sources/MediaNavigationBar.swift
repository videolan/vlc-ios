/*****************************************************************************
 * MediaNavigationBar.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc (VLCMediaNavigationBarDelegate)
protocol VLCMediaNavigationBarDelegate {
    func didMinimizePlayback(_ navigationBar: MediaNavigationBar)
    func didToggleChromeCast(_ navigationBar: MediaNavigationBar)
    func didToggleAirPlay(_ navigationBar: MediaNavigationBar)
}

@objc (VLCMediaNavigationBar)
@objcMembers class MediaNavigationBar: UIView {
    
    // MARK: Instance Variables
    weak var delegate:  VLCMediaNavigationBarDelegate?
    
    lazy var minimizePlaybackButton: UIButton = {
        var minButton = UIButton(type: .system)
        minButton.addTarget(self, action: #selector(minimizePlayback), for: .touchUpInside)
        minButton.setImage(UIImage(named: "minimizePlayback"), for: .normal)
        minButton.tintColor = .white
        
        // Constraints
        minButton.translatesAutoresizingMaskIntoConstraints = false
        return minButton
    }()
    
    private var mediaTitleTextLabel: UILabel = {
        var label = UILabel()
        label.numberOfLines = 1
        label.textColor = .white
        label.font = UIFont(name: "SFProDisplay-Medium", size: 17)
        label.text = NSLocalizedString("TITLE", comment: "Video Title")
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var chromeCastButton: UIButton = {
        var chromeButton = UIButton(type: .system)
        chromeButton.addTarget(self, action: #selector(toggleChromeCast), for: .touchUpInside)
        chromeButton.setImage(UIImage(named: "renderer"), for: .normal)
        chromeButton.tintColor = .white
        chromeButton.translatesAutoresizingMaskIntoConstraints = false
        return chromeButton
    }()
    
    lazy var airPlayButton: UIButton = {
        var airPlayButton = UIButton(type: .system)
        airPlayButton.addTarget(self, action: #selector(toggleAirPlay), for: .touchUpInside)
        airPlayButton.setImage(UIImage(named: "TVBroadcastIcon"), for: .normal)
        airPlayButton.tintColor = .white
        airPlayButton.translatesAutoresizingMaskIntoConstraints = false
        return airPlayButton
    }()
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            minimizePlaybackButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            minimizePlaybackButton.topAnchor.constraint(equalTo: self.topAnchor),
            minimizePlaybackButton.widthAnchor.constraint(equalToConstant: minimizePlaybackButton.frame.width),
            minimizePlaybackButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mediaTitleTextLabel.leadingAnchor.constraint(equalTo: minimizePlaybackButton.trailingAnchor, constant: 16),
            mediaTitleTextLabel.topAnchor.constraint(equalTo: self.topAnchor),
            mediaTitleTextLabel.trailingAnchor.constraint(equalTo: chromeCastButton.leadingAnchor, constant: 50),
            chromeCastButton.trailingAnchor.constraint(equalTo: airPlayButton.leadingAnchor, constant: 20),
            chromeCastButton.topAnchor.constraint(equalTo: self.topAnchor),
            chromeCastButton.widthAnchor.constraint(equalToConstant: 24),
            airPlayButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 20),
            airPlayButton.topAnchor.constraint(equalTo: self.topAnchor),
            airPlayButton.widthAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupViews() {
        self.addSubview(minimizePlaybackButton)
        self.addSubview(mediaTitleTextLabel)
        self.addSubview(chromeCastButton)
        self.addSubview(airPlayButton)
        
        if UIApplication.shared.statusBarOrientation.isLandscape {
            mediaTitleTextLabel.isHidden = true
        }
    }
    
    // MARK: Initializers
    required init(coder: NSCoder) {
        fatalError("init(coder: NSCoder) not implemented")
    }
    
    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }
    
    // MARK: Instance Methods
    func setMediaTitleLabelText(_ titleText: String) {
        mediaTitleTextLabel.text = titleText
    }
    
    // Mark: Button Actions
    func minimizePlayback() {
        guard let delegate = delegate else {
            print("Delegate not set for MediaNavigationBar")
            return
        }
    
        delegate.didMinimizePlayback(self)
    }
    
    func toggleChromeCast() {
        guard let delegate = delegate else {
            print("Delegate not set for MediaNavigationBar")
            return
        }
        
        delegate.didToggleChromeCast(self)
    }
    
    func toggleAirPlay() {
        guard let delegate = delegate else {
            print("Delegate not set for MediaNavigationBar")
            return
        }
        
        delegate.didToggleAirPlay(self)
    }
}
