/*****************************************************************************
 * PlayerInfoView.swift
 *
 * Copyright © 2021-2026 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol PlayerInfoViewDelegate: AnyObject {
    func playerInfoViewDidUpdateIconVisibility(_ playerInfoView: PlayerInfoView)
}

class PlayerInfoView: UIView {
    @objc var displayView: UIView? {
        return externalWindow?.rootViewController?.view
    }
    var externalWindow: UIWindow?
    weak var delegate: PlayerInfoViewDelegate?

    var showsIcon: Bool {
        return !contentImageView.isHidden
    }

    private static let contentImageSize: CGFloat = 120

    private lazy var contentImageHeightConstraint = contentImageView.heightAnchor.constraint(equalToConstant: Self.contentImageSize)

    private lazy var contentImageView: PulsingConeView = {
        let contentImageView = PulsingConeView(image: UIImage(named: "ExternallyPlaying"), size: Self.contentImageSize)
        contentImageView.translatesAutoresizingMaskIntoConstraints = false
        contentImageView.tintColor = .white
        return contentImageView
    }()

    private lazy var labelStackView: UIStackView = {
        let labelStackView = UIStackView()
        labelStackView.spacing = 5
        labelStackView.axis = .vertical
        labelStackView.alignment = .center
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        return labelStackView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.textColor = .white
        descriptionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 3
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        return descriptionLabel
    }()

    init() {
        super.init(frame: .zero)
        setupStackViews()

        titleLabel.text = NSLocalizedString("PLAYING_EXTERNALLY_TITLE", comment: "")
        descriptionLabel.text = NSLocalizedString("PLAYING_EXTERNALLY_DESC", comment:"")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let isCompactHeight = traitCollection.verticalSizeClass == .compact
        contentImageView.isHidden = isCompactHeight
        contentImageHeightConstraint.constant = isCompactHeight ? 0 : Self.contentImageSize
        delegate?.playerInfoViewDidUpdateIconVisibility(self)
    }

    @objc func updateUI(rendererName: String?, title: String?) {
        if let rendererName = rendererName {
            titleLabel.text = NSLocalizedString("PLAYING_EXTERNALLY_ADDITION", comment:"")
            descriptionLabel.text = rendererName
        } else {
            titleLabel.text = title
            descriptionLabel.text = NSLocalizedString("PLAYING_EXTERNALLY_DESC", comment:"")
        }
    }

    func setLoading(_ loading: Bool) {
        if loading {
            contentImageView.startAnimating()
        } else {
            contentImageView.stopAnimating()
        }
    }

    @objc func shouldDisplay(_ show: Bool, movieView: UIView) {
        self.isHidden = !show

        if show {
            guard let externalWindow = VLCAppCoordinator.sharedInstance().externalWindow else {
                return
            }
            guard let rootView = externalWindow.rootViewController?.view else {
                return
            }
            rootView.addSubview(movieView)

#if os(iOS)
            let bounds = externalWindow.screen.bounds
#else
            let bounds = externalWindow.bounds
#endif
            rootView.frame = bounds
            movieView.frame = bounds

            NSLayoutConstraint.activate([
                movieView.leftAnchor.constraint(equalTo: rootView.leftAnchor),
                movieView.rightAnchor.constraint(equalTo: rootView.rightAnchor),
                movieView.topAnchor.constraint(equalTo: rootView.topAnchor),
                movieView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
            ])
        } else {
            VLCAppCoordinator.sharedInstance().externalWindow = nil
            externalWindow = nil
        }
        externalWindow?.isHidden = !show
    }
}

private extension PlayerInfoView {
    private func setupStackViews() {
        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(descriptionLabel)

        addSubview(contentImageView)
        addSubview(labelStackView)

        NSLayoutConstraint.activate([
            contentImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentImageView.topAnchor.constraint(equalTo: topAnchor),
            contentImageHeightConstraint,
            contentImageView.widthAnchor.constraint(equalToConstant: Self.contentImageSize),

            labelStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelStackView.topAnchor.constraint(equalTo: contentImageView.bottomAnchor),
            labelStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
