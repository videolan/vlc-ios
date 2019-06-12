/*****************************************************************************
 * QueueCollectionViewSectionHeader.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class QueueCollectionViewSectionHeader: UICollectionReusableView {
    static let identifier = String(describing: self)

    override var reuseIdentifier: String {
        return QueueCollectionViewSectionHeader.identifier
    }

    let title: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        title.textColor = PresentationTheme.current.colors.cellTextColor
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()

    private lazy var guide: LayoutAnchorContainer = {
        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        return guide
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification,
                                               object: nil)
        setupTitleLabel()
        backgroundColor = PresentationTheme.current.colors.background
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 0.5)
    }

    @objc private func themeDidChange() {
        backgroundColor = PresentationTheme.current.colors.background
        title.textColor = PresentationTheme.current.colors.cellTextColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTitleLabel() {
        addSubview(title)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            title.centerYAnchor.constraint(equalTo: guide.centerYAnchor)
            ])
    }
}
