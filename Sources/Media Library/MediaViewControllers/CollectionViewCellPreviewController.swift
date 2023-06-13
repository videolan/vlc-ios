/*****************************************************************************
* CollectionViewCellPreviewController.swift
*
* Copyright © 2019 VLC authors and VideoLAN
*
* Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

enum PreviewInformationType {
    case title
    case subtitle
    case metadata
}

struct PreviewInformation {
    var value: String
    var label: String?
    var type: PreviewInformationType = .metadata
}

class PreviewElement {
    var info: PreviewInformation
    var uiLabel: VLCMarqueeLabel?

    init(with info: PreviewInformation) {
        self.info = info
        switch info.type {
            default:
                uiLabel = VLCMarqueeLabel()
        }
    }
}

class CollectionViewCellPreviewController: UIViewController {
    private let titleHeight: CGFloat = 25
    private let subtitleHeight: CGFloat = 23
    private let metadataHeight: CGFloat = 20
    private let marginHeight: CGFloat = 10
    private let separationHeight: CGFloat = 2
    private let listSeparator: String = " · "

    private var thumbnailView = UIImageView()
    private var actionImageView = UIImageView()
    private var backThumbnailView = UIImageView()
    private var blurView = UIVisualEffectView()
    private var previewElements: [PreviewElement]
    private var ratio: CGFloat = 0

    private var rowSeparator: String {
        let languageCode = NSLocale.autoupdatingCurrent.languageCode!
        if languageCode.starts(with: "fr") {
            return " : "
        }
        return ": "
    }

    private var width: CGFloat {
        return view.frame.width
    }

    private var thumbnailHeight: CGFloat {
        return ratio * width
    }

    private var subtitleCount: CGFloat {
        return CGFloat(previewElements.filter { $0.info.type == .subtitle }.count)
    }

    private var metadataCount: CGFloat {
        return CGFloat(previewElements.filter { $0.info.type == .metadata }.count)
    }

    private var height: CGFloat {
        if !previewElements.isEmpty {
            return thumbnailHeight
                + marginHeight
                + titleHeight + separationHeight
                + subtitleCount * (subtitleHeight + separationHeight)
                + metadataCount * metadataHeight
                + marginHeight
        }
        return thumbnailHeight
    }

    init(thumbnail: UIImage, with modelContent: VLCMLObject?) {
        self.previewElements = []
        super.init(nibName: nil, bundle: nil)

        let infos = previewInformation(from: modelContent)
        for info in infos {
            self.previewElements.append(PreviewElement(with: info))
        }

        thumbnailView.clipsToBounds = true
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.image = thumbnail
        backThumbnailView.image = thumbnail

        ratio = thumbnail.size.height / thumbnail.size.width
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange),
                                               name: .VLCThemeDidChangeNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.backgroundColor = PresentationTheme.current.colors.background

        if !UIAccessibility.isReduceTransparencyEnabled {
            setupBlurredView()
        }

        thumbnailView.frame = CGRect(x: 0, y: 0, width: width, height: thumbnailHeight)
        view.addSubview(thumbnailView)

        preferredContentSize = CGSize(width: width, height: height)
        addPreviewInformations()
        addActionImage()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private setup

extension CollectionViewCellPreviewController {
    private func infoForVideo(_ video: VLCMLMedia) -> [PreviewInformation] {
        var infos: [PreviewInformation] = []

        infos.append(PreviewInformation(value: video.mediaDuration(),
                                        label: NSLocalizedString("DURATION", comment: "")))
        infos.append(PreviewInformation(value: video.formatSize(),
                                        label: NSLocalizedString("FILE_SIZE", comment: "")))
        infos.append(PreviewInformation(value: video.codecs().joined(separator: " "),
                                        label: NSLocalizedString("ENCODING", comment: "")))
        infos.append(PreviewInformation(value: video.videoDimensions(),
                                        label: NSLocalizedString("VIDEO_DIMENSIONS", comment: "")))
        return infos
    }

    private func previewInformation(from modelContent: VLCMLObject?) -> [PreviewInformation] {
        var infos: [PreviewInformation] = []

        if let media = modelContent as? VLCMLMedia {
            infos.append(PreviewInformation(value: media.title, type: .title))

            if media.subtype() == .albumTrack {
                var description: [String] = [media.albumTrackArtistName()]

                if let album = media.album, !album.title.isEmpty {
                    description.append(album.title)
                }
                infos.append(PreviewInformation(value: description.joined(separator: listSeparator),
                                                type: .subtitle))

                var oneLineMetadata: [String] = []
                oneLineMetadata.append(media.mediaDuration())
                if !media.formatSize().isEmpty {
                    oneLineMetadata.append(media.formatSize())
                }
                infos.append(PreviewInformation(value: oneLineMetadata.joined(separator: listSeparator)))
                let codecs = media.codecs().joined(separator: " ")
                if !codecs.isEmpty {
                    infos.append(PreviewInformation(value: codecs))
                }
            } else {
                infos += infoForVideo(media)
            }
        } else if let collection = modelContent as? MediaCollectionModel {
            infos.append(PreviewInformation(value: collection.title(), type: .title))
            // Handle single mediaGroups as media
            if let mediaGroup = collection as? VLCMLMediaGroup,
                !mediaGroup.userInteracted() && mediaGroup.nbTotalMedia() == 1 {
                if let medium = mediaGroup.media(of: .video)?.first {
                    infos += infoForVideo(medium)
                }
                return infos
            } else {
                var collectionDetails: [String] = [collection.numberOfTracksString()]
                var releaseYear: String?
                if let collection = collection as? VLCMLAlbum {
                    infos.append(PreviewInformation(value: collection.albumArtistName()))
                    releaseYear = String(collection.releaseYear())
                    let duration = VLCTime(number: NSNumber(value: collection.duration()))
                    collectionDetails.append(String(describing: duration))
                }

                infos.append(PreviewInformation(value: collectionDetails.joined(separator: listSeparator)))

                if let releaseYear = releaseYear {
                    infos.append(PreviewInformation(value: releaseYear))
                }
            }
        }

        return infos
    }

    private func setupBlurredView() {
        blurView.effect = UIBlurEffect(style: PresentationTheme.current.colors.blurStyle)
        view.addSubview(backThumbnailView)
        view.addSubview(blurView)

        backThumbnailView.frame = view.bounds
        blurView.frame = view.bounds
    }

    private func addPreviewInformations() {
        var y: CGFloat = thumbnailView.frame.height + marginHeight
        for element in previewElements {
            if let label = element.uiLabel {
                label.text = labelText(for: element.info)
                label.frame = labelFrame(for: element.info, at: y)
                label.font = labelFont(for: element.info)
                label.textColor = labelColor(for: element.info)
                y += yIncrement(for: element.info)
                view.addSubview(label)
            }
        }
    }

    private func addActionImage() {
        actionImageView.frame = CGRect(x: width - 50, y: (height + thumbnailView.frame.height) / 2 - 18, width: 36, height: 36)
        view.addSubview(actionImageView)
    }
}

// MARK: - Private helpers

extension CollectionViewCellPreviewController {
    private func labelText(for info: PreviewInformation) -> String {
        var text = info.value
        if let label = info.label {
            text = label + rowSeparator + text
        }
        return text
    }

    private func labelFrame(for info: PreviewInformation, at y: CGFloat) -> CGRect {
        let rightMargin: CGFloat
        if actionImageView.image != nil {
            rightMargin = 80
        } else {
            rightMargin = 40
        }
        let frameHeight: CGFloat
        switch info.type {
            case .title:
                frameHeight = titleHeight
            case .subtitle:
                frameHeight = subtitleHeight
            default:
                frameHeight = metadataHeight
        }
        return CGRect(x: 20, y: y, width: width - rightMargin, height: frameHeight)
    }

    private func labelFont(for info: PreviewInformation) -> UIFont {
        switch info.type {
            case .title:
                return .boldSystemFont(ofSize: 18)
            default:
                return .systemFont(ofSize: 15)
        }
    }

    private func labelColor(for info: PreviewInformation) -> UIColor {
        switch info.type {
            case .title, .subtitle:
                return PresentationTheme.current.colors.cellTextColor
            default:
                if !UIAccessibility.isReduceTransparencyEnabled {
                    return PresentationTheme.current.colors.cellTextColor.withAlphaComponent(0.7)
                } else {
                    return PresentationTheme.current.colors.cellDetailTextColor
                }
        }
    }

    private func yIncrement(for info: PreviewInformation) -> CGFloat {
        switch info.type {
            case .title:
                return titleHeight + separationHeight
            case .subtitle:
                return subtitleHeight + separationHeight
            default:
                return metadataHeight
        }
    }
}

// MARK: - Theme management

@objc extension CollectionViewCellPreviewController {
    @objc func themeDidChange() {
        view.backgroundColor = PresentationTheme.current.colors.background
        blurView.effect = UIBlurEffect(style: PresentationTheme.current.colors.blurStyle)
        for element in previewElements {
            element.uiLabel?.textColor = labelColor(for: element.info)
        }
    }
}
