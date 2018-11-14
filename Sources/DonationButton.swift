/*****************************************************************************
 * DonationButton.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class DonationButton: UIButton {

    override var isHighlighted: Bool {
        didSet {
            layer.shadowOffset = isHighlighted ? CGSize(width: 0, height: 0) : CGSize(width: 0, height: 1)
            layer.shadowRadius = isHighlighted ? 0.0 : 2.0
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {

        backgroundColor = PresentationTheme.current.colors.orangeUI
        layer.cornerRadius = 8
        layer.shadowRadius = 2.0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.5
        layer.masksToBounds = false

        let coneImage = UIImageView(image: UIImage(named: "menuCone"))
        coneImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(coneImage)

        let titlelabel = UILabel(frame: .zero)
        titlelabel.textColor = .white
        titlelabel.font = UIFont.systemFont(ofSize: 17.0)
        titlelabel.text = NSLocalizedString("DONATE", comment: "")
        titlelabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titlelabel)

        let subTitlelabel = UILabel(frame: .zero)
        subTitlelabel.text = NSLocalizedString("SUPPORT_VLC", comment: "")
        subTitlelabel.font = UIFont.systemFont(ofSize: 13.0)
        subTitlelabel.translatesAutoresizingMaskIntoConstraints = false
        subTitlelabel.textColor = .white

        addSubview(subTitlelabel)

        let defaultMargin: CGFloat = 8.0

        NSLayoutConstraint.activate([
            coneImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: defaultMargin),
            coneImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            coneImage.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: defaultMargin),
            coneImage.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -defaultMargin),

            titlelabel.bottomAnchor.constraint(equalTo: centerYAnchor, constant: 2),
            titlelabel.leadingAnchor.constraint(equalTo: coneImage.trailingAnchor, constant: defaultMargin),
            titlelabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -defaultMargin),
            titlelabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: defaultMargin / 2),

            subTitlelabel.leadingAnchor.constraint(equalTo: coneImage.trailingAnchor, constant: defaultMargin),
            subTitlelabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -defaultMargin),
            subTitlelabel.topAnchor.constraint(equalTo: centerYAnchor, constant: 2),
            subTitlelabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -defaultMargin / 2),
            ])
    }
}
