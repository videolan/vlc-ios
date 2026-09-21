/*****************************************************************************
 * MediaLibraryCorruptionReportPresenter.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2026 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import MessageUI

class MediaLibraryCorruptionReportPresenter: NSObject {
    static let shared = MediaLibraryCorruptionReportPresenter()

    private static let supportEmail = "ios-support@videolan.org"
    private static let archiveFileName = "medialibrary-corruption-report.zip"

    private var isPresenting = false
    private var isWaitingForActivation = false

    func presentIfNeeded() {
        guard MediaLibraryCorruptionReport.isPending, !isPresenting else {
            return
        }

        DispatchQueue.main.async {
            self.present()
        }
    }

    private func present() {
        guard MediaLibraryCorruptionReport.isPending, !isPresenting else {
            return
        }

        guard let viewController = UIApplication.shared.topViewController,
              viewController.presentedViewController == nil,
              viewController.viewIfLoaded?.window != nil else {
            waitForActivation()
            return
        }

        guard MFMailComposeViewController.canSendMail() else {
            MediaLibraryCorruptionReport.discard()
            return
        }

        isPresenting = true

        let buttons = [
            VLCAlertButton(title: NSLocalizedString("MEDIALIBRARY_CORRUPTION_SEND", comment: ""),
                           style: .default) { _ in
                self.presentMailComposer(on: viewController)
            },
            VLCAlertButton(title: NSLocalizedString("MEDIALIBRARY_CORRUPTION_DISMISS", comment: ""),
                           style: .cancel) { _ in
                MediaLibraryCorruptionReport.discard()
                self.isPresenting = false
            }
        ]

        let alert = VLCAlertViewController.alertViewManager(title: NSLocalizedString("MEDIALIBRARY_CORRUPTION_TITLE", comment: ""),
                                                            errorMessage: NSLocalizedString("MEDIALIBRARY_CORRUPTION_MESSAGE", comment: ""),
                                                            viewController: viewController,
                                                            buttonsAction: buttons)
        alert.preferredAction = alert.actions.first
    }

    private func presentMailComposer(on viewController: UIViewController) {
        guard let archive = MediaLibraryCorruptionReport.archivedData() else {
            MediaLibraryCorruptionReport.discard()
            isPresenting = false
            return
        }

        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients([MediaLibraryCorruptionReportPresenter.supportEmail])
        composer.setSubject(NSLocalizedString("MEDIALIBRARY_CORRUPTION_EMAIL_TITLE", comment: ""))
        composer.addAttachmentData(archive,
                                   mimeType: "application/zip",
                                   fileName: MediaLibraryCorruptionReportPresenter.archiveFileName)
        viewController.present(composer, animated: true)
    }

    private func waitForActivation() {
        guard !isWaitingForActivation else {
            return
        }

        isWaitingForActivation = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    @objc private func applicationDidBecomeActive() {
        isWaitingForActivation = false
        presentIfNeeded()
    }
}

extension MediaLibraryCorruptionReportPresenter: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)

        if result != .failed {
            MediaLibraryCorruptionReport.discard()
        }

        isPresenting = false
    }
}
