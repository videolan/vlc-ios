//
//  LongPressPlaybackSpeedView.swift
//  VLC-iOS
//
//  Created by İbrahim Çetin on 14.06.2024.
//  Copyright © 2024 VideoLAN. All rights reserved.
//

import UIKit

class LongPressPlaybackSpeedView: UIView {
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var label: UILabel!

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."

        return formatter
    }()

    var speedMultiplier: Float = 2 {
        didSet {
            let formatted = numberFormatter.string(from: NSNumber(value: speedMultiplier))
            label.text = "\(formatted ?? String(speedMultiplier))x"
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 20, bottom: 5, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true

        stackView.layer.cornerRadius = stackView.bounds.height / 2
        stackView.layer.masksToBounds = true
        
        stackView.backgroundColor = stackView.backgroundColor?.withAlphaComponent(0.5)

        // Make label font bold
        if #available(iOS 13, *) {
            label.font = .preferredFont(forTextStyle: .subheadline, compatibleWith: .init(legibilityWeight: .bold))
        }
    }
}
