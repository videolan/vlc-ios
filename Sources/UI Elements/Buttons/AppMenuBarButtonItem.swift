/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@objc(VLCAppMenuBarButtonItem)
class AppMenuBarButtonItem: UIBarButtonItem {

    private weak var presenter: UIViewController?

    @objc init(presenter: UIViewController) {
        self.presenter = presenter
        super.init()

        image = UIImage(named: "MenuCone")
        accessibilityLabel = NSLocalizedString("Settings", comment: "")
        accessibilityIdentifier = VLCAccessibilityIdentifier.settings

        menu = buildMenu()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildMenu() -> UIMenu {
        let about = UIAction(title: NSLocalizedString("SETTINGS_ABOUT", comment: ""),
                             image: UIImage(named: "MenuCone")) { [weak self] _ in
            self?.showAbout()
        }
        about.accessibilityIdentifier = VLCAccessibilityIdentifier.about

        let documentation = UIAction(title: NSLocalizedString("SETTINGS_DOCUMENTATION", comment: ""),
                                     image: UIImage(systemName: "book")) { [weak self] _ in
            self?.showDocumentation()
        }

        let donation: UIMenuElement = UIAction(title: NSLocalizedString("SETTINGS_DONATE", comment: ""),
                                               image: UIImage(systemName: "heart")) { [weak self] _ in
            self?.showDonation()
        }
        donation.subtitle = NSLocalizedString("SETTINGS_DONATE_LONG", comment: "")

        let settings = UIAction(title: NSLocalizedString("Settings", comment: ""),
                                image: UIImage(systemName: "gearshape")) { [weak self] _ in
            self?.showSettings()
        }
        settings.accessibilityIdentifier = VLCAccessibilityIdentifier.openSettings

        let settingsSection = UIMenu(title: "", options: .displayInline, children: [settings])
        return UIMenu(title: "", children: [about, documentation, donation, settingsSection])
    }

    private func showAbout() {
        let aboutController = AboutController()
        let aboutNavigationController = AboutNavigationController(rootViewController: aboutController)
        presenter?.present(aboutNavigationController, animated: true)
    }

    private func showDocumentation() {
        UIApplication.shared.open(URL(string: "https://docs.videolan.me/vlc-user/ios/3.X/en/index.html")!)
    }

    private func showDonation() {
        let donationController = VLCDonationViewController(nibName: "VLCDonationViewController", bundle: nil)
        let donationNavigationController = VLCDonationNavigationController(rootViewController: donationController)
        if UIDevice.current.userInterfaceIdiom == .pad {
            donationNavigationController.modalPresentationStyle = .popover
            donationNavigationController.popoverPresentationController?.barButtonItem = self
        } else {
            donationNavigationController.modalPresentationStyle = .fullScreen
        }
        donationNavigationController.modalTransitionStyle = .flipHorizontal
        presenter?.present(donationNavigationController, animated: true)
    }

    private func showSettings() {
        ParentalControlCoordinator.shared.authorizeIfParentalControlIsEnabled(action: { [weak self] in
            guard let presenter = self?.presenter else {
                return
            }

            let mediaLibraryService = VLCAppCoordinator.sharedInstance().mediaLibraryService
            let settingsController = SettingsController(mediaLibraryService: mediaLibraryService)
            let settingsNavigationController = UINavigationController(rootViewController: settingsController)
            presenter.present(settingsNavigationController, animated: true)
        })
    }
}
