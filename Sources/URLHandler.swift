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

enum VLCXCallbackType {
    case url
    case sub
    case filename
    case xSuccess
    case xError
    case undefined
}

@objc public protocol VLCURLHandler {
    var movieURL: URL? { get set }
    var subURL: URL? { get set }
    var successCallback: URL? { get set }
    var errorCallback: URL? { get set }
    var fileName: String? { get set }

    func canHandleOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool
    func performOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool
}

extension VLCURLHandler {
    func matchCallback(key: String) -> VLCXCallbackType {
        switch key {
        case "url":
            return .url
        case "sub":
            return .sub
        case "filename":
            return .filename
        case "x-success":
            return .xSuccess
        case "x-error":
            return .xError
        default:
            return .undefined
        }
    }

    func handlePlay() {
        guard let safeMovieURL = self.movieURL else {
            assertionFailure("VLCURLHandler: Fail to retrieve movieURL.")
            return
        }

        play(url: safeMovieURL, sub: self.subURL) { success in
            guard let callback = success ? self.successCallback : self.errorCallback else {
                assertionFailure("VLCURLHandler: Invalid callback.")
                return
            }

            if #available(iOS 10, *) {
                UIApplication.shared.open(callback,
                                          options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]),
                                          completionHandler: nil)
            } else {
                UIApplication.shared.openURL(callback)
            }
        }
    }

    func handleDownload() {
        guard let safeMovieURL = self.movieURL else {
            assertionFailure("VLCURLHandler: Fail to retrieve movieURL.")
            return
        }

        downloadMovie(from: safeMovieURL, fileNameOfMedia: self.fileName)
    }

    func parseURL(url: URL) {
        guard let query = url.query else {
            assertionFailure("VLCURLHandler: Invalid query.")
            return
        }

        for entry in query.components(separatedBy: "&") {
            let components = entry.components(separatedBy: "=")
            if components.count < 2 {
                continue
            }

            guard let key = components.first else {
                assertionFailure("VLCURLHandler: Fail to retrieve key.")
                continue
            }

            let callback = matchCallback(key: key)

            guard let value = components[1].removingPercentEncoding else {
                assertionFailure("VLCURLHandler: RemovingPercentEnconding returns nil.")
                continue
            }

            switch callback {
            case .url:
                movieURL = URL(string: value)
                break
            case .sub:
                subURL = URL(string: value)
                break
            case .filename:
                fileName = value
                break
            case .xSuccess:
                successCallback = URL(string: value)
                break
            case .xError:
                errorCallback = URL(string: value)
                break
            default:
                assertionFailure("VLCURLHandler: Invalid match of callback.")
                break
            }
        }
    }

    func createAlert() {
        guard let safeMovieURL = self.movieURL else {
            assertionFailure("VLCURLHandler: Fail to retrieve movieURL.")
            return
        }

        let alert = UIAlertController(title: NSLocalizedString("OPEN_STREAM_OR_DOWNLOAD",
                                                                   comment: ""),
                                      message: safeMovieURL.absoluteString,
                                      preferredStyle: .alert)

        let downloadAction = UIAlertAction(title: NSLocalizedString("BUTTON_DOWNLOAD",
                                                                     comment: ""),
                                            style: .default) { _ in
            self.handleDownload()
        }

        let playAction = UIAlertAction(title: NSLocalizedString("PLAY_BUTTON",
                                                                comment: ""),
                                       style: .default) { _ in
            self.handlePlay()
        }

        alert.addAction(downloadAction)
        alert.addAction(playAction)

        var rootViewController = UIApplication.shared.keyWindow?.rootViewController
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController
            as? UITabBarController {
            rootViewController = tabBarController.selectedViewController
        }

        rootViewController?.present(alert, animated: true, completion: nil)
    }
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
    var movieURL: URL?

    var subURL: URL?

    var successCallback: URL?

    var errorCallback: URL?

    var fileName: String?


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
    var movieURL: URL?

    var subURL: URL?

    var successCallback: URL?

    var errorCallback: URL?

    var fileName: String?


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
    var movieURL: URL?

    var subURL: URL?

    var successCallback: URL?

    var errorCallback: URL?

    var fileName: String?


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
    var movieURL: URL?

    var subURL: URL?

    var successCallback: URL?

    var errorCallback: URL?

    var fileName: String?

    enum VLCXCallbackActionType {
        case stream
        case download
        case undefined
    }

    func matchAction(action: String) -> VLCXCallbackActionType {
        switch action {
        case "stream":
            return .stream
        case "download":
            return .download
        default:
            return .undefined
        }
    }

    @objc func canHandleOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        return url.scheme == "vlc-x-callback" || url.scheme == "x-callback-url"
    }

    @objc func performOpen(url: URL, options: [UIApplication.OpenURLOptionsKey: AnyObject]) -> Bool {
        let action = matchAction(action: url.path.replacingOccurrences(of: "/", with: ""))

        parseURL(url: url)

        switch action {
        case .stream:
            handlePlay()
            return true
        case .download:
            handleDownload()
            return true
        default:
            self.createAlert()
            return true
        }
    }
}

public class VLCCallbackURLHandler: NSObject, VLCURLHandler {
    public var movieURL: URL?

    public var subURL: URL?

    public var successCallback: URL?

    public var errorCallback: URL?

    public var fileName: String?

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

        parseURL(url: transformedURL)

        let scheme = transformedURL.scheme
        if scheme == "http" || scheme == "https" || scheme == "ftp" {
            self.createAlert()
        } else {
            handlePlay()
        }
        return true
    }
}

class ElseCallbackURLHandler: NSObject, VLCURLHandler {
    var movieURL: URL?

    var subURL: URL?

    var successCallback: URL?

    var errorCallback: URL?

    var fileName: String?

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
        VLCDownloadController.sharedInstance().addURL(toDownloadList: url, fileNameOfMedia: fileName)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
