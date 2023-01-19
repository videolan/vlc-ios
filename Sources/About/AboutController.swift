/*****************************************************************************
 * AboutController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import WebKit
import MessageUI

class AboutController: UIViewController, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {

    private let webView = WKWebView()
    private let notificationCenter = NotificationCenter.default
    private let feedbackEmail = "ios-support@videolan.org"

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    override var shouldAutorotate: Bool {
        let toInterfaceOrientation = UIApplication.shared.statusBarOrientation
        let currentUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
        if currentUserInterfaceIdiom == .phone && toInterfaceOrientation == .portraitUpsideDown {
            return false
        }
        return true
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setup() {
        setupUI()
        setupObserver()
        setupNavigationBar()
        loadWebsite()
    }

    private func setupUI() {
        self.view.backgroundColor = PresentationTheme.current.colors.background
        self.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        webView.frame = self.view.frame
        webView.clipsToBounds = true
        webView.navigationDelegate = self
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.indicatorStyle = .white
        webView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.view.addSubview(webView)
    }

    private func setupObserver() {
        notificationCenter.addObserver(self,
                                       selector: #selector(themeDidChange),
                                       name: NSNotification.Name(kVLCThemeDidChangeNotification),
                                       object: nil)
    }

    private func setupNavigationBar() {
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "AboutTitle"))
        self.navigationItem.titleView?.tintColor = PresentationTheme.current.colors.navigationbarTextColor
        self.navigationController?.navigationBar.isOpaque = true
        setupBarButtons()
    }

    private func setupBarButtons() {
        let feedbackButton = UIBarButtonItem(title: NSLocalizedString("BUTTON_CONTACT", comment: ""),
                                             style: .plain,
                                             target: self,
                                             action: #selector(sendFeedbackEmail))
        feedbackButton.accessibilityIdentifier = VLCAccessibilityIdentifier.contact
        let doneButton = UIBarButtonItem(title: NSLocalizedString("BUTTON_DONE", comment: ""),
                                         style: .done,
                                         target: self,
                                         action: #selector(dismissView))
        doneButton.accessibilityIdentifier = VLCAccessibilityIdentifier.done
        self.navigationItem.leftBarButtonItem = feedbackButton
        self.navigationItem.rightBarButtonItem = doneButton
    }

    private func loadWebsite() {
        let mainBundle = Bundle.main
        let textColor = PresentationTheme.current.colors.cellTextColor.toHex ?? "#000000"
        let backgroundColor = PresentationTheme.current.colors.background.toHex ?? "#FFFFFF"
        guard let bundleShortVersionString = mainBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return
        }
        guard let bundleVersion = mainBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? CVarArg else {
            return
        }
        let version = String(format: NSLocalizedString("VERSION_FORMAT", comment: ""),
                             bundleShortVersionString)
        let versionBuildNumberAndCodeName = version.appendingFormat(" (%@)", bundleVersion)
        let vlcLibraryVersion = String(format: NSLocalizedString("BASED_ON_FORMAT", comment: ""),
                                       VLCLibrary.shared().changeset as CVarArg)
        guard let staticHTMLPath = Bundle.main.path(forResource: "About Contents", ofType: "html") else { return }
        do {
            var htmlString = try String(contentsOfFile: staticHTMLPath) as NSString

            let rangeOfLastStringToReplace = htmlString.range(of: "MOBILEVLCKITVERSION")
            let lengthOfStringToSearch = rangeOfLastStringToReplace.location +
            rangeOfLastStringToReplace.length +
            versionBuildNumberAndCodeName.count +
            textColor.count +
            backgroundColor.count +
            vlcLibraryVersion.count
            let searchRange = NSRange(location: 0, length: lengthOfStringToSearch)

            htmlString = htmlString.replacingOccurrences(of: "VLCFORIOSVERSION",
                                                         with: versionBuildNumberAndCodeName,
                                                         options: .literal,
                                                         range: searchRange) as NSString
            htmlString = htmlString.replacingOccurrences(of: "TEXTCOLOR",
                                                         with: textColor,
                                                         options: .literal,
                                                         range: searchRange) as NSString
            htmlString = htmlString.replacingOccurrences(of: "BACKGROUNDCOLOR",
                                                         with: backgroundColor,
                                                         options: .literal,
                                                         range: searchRange) as NSString
            htmlString = htmlString.replacingOccurrences(of: "MOBILEVLCKITVERSION",
                                                         with: vlcLibraryVersion,
                                                         options: .literal,
                                                         range: searchRange) as NSString

            let staticPageURL = URL(fileURLWithPath: staticHTMLPath)
            webView.loadHTMLString(htmlString as String, baseURL: staticPageURL)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    // MARK: - Observer & BarButton Actions

    @objc private func themeDidChange() {
        view.backgroundColor = PresentationTheme.current.colors.background
        webView.backgroundColor = PresentationTheme.current.colors.background
        loadWebsite()
    }

    @objc private func sendFeedbackEmail() {
        if #available(iOS 10, *) {
            ImpactFeedbackGenerator().selectionChanged()
        }

        if MFMailComposeViewController.canSendMail() {
            let mailComposerVC = MFMailComposeViewController()
            mailComposerVC.mailComposeDelegate = self
            mailComposerVC.setToRecipients([feedbackEmail])
            mailComposerVC.setSubject(NSLocalizedString("FEEDBACK_EMAIL_TITLE", comment: ""))
            mailComposerVC.setMessageBody(generateFeedbackEmailPrefill(), isHTML: false)
            self.present(mailComposerVC, animated: true)
        } else {
            let alert = UIAlertController(title: NSLocalizedString("FEEDBACK_EMAIL_NOT_POSSIBLE_TITLE", comment: ""),
                                          message: String(format: NSLocalizedString("FEEDBACK_EMAIL_NOT_POSSIBLE_LONG", comment: ""),
                                                          feedbackEmail),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }

    func generateFeedbackEmailPrefill() -> String {
        let bundleShortVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let device = UIDevice.current
        let defaults = UserDefaults.standard
        let locale = NSLocale.autoupdatingCurrent
        let prefilledFeedback = String(format: "\n\n\n----------------------------------------\n%@\nDevice: %@\nOS: %@ - %@\nLocale: %@ (%@)\nVLC app version: %@\nlibvlc version: %@\nhardware decoding: %i\nnetwork caching level: %i\nskip loop filter: %i\nRTSP over TCP: %i\nAudio time stretching: %i",
                                       NSLocalizedString("FEEDBACK_EMAIL_BODY", comment: ""),
                                       generateDeviceIdentifier(),
                                       device.systemName,
                                       device.systemVersion,
                                       locale.languageCode!,
                                       locale.regionCode!,
                                       bundleShortVersionString,
                                       VLCLibrary.shared().changeset,
                                       defaults.integer(forKey: kVLCSettingHardwareDecoding),
                                       defaults.integer(forKey: kVLCSettingNetworkCaching),
                                       defaults.integer(forKey: kVLCSettingSkipLoopFilter),
                                       defaults.integer(forKey: kVLCSettingNetworkRTSPTCP),
                                       defaults.integer(forKey: kVLCSettingStretchAudio))
        return prefilledFeedback
    }

    func generateDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)

        let identifier = mirror.children.reduce("") { identifier, element in guard let value = element.value as? Int8, value != 0 else { return identifier }
              return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }


    @objc private func dismissView() {
        if #available(iOS 10, *) {
            ImpactFeedbackGenerator().selectionChanged()
        }
        dismiss(animated: true)
    }
}

extension AboutController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.backgroundColor = PresentationTheme.current.colors.background
        webView.isOpaque = true
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let requestURL = navigationAction.request.url else {return}
        if (requestURL.scheme != "") && UIApplication.shared.openURL(requestURL) {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

class AboutNavigationController: UINavigationController {

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = false
        }
    }
}
