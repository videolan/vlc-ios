//
//  LongPressPlaybackSpeedView.swift
//  VLC-iOS
//
//  Created by İbrahim Çetin on 14.06.2024.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import UIKit

class LongPressPlaybackSpeedView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."

        return formatter
    }()

    var speedMultiplier: Float = 2 {
        didSet {
            // Format the fraction
            let formatted = Self.numberFormatter.string(from: NSNumber(value: speedMultiplier))

            // Update multiplier label text
            multiplierLabel.text = "\(formatted ?? String(speedMultiplier))x"
        }
    }

    private let multiplierLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        label.text = "2x"
        label.font = .preferredFont(forTextStyle: .subheadline).bolded

        return label
    }()

    /// Creates a new instance of UIImageView with play symbol
    private var playSymbolView: UIImageView {
        let imageView: UIImageView

        if #available(iOS 13, *) {
            let image = UIImage(systemName: "play.fill")?
                .applyingSymbolConfiguration(.init(scale: .small))
            imageView = UIImageView(image: image)
            imageView.tintColor = .label
        } else {
            let image = UIImage(named: "play.fill")
            imageView = UIImageView(image: image)
        }

        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }

    func setupView() {
        let playSymbolView1 = playSymbolView
        let playSymbolView2 = playSymbolView

        self.addSubview(multiplierLabel)
        self.addSubview(playSymbolView1)
        self.addSubview(playSymbolView2)

        NSLayoutConstraint.activate([
            // Center everything
            self.centerYAnchor.constraint(equalTo: multiplierLabel.centerYAnchor),
            multiplierLabel.centerYAnchor.constraint(equalTo: playSymbolView1.centerYAnchor),
            multiplierLabel.centerYAnchor.constraint(equalTo: playSymbolView2.centerYAnchor),
            // Margins
            self.topAnchor.constraint(equalTo: multiplierLabel.topAnchor, constant: -5),
            self.leadingAnchor.constraint(equalTo: multiplierLabel.leadingAnchor, constant: -20),
            self.bottomAnchor.constraint(equalTo: multiplierLabel.bottomAnchor, constant: 5),
            self.trailingAnchor.constraint(equalTo: playSymbolView2.trailingAnchor, constant: 20),
            // UI Elements
            multiplierLabel.trailingAnchor.constraint(equalTo: playSymbolView1.leadingAnchor, constant: -5),
            playSymbolView1.trailingAnchor.constraint(equalTo: playSymbolView2.leadingAnchor)
        ])
        
        if #available(iOS 13, *) {
            self.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.5)
        } else {
            self.backgroundColor = .black.withAlphaComponent(0.35)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.bounds.height / 2
        self.layer.masksToBounds = true
    }
}
