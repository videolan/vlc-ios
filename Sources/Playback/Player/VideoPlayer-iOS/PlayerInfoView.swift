/*****************************************************************************
 * PlayerInfoView.swift
 *
 * Copyright © 2021, 2023 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class PlayerInfoView: UIView {
    @objc var displayView: UIView? {
        return externalWindow?.rootViewController?.view
    }
    var externalWindow: UIWindow?

    private lazy var contentImageView: UIImageView = {
        let contentImageView = UIImageView(image: UIImage(named: "ExternallyPlaying"))
        contentImageView.translatesAutoresizingMaskIntoConstraints = false
        contentImageView.contentMode = .scaleAspectFit
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

    @objc func updateUI(rendererItem: VLCRendererItem?, title: String?) {
        if let rendererItem = rendererItem {
            titleLabel.text = NSLocalizedString("PLAYING_EXTERNALLY_ADDITION", comment:"")
            descriptionLabel.text = rendererItem.name
        } else {
            titleLabel.text = title
            descriptionLabel.text = NSLocalizedString("PLAYING_EXTERNALLY_DESC", comment:"")
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

            let bounds = externalWindow.screen.bounds
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
            contentImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            contentImageView.heightAnchor.constraint(equalToConstant: 120),
            contentImageView.widthAnchor.constraint(equalToConstant: 120),

            labelStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelStackView.topAnchor.constraint(equalTo: contentImageView.bottomAnchor),
        ])
    }
}
