/*****************************************************************************
 * GraphViewController.swift
 *
 * Copyright © 2022 VLC authors and VideoLAN
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import MSAL
import MSGraphClientSDK
import MSGraphClientModels
import MSGraphMSALAuthProvider

@objc (VLCGraphViewController)
class GraphViewController: VLCCloudStorageController {
    // MARK: - Properties
    private let kClientID = "c7fbceea-ef4a-4a2e-9e54-72a3c333aa0b"
    private let kRedirectUri = "msauth.com.example.vlc-ios://auth"
    private let kAuthority = "https://login.microsoftonline.com/common"
    private let kGraphEndpoint = "https://graph.microsoft.com/"

    private let kScopes: [String] = ["user.read", "files.read"]

    private var accessToken = String()
    private var applicationContext: MSALPublicClientApplication?
    private var webViewParameters: MSALWebviewParameters?

    private var currentAccount: MSALAccount?

    private var authenticationProvider: MSAuthenticationProvider?

    lazy var currentItem: MSGraphDriveItem? = nil
    lazy var parentItem: MSGraphDriveItem? = nil
    private lazy var currentItems: [MSGraphDriveItem] = []
    private lazy var downloadUrlDictionary: [MSGraphDriveItem: String] = [:]
    private lazy var rootItemID: String? = nil
    private var presentingViewController: UIViewController?

    private lazy var pendingDownloads: [MSGraphDriveItem] = []
    private var downloadInProgress: Bool = false
    private var progress: Progress = Progress()

    @objc static var sharedObject: GraphViewController = {
        let sharedInstance = GraphViewController()
        return sharedInstance
    }()

    // MARK: - Overriding properties
    override var currentListFiles: [Any]! {
        get { return currentItems }
    }

    override var isAuthorized: Bool {
        get { return super.isAuthorized }
        set { super.isAuthorized = newValue }
    }

    override var canPlayAll: Bool {
        get { return !currentItems.isEmpty }
    }

    // MARK: - Overriding methods
    override func logout() {
        guard let applicationContext = applicationContext else {
            return
        }

        guard let currentAccount = currentAccount else {
            return
        }

        do {
            let signoutParameters = MSALSignoutParameters(webviewParameters: webViewParameters!)
            signoutParameters.signoutFromBrowser = false

            applicationContext.signout(with: currentAccount, signoutParameters: signoutParameters, completionBlock: { (success, error) in
                if let error = error {
                    preconditionFailure("GraphViewController: Couldn't sign out account: \(error).")
                }

                self.accessToken = ""
                self.updateCurrentAccount(account: nil)
            })
        }

        delegate.mediaListUpdated()
        if let presentingViewController = presentingViewController {
            presentingViewController.navigationController?.popViewController(animated: true)
        }

        resetSession()
    }

    override func requestDirectoryListing(atPath path: String!) {
        loadCurrentItem()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async {
            if let progress: Progress = object as? Progress {
                let expectedDowloadSize = CGFloat(progress.totalUnitCount)
                let percentage = (progress.fractionCompleted * expectedDowloadSize) / 100
                self.delegate.currentProgressInformation?(percentage)
            }
        }
    }

    // MARK: - Public helpers
    func getCurrentListFiles() -> [MSGraphDriveItem] {
        return currentItems
    }

    func getDownloadUrlDictionary() -> [MSGraphDriveItem: String] {
        return downloadUrlDictionary
    }

    func getRootItemID() -> String? {
        return rootItemID
    }

    func setPresentingViewController(with viewController: UIViewController) {
        presentingViewController = viewController
    }

    // MARK: - Private helpers
    private func resetSession() {
        parentItem = nil
        currentItem = nil
        rootItemID = nil
        isAuthorized = false
        currentItems.removeAll()
        downloadUrlDictionary.removeAll()
        pendingDownloads.removeAll()
    }

    private func checkFileExtension(for item: MSGraphDriveItem) -> Bool {
        if item.folder != nil || item.audio != nil || item.video != nil {
            return true
        } else if let itemName = item.name as? NSString,
           itemName.isSupportedMediaFormat() {
            return true
        } else {
            return false
        }
    }

    @objc private func sessionWasUpdated() {
        delegate.responds(to: #selector(sessionWasUpdated))
        delegate.perform(#selector(sessionWasUpdated))
    }

    private func platformViewDidLoadSetup() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appCameToForeGround(notification:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    @objc private func appCameToForeGround(notification: Notification) {
        loadCurrentAccount()
    }

    // MARK: - Authentication
    func loginWithViewController(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController

        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().prefersLargeTitles = false
        }

        do {
            try initMSAL()
        } catch let error {
            preconditionFailure("GraphViewController: Unable to create the application context: \(error).")
        }

        webViewParameters = MSALWebviewParameters(authPresentationViewController: presentingViewController)

        loadCurrentAccount()
        platformViewDidLoadSetup()
        callGraphAPI()
    }

    private func initMSAL() throws {
        guard let authorityURL = URL(string: kAuthority) else {
            preconditionFailure("GraphViewController: Unable to create authority URL.")
        }

        let authority = try MSALAADAuthority(url: authorityURL)
        let msalConfiguration = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: kRedirectUri, authority: authority)
        applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
    }

    private func callGraphAPI() {
        loadCurrentAccount { (account) in
            guard let currentAccount = account else {
                self.acquireTokenInteractively()
                return
            }

            self.acquireTokenSilently(currentAccount)
        }
    }

    private func acquireTokenInteractively() {
        guard let applicationContext = applicationContext else {
            return
        }

        guard let webViewParameters = webViewParameters else {
            return
        }

        let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount

        applicationContext.acquireToken(with: parameters) { (result, error) in
            if let error = error {
                preconditionFailure("GraphViewController: Couldn't acquire token: \(error).")
            }

            guard let result = result else {
                preconditionFailure("GraphViewController: Couldn't retrieve token result.")
            }

            self.accessToken = result.accessToken
            self.updateCurrentAccount(account: result.account)
            self.load()
        }
    }

    private func acquireTokenSilently(_ account: MSALAccount) {
        guard let applicationContext = applicationContext else {
            return
        }

        let parameters = MSALSilentTokenParameters(scopes: kScopes, account: account)
        applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
            if let error = error {
                let nsError = error as NSError
                if nsError.domain == MSALErrorDomain {
                    if nsError.code == MSALError.interactionRequired.rawValue {
                        DispatchQueue.main.async {
                            self.acquireTokenInteractively()
                        }

                        return
                    }
                }

                return
            }

            guard let result = result else {
                preconditionFailure("GraphViewController: Couldn't retrieve token result.")
            }

            self.accessToken = result.accessToken
            self.load()
        }
    }

    private func getGraphEndpoint() -> String {
        if let currentItem = currentItem,
           let rootItemID = rootItemID {
            return kGraphEndpoint + "v1.0/drives/\(rootItemID)/items/\(currentItem.entityId)/children"
        }

        return kGraphEndpoint + "v1.0/me/drive/root/children"
    }

    typealias AccountCompletion = (MSALAccount?) -> Void

    private func loadCurrentAccount(completion: AccountCompletion? = nil) {
        guard let applicationContext = applicationContext else {
            return
        }

        let msalParameters = MSALParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main

        applicationContext.getCurrentAccount(with: msalParameters, completionBlock: { (currentAccount, previousAccount, error) in
            if let error = error {
                preconditionFailure("GraphViewController: Couldn't acquire current account: \(error).")
            }

            if let currentAccount = currentAccount {
                self.updateCurrentAccount(account: currentAccount)

                if let completion = completion {
                    completion(self.currentAccount)
                }

                return
            }

            self.accessToken = ""
            self.updateCurrentAccount(account: nil)

            if let completion = completion {
                completion(nil)
            }
        })
    }

    private func updateCurrentAccount(account: MSALAccount?) {
        currentAccount = account
    }

    private func authSuccess() {
        isAuthorized = true
        DispatchQueue.main.async {
            self.sessionWasUpdated()
        }
    }

    private func authFailed() {
        isAuthorized = false
        DispatchQueue.main.async {
            self.sessionWasUpdated()
        }
    }

    // MARK: - Content load
    func loadParentItem() {
        guard let applicationContext = applicationContext else {
            return
        }

        guard let parentId = parentItem?.parentReference?.itemReferenceId else {
            currentItem = nil
            parentItem = nil
            return
        }

        var rootID: String = "root"
        if let rootItemID = rootItemID {
            rootID = rootItemID
        }

        let stringUrl: String = kGraphEndpoint + "v1.0/drives/\(rootID)/items/\(parentId)"
        let url = URL(string: stringUrl)

        guard let url = url else {
            return
        }

        let urlRequest = NSMutableURLRequest(url: url)
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.httpMethod = "GET"

        let parameters = MSALAuthenticationProviderOptions(scopes: kScopes)

        authenticationProvider = MSALAuthenticationProvider(publicClientApplication: applicationContext, andOptions: parameters)
        let httpClient: MSHTTPClient = MSClientFactory.createHTTPClient(with: authenticationProvider)

        var driveItem: MSGraphDriveItem? = nil

        let meDataTask: MSURLSessionDataTask = httpClient.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            if error != nil {
                self.authFailed()
                return
            }

            guard let data = data else {
                preconditionFailure("GraphViewController: Couldn't retrieve data.")
            }

            driveItem = try! MSGraphDriveItem(data: data)
            self.parentItem = driveItem
        })
        meDataTask.execute()
    }

    func loadCurrentItem() {
        let itemID: String
        if let currentItem = currentItem {
            itemID = currentItem.entityId
        } else {
            itemID = "root"
        }

        guard let rootItemID = rootItemID else {
            return
        }

        let stringUrl: String = kGraphEndpoint + "v1.0/drives/\(rootItemID)/items/\(itemID)/children"
        let url = URL(string: stringUrl)

        guard let url = url else {
            return
        }

        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: url)
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.httpMethod = "GET"

        load(with: urlRequest)
    }

    private func load(with request: NSMutableURLRequest? = nil) {
        guard let applicationContext = applicationContext else {
            return
        }

        let parameters = MSALAuthenticationProviderOptions(scopes: kScopes)

        authenticationProvider = MSALAuthenticationProvider(publicClientApplication: applicationContext, andOptions: parameters)
        let httpClient: MSHTTPClient = MSClientFactory.createHTTPClient(with: authenticationProvider)

        let urlRequest: NSMutableURLRequest
        if let request = request {
            urlRequest = request
        } else {
            let url = URL(string: getGraphEndpoint())

            guard let url = url else {
                return
            }

            urlRequest = NSMutableURLRequest(url: url)
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            urlRequest.httpMethod = "GET"
        }

        let meDataTask: MSURLSessionDataTask = httpClient.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            if error != nil {
                self.authFailed()
                return
            }

            guard let data = data else {
                preconditionFailure("GraphViewController: Couldn't retrieve data.")
            }

            let collection: MSCollection? = try? MSCollection(data: data)

            guard let collection = collection else {
                return
            }

            guard let collectionValue = collection.value else {
                return
            }

            self.currentItems.removeAll()

            for object in collectionValue {
                let driveItem: MSGraphDriveItem? = MSGraphDriveItem(dictionary: object as? [AnyHashable: Any])
                if let driveItem = driveItem,
                   self.checkFileExtension(for: driveItem) {
                    self.currentItems.append(driveItem)
                    self.getDownloadURL(for: driveItem)

                    if self.rootItemID == nil {
                        self.rootItemID = driveItem.parentReference?.driveId
                    }
                }
            }

            self.authSuccess()
        })
        meDataTask.execute()
    }

    // MARK: - Download
    func startDownloadingDriveItem(item: MSGraphDriveItem) {
        pendingDownloads.append(item)
        triggerNextDownload()
    }

    private func triggerNextDownload() {
        if !pendingDownloads.isEmpty && !downloadInProgress {
            downloadInProgress = true
            guard let firstItem = pendingDownloads.first else {
                return
            }

            downloadDriveItem(item: firstItem)
        }
    }

    private func downloadStarted() {
        delegate.operationWithProgressInformationStarted?()
    }

    private func downloadEnded() {
        delegate.operationWithProgressInformationStopped?()
        downloadInProgress = false
        pendingDownloads.remove(at: 0)
        triggerNextDownload()
    }

    private func downloadDriveItem(item: MSGraphDriveItem) {
        guard let downloadUrl = downloadUrlDictionary[item] else {
            return
        }

        let url = URL(string: downloadUrl)

        guard let url = url else {
            return
        }

        downloadStarted()

        loadData(item: item, url: url) { (data, error) in
            self.downloadEnded()
        }
    }

    private func loadData(item: MSGraphDriveItem, url: URL, completion: @escaping (Data?, Error?) -> Void) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileCachePath = documentDirectory.appendingPathComponent(item.name!, isDirectory: true)

        if FileManager().fileExists(atPath: fileCachePath.path) {
            downloadEnded()
            return
        }

        if let data = try? Data(contentsOf: fileCachePath) {
            completion(data, nil)
            return
        }

        download(url: url, toFile: fileCachePath, item: item) { (error) in
            let data = try? Data(contentsOf: fileCachePath)
            completion(data, error)
        }
    }

    private func download(url: URL, toFile file: URL, item: MSGraphDriveItem, completion: @escaping (Error?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (tempUrl, response, error) in
            guard let tempUrl = tempUrl else {
                completion(error)
                return
            }

            do {
                if FileManager.default.fileExists(atPath: file.path) {
                    try FileManager.default.removeItem(at: file)
                }

                try FileManager.default.copyItem(at: tempUrl, to: file)

                completion(nil)
            }

            catch let fileError {
                completion(fileError)
            }
        }

        if #available(iOS 11.0, *) {
            task.progress.totalUnitCount = item.size
            showProgress(progress: task.progress)
            delegate.updateProgressLabel?(item.name!)
        }
        task.resume()
    }

    private func showProgress(progress: Progress) {
        self.progress = progress
        progress.addObserver(self, forKeyPath: NSStringFromSelector(#selector(getter: self.progress.fractionCompleted)), options: .init(rawValue: 0), context: nil)
    }

    private func getDownloadURL(for driveItem: MSGraphDriveItem) {
        guard let applicationContext = applicationContext else {
            return
        }

        downloadUrlDictionary.removeAll()

        let driveItemID: String = driveItem.entityId

        let stringUrl: String = kGraphEndpoint + "v1.0/drive/items/\(driveItemID)/?select=id,@microsoft.graph.downloadUrl"
        let url = URL(string: stringUrl)

        guard let url = url else {
            return
        }

        let urlRequest = NSMutableURLRequest(url: url)
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.httpMethod = "GET"

        let parameters = MSALAuthenticationProviderOptions(scopes: kScopes)

        authenticationProvider = MSALAuthenticationProvider(publicClientApplication: applicationContext, andOptions: parameters)
        let httpClient: MSHTTPClient = MSClientFactory.createHTTPClient(with: authenticationProvider)

        let meDataTask: MSURLSessionDataTask = httpClient.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            if error != nil {
                self.authFailed()
                return
            }

            guard let data = data else {
                preconditionFailure("GraphViewController: Couldn't retrieve data.")
            }

            guard let result = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] else {
                return
            }

            guard let url = result["@microsoft.graph.downloadUrl"] as? String else {
                self.downloadUrlDictionary[driveItem] = nil
                return
            }

            self.downloadUrlDictionary.updateValue(url, forKey: driveItem)
        })
        meDataTask.execute()
    }
}
