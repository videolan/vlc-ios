/*****************************************************************************
 * MediaDetailViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 *
 * Authors: Priyank Shusheet
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class MediaDetailViewController: UIViewController {
    private let media: VLCMLMedia
    
    private let scrollView: UIScrollView = {
        let sc = UIScrollView()
        sc.alwaysBounceVertical = true
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    private let backdropImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40, weight: .black)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let synopsisLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.numberOfLines = 0
        label.text = "No description available for this media."
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(media: VLCMLMedia) {
        self.media = media
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureData()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(backdropImageView)
        view.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(playButton)
        contentView.addSubview(synopsisLabel)
        
        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 350),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            
            playButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            playButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 200),
            playButton.heightAnchor.constraint(equalToConstant: 50),
            
            synopsisLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 30),
            synopsisLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            synopsisLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            synopsisLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)
        ])
        
        playButton.addTarget(self, action: #selector(playMedia), for: .touchUpInside)
        
        // Add a gradient overlay to the backdrop for readability
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.4, 0.7]
        view.layer.insertSublayer(gradient, above: backdropImageView.layer)
    }
    
    private func configureData() {
        titleLabel.text = media.title
        if let thumbnail = media.thumbnail() {
            backdropImageView.image = UIImage(contentsOfFile: thumbnail.path)
        }
    }
    
    @objc private func playMedia() {
        let playbackService = PlaybackService.sharedInstance()
        playbackService.play(media)
        dismiss(animated: true)
    }
}
