/*****************************************************************************
 * VLCNetworkLoginTVViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019, 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

@objc class VLCNetworkLoginTVViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var serverField: UITextField!
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var workgroupField: UITextField!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var buttonConnect: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nothingFoundView: UIView!
    @IBOutlet weak var nothingFoundLabel: UILabel!

    var serverList: NSMutableArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()

        serverList = NSMutableArray.init()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ubiquitousKeyValueStoreDidChange),
                                               name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: NSUbiquitousKeyValueStore.default)

        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)

        let ukvStore = NSUbiquitousKeyValueStore.default
        ukvStore.synchronize()
        let ukvServerList = ukvStore.array(forKey: kVLCStoredServerList)
        if ukvServerList != nil {
            serverList.addObjects(from: ukvServerList!)
        }

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGestureRecognizer.minimumPressDuration = 1
        longPressGestureRecognizer.delaysTouchesBegan = true
        longPressGestureRecognizer.delegate = self
        tableView.addGestureRecognizer(longPressGestureRecognizer)

        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        segmentedControl.setTitle(NSLocalizedString("SMB_CIFS_FILE_SERVERS_SHORT", comment: ""), forSegmentAt: 0)
        segmentedControl.setTitle(NSLocalizedString("FTP_SHORT", comment: ""), forSegmentAt: 1)
        segmentedControl.setTitle(NSLocalizedString("PLEX_SHORT", comment: ""), forSegmentAt: 2)
        segmentedControl.setTitle(NSLocalizedString("NFS_SHORT", comment: ""), forSegmentAt: 3)
        segmentedControl.setTitle(NSLocalizedString("SFTP_SHORT", comment: ""), forSegmentAt: 4)
    }

    func configureAppearance() {
        setSegControlProtocolIdentifier(VLCNetworkServerProtocolIdentifierFTP)

        serverField.placeholder = NSLocalizedString("SERVER", comment: "")
        serverField.delegate = self
        portField.placeholder = NSLocalizedString("SERVER_PORT", comment: "")
        portField.delegate = self
        portField.keyboardType = UIKeyboardType.numberPad
        usernameField.placeholder = NSLocalizedString("USER_LABEL", comment: "")
        passwordField.placeholder = NSLocalizedString("PASSWORD_LABEL", comment: "")
        workgroupField.placeholder = NSLocalizedString("DSM_WORKGROUP", comment: "")
        workgroupField.isHidden = true
        if #available(tvOS 10.0, *) {
            serverField.textContentType = UITextContentType.URL
        }
        if #available(tvOS 11.0, *) {
            usernameField.textContentType = UITextContentType.username
            passwordField.textContentType = UITextContentType.password
        }

        buttonSave.setTitle(NSLocalizedString("BUTTON_SAVE", comment: ""), for: .normal)
        buttonSave.isEnabled = false
        buttonConnect.setTitle(NSLocalizedString("BUTTON_CONNECT", comment: ""), for: .normal)
        buttonConnect.isEnabled = false

        nothingFoundLabel.text = NSLocalizedString("NO_SAVING_DATA", comment: "")
    }

    @objc func ubiquitousKeyValueStoreDidChange(notification: NSNotification) {
        if !Thread.isMainThread {
            self.performSelector(onMainThread: #selector(ubiquitousKeyValueStoreDidChange), with: notification, waitUntilDone: false)
            return
        }
        guard let storedServerList = NSUbiquitousKeyValueStore.default.array(forKey: kVLCStoredServerList)
        else {
            return
        }
        serverList?.setArray(storedServerList)
        tableView.reloadData()
    }

    @objc func segmentedControlChanged(_ control: UISegmentedControl) {
        let selectedIndex = control.selectedSegmentIndex
        if selectedIndex == 0 {
            workgroupField.isHidden = false
            workgroupField.text = "WORKGROUP"
        } else {
            workgroupField.isHidden = true
            workgroupField.text = ""
        }
    }

    // MARK: - UILongPressGestureRecognizer Action
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == UIGestureRecognizer.State.ended {
            return
        }
        let point = gestureReconizer.location(in: self.tableView)

        if let indexPath = self.tableView.indexPathForRow(at: point) {
            let cell = self.tableView.cellForRow(at: indexPath)

            let alertController = UIAlertController(title: cell?.textLabel?.text,
                                                    message: cell?.detailTextLabel?.text,
                                                    preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_DELETE", comment: ""), style: .destructive, handler: { action in
                self.deleteItem(indexPath.row)
            }))

            self.present(alertController, animated: true)
        }
    }

    // MARK: -
    func protocolIdentifierForProtocol(_ segmentedControl: UISegmentedControl) -> String? {
        var protocolIdentifier: String? = nil
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            protocolIdentifier = VLCNetworkServerProtocolIdentifierSMB
            break
        case 1:
            protocolIdentifier = VLCNetworkServerProtocolIdentifierFTP
            break
        case 2:
            protocolIdentifier = VLCNetworkServerProtocolIdentifierPlex
            break
        case 3:
            protocolIdentifier = VLCNetworkServerProtocolIdentifierNFS
            break
        case 4:
            protocolIdentifier = VLCNetworkServerProtocolIdentifierSFTP
        default:
            break
        }
        return protocolIdentifier
    }

    func setSegControlProtocolIdentifier(_ protocolIdentifier: String) {
        switch protocolIdentifier {
        case VLCNetworkServerProtocolIdentifierSMB:
            segmentedControl.selectedSegmentIndex = 0
            break
        case VLCNetworkServerProtocolIdentifierFTP:
            segmentedControl.selectedSegmentIndex = 1
            break
        case VLCNetworkServerProtocolIdentifierPlex:
            segmentedControl.selectedSegmentIndex = 2
            break
        case VLCNetworkServerProtocolIdentifierNFS:
            segmentedControl.selectedSegmentIndex = 3
            break
        case VLCNetworkServerProtocolIdentifierSFTP:
            segmentedControl.selectedSegmentIndex = 4
            break
        default:
            break
        }
    }

    func serverLoginInformation(protocolSection: String) -> VLCNetworkServerLoginInformation {
        var login = VLCNetworkServerLoginInformation.init()
        login = VLCNetworkServerLoginInformation.newLoginInformation(forProtocol: protocolSection)

        login.address = serverField.text!
        if !(portField.text?.isEmpty)! {
            login.port = NSNumber.init(value: Int(portField.text!)!)
        }
        login.username = usernameField.text
        login.password = passwordField.text

        if login.protocolIdentifier == VLCNetworkServerProtocolIdentifierSMB {
            for fieldInfo: VLCNetworkServerLoginInformationField in login.additionalFields {
                fieldInfo.textValue = workgroupField.text ?? "WORKGROUP"
            }
        }

        return login
    }

    func showBrowserWithLogin(_ login: VLCNetworkServerLoginInformation) {
        var serverBrowser: VLCNetworkServerBrowser? = nil
        let identifier = login.protocolIdentifier as NSString

        if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierFTP) {
            serverBrowser = VLCNetworkServerBrowserVLCMedia.ftpNetworkServerBrowser(withLogin: login)
        } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierPlex) {
            serverBrowser = VLCNetworkServerBrowserPlex.init(login: login)
        } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierSMB) {
            serverBrowser = VLCNetworkServerBrowserVLCMedia.smbNetworkServerBrowser(withLogin: login)
        } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierNFS) {
            serverBrowser = VLCNetworkServerBrowserVLCMedia.nfsNetworkServerBrowser(withLogin: login)
        } else if identifier.isEqual(to: VLCNetworkServerProtocolIdentifierSFTP) {
            serverBrowser = VLCNetworkServerBrowserVLCMedia.sftpNetworkServerBrowser(withLogin: login)
        }

        if serverBrowser != nil {
            let targetViewController: VLCServerBrowsingTVViewController = VLCSearchableServerBrowsingTVViewController.init(serverBrowser: serverBrowser!)
            self.present(targetViewController, animated: true, completion: nil)
        }
    }

    func deleteItem(_ row: NSInteger) {
        let serviceString = serverList[row]
        do {
            try XKKeychainGenericPasswordItem.removeItems(forService: serviceString as? String)
        } catch let error as NSError {
            print("Failed to delete login with error: \(error)")
            return
        }
        serverList.remove(serviceString)
        let ukvStore = NSUbiquitousKeyValueStore.default
        ukvStore.set(serverList, forKey: kVLCStoredServerList)
        ukvStore.synchronize()
        tableView.reloadData()
    }

    // MARK: - UITableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let serverListCount = serverList.count
        if serverListCount > 0 {
            nothingFoundView.isHidden = true
        } else {
            nothingFoundView.isHidden = false
        }
        return serverList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "LoginSavedTableViewCell")
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "LoginSavedTableViewCell")
        }

        let serviceString = serverList[indexPath.row]
        let service = URL.init(string: serviceString as! String)
        cell?.textLabel?.text = String(format: "%@ [%@]", service?.host ?? "", service?.scheme?.uppercased() ?? "")
        do {
            let keychainItem = try XKKeychainGenericPasswordItem.init(forService: (serviceString as? String), account: nil)
            cell?.detailTextLabel?.text = keychainItem.account
        } catch {
            cell?.detailTextLabel?.text = ""
        }
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let login = VLCNetworkServerLoginInformation.init(keychainIdentifier: serverList?[indexPath.row] as! String)
        do {
            try login.loadFromKeychain()
        } catch {
            print("Failed to load login from key chain")
            return
        }

        setSegControlProtocolIdentifier(login.protocolIdentifier)
        segmentedControlChanged(segmentedControl)

        usernameField.text = login.username
        passwordField.text = login.password
        portField.text = login.port.stringValue
        serverField.text = login.address

        if login.protocolIdentifier == VLCNetworkServerProtocolIdentifierSMB {
            for fieldInfo: VLCNetworkServerLoginInformationField in login.additionalFields {
                workgroupField.text = fieldInfo.textValue
            }
        }

        showBrowserWithLogin(login)
    }

    // MARK: - IBAction
    @IBAction func saveLogin(_ sender: Any) {
        let protocolSection = protocolIdentifierForProtocol(segmentedControl)
        if protocolSection != nil {
            let login = serverLoginInformation(protocolSection: protocolSection!)
            do {
                try login.saveToKeychain()
                serverField.text = nil
                portField.text = nil
                usernameField.text = nil
                passwordField.text = nil
            } catch let error as NSError {
                // TODO : add vclalertview ?
                print("Failed to save login with error: \(error)")
            }

            let serviceIdentifier = login.keychainServiceIdentifier
            serverList.add(serviceIdentifier)
            let ukvStore = NSUbiquitousKeyValueStore.default
            ukvStore.set(serverList, forKey: kVLCStoredServerList)
            ukvStore.synchronize()

            tableView.reloadData()
            //showBrowserWithLogin(login)
        }
    }
    
    @IBAction func ConnectToServer(_ sender: Any) {
        let protocolSection = protocolIdentifierForProtocol(segmentedControl)
        if protocolSection != nil {
            let login = serverLoginInformation(protocolSection: protocolSection!)
            showBrowserWithLogin(login)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.serverField {
            self.buttonSave.isEnabled = !(textField.text?.isEmpty)!
            self.buttonConnect.isEnabled = !(textField.text?.isEmpty)!
        } else if textField == self.portField {
            if Int(portField.text!) == nil {
                portField.text = ""
            }
        }
    }
}
