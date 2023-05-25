/*****************************************************************************
 * VLCPlayerDisplayController+MiniPlayerDraggingDelegate.swift
 *
 * Copyright © 2021 VLC authors and VideoLAN
 *
 * Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

extension VLCPlayerDisplayController: MiniPlayerDraggingDelegate {
    static private let animationDuration = 0.2

    func miniPlayerDragStateDidChange(_ miniPlayer: AudioMiniPlayer, sender: UIPanGestureRecognizer, panDirection: PanDirection) {
        let translation = sender.translation(in: UIApplication.shared.keyWindow?.rootViewController?.view)

        switch panDirection {
            case .vertical:
                if bottomConstraint?.isActive ?? false {
                    bottomConstraint?.constant += translation.y
                } else if playqueueBottomConstraint?.isActive ?? false {
                    playqueueBottomConstraint?.constant += translation.y
                }
            case .horizontal:
                leadingConstraint?.constant += translation.x
                trailingConstraint?.constant += translation.x
        }
    }

    func miniPlayerDragDidEnd(_ miniPlayer: AudioMiniPlayer, sender: UIPanGestureRecognizer, panDirection: PanDirection) {
        if panDirection == .vertical {
            resetVerticalConstraints()
        }
    }

    func miniPlayerPositionToTop(_ miniPlayer: AudioMiniPlayer) {
        bottomConstraint?.isActive = false
        playqueueBottomConstraint?.isActive = true
        resetVerticalConstraints()
        view?.setNeedsLayout()
        UIView.animate(withDuration: VLCPlayerDisplayController.animationDuration, animations: {
            self.view.layoutIfNeeded()
        })
    }

    func miniPlayerPositionToBottom(_ miniPlayer: AudioMiniPlayer, completion: ((Bool) -> Void)?) {
        bottomConstraint?.isActive = true
        playqueueBottomConstraint?.isActive = false
        resetVerticalConstraints()
        view?.setNeedsLayout()
        UIView.animate(withDuration: VLCPlayerDisplayController.animationDuration, animations: {
            self.view.layoutIfNeeded()
        }, completion: completion)
    }

    func miniPlayerCenterHorizontaly(_ miniPlayer: AudioMiniPlayer) {
        leadingConstraint?.constant = 0.0
        trailingConstraint?.constant = 0.0
        UIView.animate(withDuration: VLCPlayerDisplayController.animationDuration, animations: {
            self.view.layoutIfNeeded()
        })
    }

    func miniPlayerNeedsLayout(_ miniPlayer: AudioMiniPlayer) {
        view?.setNeedsLayout()
        view?.layoutIfNeeded()
    }

    private func resetVerticalConstraints() {
            bottomConstraint?.constant = 0.0
            playqueueBottomConstraint?.constant = 25.0
    }
}
