/*****************************************************************************
 * URLHandler.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@objc public protocol VLCURLHandler {
    func canHandleOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool
    func performOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool
}

@objc class URLHandlers: NSObject {
    @objc static let googleURLHandler = GoogleURLHandler()

    @objc static let handlers =
        [
            googleURLHandler,
            DropBoxURLHandler(),
            FileURLHandler(),
            XCallbackURLHandler(),
            VLCCallbackURLHandler(),
            ElseCallbackURLHandler()
        ]
}

class DropBoxURLHandler: NSObject, VLCURLHandler {

    @objc func canHandleOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {

        let components = url.pathComponents
        let methodName = components.count > 1 ? components[1] : nil

        if methodName == "cancel" {
            return false
        }

        return url.scheme == "db-a60fc6qj9zdg7bw"
    }

    @objc func performOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        let authResult = DBClientsManager.handleRedirectURL(url)

        if  let authResult = authResult, authResult.isSuccess() == true {
            //TODO:update Dropboxcontrollers
            return true
        }
        return false
    }
}

class GoogleURLHandler: NSObject, VLCURLHandler {

    @objc var currentGoogleAuthorizationFlow: OIDExternalUserAgentSession?

    @objc func canHandleOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        return url.scheme == "com.googleusercontent.apps.CLIENT"
    }

    @objc func performOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        if currentGoogleAuthorizationFlow?.resumeExternalUserAgentFlow(with: url) == true {
            currentGoogleAuthorizationFlow = nil
            return true
        }
        return false
    }
}

class FileURLHandler: NSObject, VLCURLHandler {

    @objc func canHandleOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        return url.isFileURL
    }

    @objc func performOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        let subclass = DocumentClass(fileURL: url)
        subclass.open { _ in
            self.play(url: url) { _ in
                subclass.close(completionHandler: nil)
            }
        }
        return true
    }
}

class XCallbackURLHandler: NSObject, VLCURLHandler {

    @objc func canHandleOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        return url.scheme == "vlc-x-callback" || url.scheme == "x-callback-url"
    }

    @objc func performOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        let action = url.path.replacingOccurrences(of: "/", with: "")
        var movieURL: URL?
        var subURL: URL?
        var successCallback: URL?
        var errorCallback: URL?
        var fileName: String?
        guard let query = url.query else {
            assertionFailure("no query")
            return false
        }
        for entry in query.components(separatedBy: "&") {
            let components = entry.components(separatedBy: "=")
            if components.count < 2 {
                continue
            }

            if let key = components.first, let value = components[1].removingPercentEncoding {
                if key == "url"{
                    movieURL = URL(string: value)
                } else if key == "sub" {
                    subURL = URL(string: value)
                } else if key == "filename" {
                    fileName = value
                } else if key == "x-success" {
                    successCallback = URL(string: value)
                } else if key == "x-error" {
                    errorCallback = URL(string: value)
                }
            } else {
                assertionFailure("no key or app value")
            }
        }
        if action == "stream", let movieURL = movieURL {
            play(url: movieURL, sub: subURL) { success in
                guard let callback = success ? successCallback : errorCallback else {
                    assertionFailure("no CallbackURL")
                    return
                }
                if #available(iOS 10, *) {
                    UIApplication.shared.open(callback, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(callback)
                }
            }
            return true
        } else if action == "download", let movieURL = movieURL {
            downloadMovie(from:movieURL, fileNameOfMedia:fileName)
            return true
        }
        return false
    }
}

public class VLCCallbackURLHandler: NSObject, VLCURLHandler {

    @objc public func canHandleOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        return url.scheme == "vlc"
    }

    // Safari fixes URLs like "vlc://http://example.org" to "vlc://http//example.org"
    public func transformVLCURL(_ url: URL) -> URL {
        var parsedString = url.absoluteString.replacingOccurrences(of: "vlc://", with: "")
        if let location = parsedString.range(of: "//"), parsedString[parsedString.index(location.lowerBound, offsetBy: -1)] != ":" {
            parsedString = "\(parsedString[parsedString.startIndex..<location.lowerBound])://\(parsedString[location.upperBound...])"
        } else if !parsedString.hasPrefix("http://") && !parsedString.hasPrefix("https://") && !parsedString.hasPrefix("ftp://") {
            parsedString = "http://\(parsedString)"
        }
        return URL(string: parsedString)!
    }

    public func performOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {

        let transformedURL = transformVLCURL(url)
        let scheme = transformedURL.scheme
        if scheme == "http" || scheme == "https" || scheme == "ftp" {
            let alert = UIAlertController(title: NSLocalizedString("OPEN_STREAM_OR_DOWNLOAD", comment:""), message: url.absoluteString, preferredStyle: .alert)
            let downloadAction = UIAlertAction(title: NSLocalizedString("BUTTON_DOWNLOAD", comment:""), style: .default) { _ in
                self.downloadMovie(from:transformedURL, fileNameOfMedia:nil)
            }
            alert.addAction(downloadAction)
            let playAction = UIAlertAction(title: NSLocalizedString("PLAY_BUTTON", comment:""), style: .default) { _ in
                self.play(url: transformedURL, completion: nil)
            }
            alert.addAction(playAction)

            var rootViewController = UIApplication.shared.keyWindow?.rootViewController
            if let tabBarController = UIApplication.shared.keyWindow?.rootViewController
                as? UITabBarController {
                rootViewController = tabBarController.selectedViewController
            }
            rootViewController?.present(alert, animated: true, completion: nil)

        } else {
            self.play(url: transformedURL, completion: nil)
        }
        return true
    }
}

class ElseCallbackURLHandler: NSObject, VLCURLHandler {
    @objc func canHandleOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        guard let scheme = url.scheme else {
            return false
        }
        return scheme.range(of: kSupportedProtocolSchemes,
                            options: [.regularExpression, .caseInsensitive], range: nil, locale: nil) != nil
    }

    func performOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        self.play(url: url, completion: nil)
        return true
    }
}

extension VLCURLHandler {
    // TODO: This code should probably not live here
    func play(url: URL, sub: URL? = nil, completion: ((Bool) -> Void)?) {
        let vpc = PlaybackService.sharedInstance()
        vpc.fullscreenSessionRequested = true
        if let mediaList = VLCMediaList(array: [VLCMedia(url: url)]) {
            vpc.playMediaList(mediaList, firstIndex: 0, subtitlesFilePath: sub?.absoluteString, completion: completion)
        }
    }

    func downloadMovie(from url: URL, fileNameOfMedia fileName: String?) {
        VLCDownloadViewController.sharedInstance().addURL(toDownloadList: url, fileNameOfMedia: fileName)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
