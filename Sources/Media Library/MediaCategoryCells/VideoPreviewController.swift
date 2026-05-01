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
    private let videoView = UIView()
    private var mediaPlayer: VLCMediaPlayer?
    private let savedProgress: Double
    private var hasSeeked = false

    var currentPosition: Double {
        return mediaPlayer?.position ?? savedProgress
    }

    init(media: VLCMLMedia) {
        self.media = media
        self.savedProgress = Double(media.progress)
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = CGSize(width: 300, height: 169)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        videoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoView)
        NSLayoutConstraint.activate([
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
        guard newState == .playing,
              !hasSeeked,
              let player = mediaPlayer else { return }
        hasSeeked = true
        player.position = savedProgress
    }
}
