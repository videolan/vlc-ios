/*****************************************************************************
 * AboutController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2020 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import WebKit

class AboutController: UIViewController {

    private let webView = WKWebView()
    private let notificationCenter = NotificationCenter.default
    private let contributeURL = "http://www.videolan.org/contribute.html"

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
        let contributeButton = UIBarButtonItem(title: NSLocalizedString("BUTTON_CONTRIBUTE", comment: ""),
                                               style: .plain,
                                               target: self,
                                               action: #selector(openContributePage))
        contributeButton.accessibilityIdentifier = VLCAccessibilityIdentifier.contribute
        let doneButton = UIBarButtonItem(title: NSLocalizedString("BUTTON_DONE", comment: ""),
                                         style: .done,
                                         target: self,
                                         action: #selector(dismissView))
        doneButton.accessibilityIdentifier = VLCAccessibilityIdentifier.done
        self.navigationItem.leftBarButtonItem = contributeButton
        self.navigationItem.rightBarButtonItem = doneButton
    }

    private func loadWebsite() {
        let mainBundle = Bundle.main
        let textColor = PresentationTheme.current.colors.cellTextColor.toHex ?? "#000000"
        let backgroundColor = PresentationTheme.current.colors.background.toHex ?? "#FFFFFF"
        guard let bundleShortVersionString = mainBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? CVarArg else {
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

    @objc private func openContributePage() {
        if #available(iOS 10, *) {
            ImpactFeedbackGenerator().selectionChanged()
        }
        guard let url = URL(string: contributeURL) else { return }
        UIApplication.shared.openURL(url)
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
