/*****************************************************************************
 * ActionSheetSectionHeader.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class ActionSheetSectionHeader: UIView {

    static let identifier = "VLCActionSheetSectionHeader"

    let title: UILabel = {
        let title = UILabel()
        title.font = UIFont.boldSystemFont(ofSize: 13)
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()

    let separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = .lightGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()

    lazy var guide: LayoutAnchorContainer = {
        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        return guide
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTitle()
        setupSeparator()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTitle()
        setupSeparator()
    }

    fileprivate func setupSeparator() {
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.topAnchor.constraint(equalTo: bottomAnchor, constant: -1)
        ])
    }

    fileprivate func setupTitle() {
        addSubview(title)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
            title.centerXAnchor.constraint(equalTo: centerXAnchor),
            title.topAnchor.constraint(equalTo: topAnchor)
        ])
    }
}
