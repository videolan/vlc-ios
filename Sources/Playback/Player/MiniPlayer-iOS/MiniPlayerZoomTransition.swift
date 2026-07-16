/*****************************************************************************
 * MiniPlayerZoomTransition.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2026 VLC authors and VideoLAN
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@objc(VLCZoomTransitionEndpoint)
protocol ZoomTransitionEndpoint: NSObjectProtocol {
    var zoomTransitionArtworkView: UIImageView? { get }
}

@objc(VLCZoomTransitionDataSource)
protocol ZoomTransitionDataSource: NSObjectProtocol {
    func miniPlayerZoomTransitionEndpoint() -> ZoomTransitionEndpoint?
}

private func artworkView(of viewController: UIViewController) -> UIImageView? {
    let endpoint = (viewController as? UINavigationController)?.topViewController ?? viewController
    return (endpoint as? ZoomTransitionEndpoint)?.zoomTransitionArtworkView
}

class MiniPlayerZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private weak var miniPlayerEndpoint: ZoomTransitionEndpoint?
    private let presenting: Bool

    init(miniPlayerEndpoint: ZoomTransitionEndpoint, presenting: Bool) {
        self.miniPlayerEndpoint = miniPlayerEndpoint
        self.presenting = presenting
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.45
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if presenting {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard let toViewController = transitionContext.viewController(forKey: .to),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        toView.frame = transitionContext.finalFrame(for: toViewController)
        containerView.addSubview(toView)
        toView.layoutIfNeeded()

        guard let miniArtworkView = miniPlayerEndpoint?.zoomTransitionArtworkView,
              let artwork = miniArtworkView.image,
              let playerArtworkView = artworkView(of: toViewController),
              miniArtworkView.window != nil else {
            fade(toView, from: 0.0, to: 1.0, using: transitionContext)
            return
        }

        let sourceFrame = miniArtworkView.convert(miniArtworkView.bounds, to: containerView)
        let destinationFrame = playerArtworkView.convert(playerArtworkView.bounds, to: containerView)

        guard !sourceFrame.isEmpty && !destinationFrame.isEmpty else {
            fade(toView, from: 0.0, to: 1.0, using: transitionContext)
            return
        }

        toView.alpha = 0.0
        fly(artwork,
            from: miniArtworkView, at: sourceFrame,
            to: playerArtworkView, at: destinationFrame,
            in: containerView,
            alongside: { toView.alpha = 1.0 },
            using: transitionContext)
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        guard let playerArtworkView = artworkView(of: fromViewController),
              let artwork = playerArtworkView.image,
              let miniArtworkView = miniPlayerEndpoint?.zoomTransitionArtworkView,
              miniArtworkView.window != nil else {
            fade(fromView, from: 1.0, to: 0.0, using: transitionContext)
            return
        }

        miniArtworkView.superview?.layoutIfNeeded()

        let sourceFrame = playerArtworkView.convert(playerArtworkView.bounds, to: containerView)
        let destinationFrame = miniArtworkView.convert(miniArtworkView.bounds, to: containerView)

        guard !sourceFrame.isEmpty && !destinationFrame.isEmpty else {
            fade(fromView, from: 1.0, to: 0.0, using: transitionContext)
            return
        }

        fly(artwork,
            from: playerArtworkView, at: sourceFrame,
            to: miniArtworkView, at: destinationFrame,
            in: containerView,
            alongside: { fromView.alpha = 0.0 },
            using: transitionContext)
    }

    private func fly(_ artwork: UIImage,
                     from sourceArtworkView: UIImageView, at sourceFrame: CGRect,
                     to destinationArtworkView: UIImageView, at destinationFrame: CGRect,
                     in containerView: UIView,
                     alongside animations: @escaping () -> Void,
                     using transitionContext: UIViewControllerContextTransitioning) {
        let flyingArtworkView = UIImageView(image: artwork)
        flyingArtworkView.contentMode = destinationArtworkView.contentMode
        flyingArtworkView.clipsToBounds = true
        flyingArtworkView.frame = sourceFrame
        flyingArtworkView.layer.cornerRadius = sourceArtworkView.layer.cornerRadius
        containerView.addSubview(flyingArtworkView)

        sourceArtworkView.alpha = 0.0
        destinationArtworkView.alpha = 0.0

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0.0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.0,
                       options: .curveEaseInOut,
                       animations: {
            flyingArtworkView.frame = destinationFrame
            flyingArtworkView.layer.cornerRadius = destinationArtworkView.layer.cornerRadius
            animations()
        }, completion: { _ in
            flyingArtworkView.removeFromSuperview()
            destinationArtworkView.alpha = 1.0
            sourceArtworkView.alpha = 1.0
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    private func fade(_ view: UIView,
                      from startAlpha: CGFloat,
                      to endAlpha: CGFloat,
                      using transitionContext: UIViewControllerContextTransitioning) {
        view.alpha = startAlpha
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            view.alpha = endAlpha
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

@objc(VLCMiniPlayerZoomTransitioningDelegate)
class MiniPlayerZoomTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    private weak var dataSource: ZoomTransitionDataSource?

    @objc init(dataSource: ZoomTransitionDataSource) {
        self.dataSource = dataSource
        super.init()
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let miniPlayerEndpoint = dataSource?.miniPlayerZoomTransitionEndpoint(),
              miniPlayerEndpoint.zoomTransitionArtworkView?.image != nil else {
            return nil
        }

        return MiniPlayerZoomAnimator(miniPlayerEndpoint: miniPlayerEndpoint, presenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let miniPlayerEndpoint = dataSource?.miniPlayerZoomTransitionEndpoint(),
              miniPlayerEndpoint.zoomTransitionArtworkView?.image != nil,
              artworkView(of: dismissed)?.image != nil else {
            return nil
        }

        return MiniPlayerZoomAnimator(miniPlayerEndpoint: miniPlayerEndpoint, presenting: false)
    }
}
