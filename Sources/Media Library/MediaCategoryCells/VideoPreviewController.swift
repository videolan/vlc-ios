/*****************************************************************************
 * VideoPreviewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VLC authors and VideoLAN
 *
 * Authors: Eshan Singh <eeeshan789 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import VLCKit

final class VideoPreviewController: UIViewController {
    private let media: VLCMLMedia
    private let thumbnail: UIImage?
    private let videoView = UIView()
    private var mediaPlayer: VLCMediaPlayer?
    private let savedProgress: Double
    private var hasSeeked = false
    private let thumbnailRatio: CGFloat

    var currentPosition: Double {
        return mediaPlayer?.position ?? savedProgress
    }

    init(media: VLCMLMedia, thumbnail: UIImage?) {
        self.media = media
        self.thumbnail = thumbnail
        self.savedProgress = Double(media.progress)
        if let thumb = thumbnail, thumb.size.width > 0 {
            self.thumbnailRatio = thumb.size.height / thumb.size.width
        } else {
            self.thumbnailRatio = 9.0 / 16.0
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        embedInfoPreview()
        setupVideoOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let width = view.frame.width
        let thumbHeight = min(thumbnailRatio * width, 400)
        preferredContentSize = CGSize(width: width, height: thumbHeight + 147)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPreview()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mediaPlayer?.delegate = nil
        mediaPlayer?.stop()
        mediaPlayer = nil
    }

    private func embedInfoPreview() {
        let thumb = thumbnail ?? blackPlaceholder()
        let child = CollectionViewCellPreviewController(thumbnail: thumb, with: media)
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        child.didMove(toParent: self)
    }

    private func setupVideoOverlay() {
        videoView.backgroundColor = .black
        videoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoView)
        let aspectConstraint = videoView.heightAnchor.constraint(equalTo: videoView.widthAnchor, multiplier: thumbnailRatio)
        aspectConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoView.heightAnchor.constraint(lessThanOrEqualToConstant: 400),
            aspectConstraint
        ])
    }

    private func blackPlaceholder() -> UIImage {
        let size = CGSize(width: 16, height: 9)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func startPreview() {
        guard let mrl = media.mainFile()?.mrl,
              let vlcMedia = VLCMedia(url: mrl) else { return }

        let player = VLCMediaPlayer()
        player.drawable = videoView
        player.delegate = self
        player.media = vlcMedia
        player.audio?.isMuted = true
        player.play()
        mediaPlayer = player
    }
}

// MARK: - VLCMediaPlayerDelegate

extension VideoPreviewController: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
        DispatchQueue.main.async {
            self.mediaPlayer?.audio?.isMuted = true
            guard newState == .playing,
                  !self.hasSeeked,
                  let player = self.mediaPlayer else { return }
            self.hasSeeked = true
            player.position = self.savedProgress
        }
    }
}
