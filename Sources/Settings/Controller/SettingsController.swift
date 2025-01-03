/*****************************************************************************
 * SettingsController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2020 VideoLAN. All rights reserved.
 *
 * Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
 *          Soomin Lee < bubu@mikan.io >
 *          Carola Nitz <caro # videolan.org>
 *          Edgar Fouillet <vlc # edgar.fouillet.eu>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Andrew Breckenridge <asbreckenridge@me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import LocalAuthentication

extension Notification.Name {
    static let VLCDisableGroupingDidChangeNotification = Notification.Name("disableGroupingDidChangeNotfication")
}

class SettingsController: UITableViewController {
    private let cellReuseIdentifier = "settingsCell"
    private let sectionHeaderReuseIdentifier = "sectionHeaderReuseIdentifier"
    private let sectionFooterReuseIdentifier = "sectionFooterReuseIdentifier"
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = NotificationCenter.default
    private let actionSheet = ActionSheet()
    private let specifierManager = ActionSheetSpecifier()
    private var mediaLibraryService: MediaLibraryService
    private var settingsBundle = Bundle()
    private var isBackingUp = false
    private let isLabActivated: Bool = true

    /// the source of all data.
    private var settingsSections: [SettingsSection] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    init(mediaLibraryService: MediaLibraryService) {
        self.mediaLibraryService = mediaLibraryService
        super.init(style: .grouped)
        self.mediaLibraryService.deviceBackupDelegate = self
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PlaybackService.sharedInstance().playerDisplayController.isMiniPlayerVisible ? self.miniPlayerIsShown() : self.miniPlayerIsHidden()
    }

    private func setup() {
        setupUI()
        setNavBarAppearance()
        registerTableViewClasses()
        setupBarButton()
        addObservers()
        reloadSettingsSections()
    }

// MARK: - Setup Functions

    private func setupUI() {
        self.title = NSLocalizedString("Settings", comment: "")
        self.tabBarItem = UITabBarItem(title: NSLocalizedString("Settings", comment: ""),
                                       image: UIImage(named: "Settings"),
                                       selectedImage: UIImage(named: "Settings"))
        self.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.settings
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = false //Fix for iPad
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)
        view.backgroundColor = PresentationTheme.current.colors.background
        actionSheet.modalPresentationStyle = .custom
        guard let unsafeSettingsBundle = getSettingsBundle() else { return }
        settingsBundle = unsafeSettingsBundle
    }

    private func addObservers() {
        notificationCenter.addObserver(self,
                                       selector: #selector(reloadSettingsSections2),
                                       name: UserDefaults.didChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(themeDidChange),
                                       name: .VLCThemeDidChangeNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(miniPlayerIsShown),
                                       name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerDisplayMiniPlayer),
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(miniPlayerIsHidden),
                                       name: NSNotification.Name(rawValue: VLCPlayerDisplayControllerHideMiniPlayer),
                                       object: nil)
    }

    private func registerTableViewClasses() {
        tableView.register(SettingsCell.self,
                           forCellReuseIdentifier: cellReuseIdentifier)
        tableView.register(SettingsHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: sectionHeaderReuseIdentifier)
        tableView.register(SettingsFooterView.self,
                           forHeaderFooterViewReuseIdentifier: sectionFooterReuseIdentifier)
    }

    private func setupBarButton() {
        let aboutBarButton = UIBarButtonItem(title: NSLocalizedString("BUTTON_ABOUT", comment: ""),
                                             style: .plain,
                                             target: self,
                                             action: #selector(showAbout))
        aboutBarButton.tintColor = PresentationTheme.current.colors.orangeUI
        navigationItem.leftBarButtonItem = aboutBarButton
        self.navigationItem.leftBarButtonItem?.accessibilityIdentifier = VLCAccessibilityIdentifier.about

        let docButton = UIBarButtonItem(title: NSLocalizedString("SETTINGS_DOCUMENTATION", comment: ""),
                                             style: .plain,
                                             target: self,
                                             action: #selector(showDocumentation))
        docButton.tintColor = PresentationTheme.current.colors.orangeUI
        navigationItem.rightBarButtonItem = docButton
    }

    private func setNavBarAppearance() {
        if #available(iOS 13.0, *) {
            let navigationBarAppearance = AppearanceManager.navigationbarAppearance
            self.navigationController?.navigationBar.standardAppearance = navigationBarAppearance()
            self.navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance()
        }
    }

// MARK: - Observer & BarButton Actions

    @objc private func showAbout() {
        ImpactFeedbackGenerator().selectionChanged()
        let aboutController = AboutController()
        let aboutNavigationController = AboutNavigationController(rootViewController: aboutController)
        present(aboutNavigationController, animated: true)
    }

    @objc private func showDocumentation() {
        ImpactFeedbackGenerator().selectionChanged()
        UIApplication.shared.open(URL(string: "https://docs.videolan.me/vlc-user/ios/3.X/en/index.html")!)
    }

    @objc private func themeDidChange() {
        self.view.backgroundColor = PresentationTheme.current.colors.background
        setNavBarAppearance()
        self.setNeedsStatusBarAppearanceUpdate()
        self.reloadSettingsSections() // When theme changes hide the black theme section if needed
    }

    @objc private func miniPlayerIsShown() {
        self.tableView.contentInset = UIEdgeInsets(top: 0,
                                                   left: 0,
                                                   bottom: CGFloat(AudioMiniPlayer.height),
                                                   right: 0)
    }

    @objc private func miniPlayerIsHidden() {
        self.tableView.contentInset = UIEdgeInsets(top: 0,
                                                   left: 0,
                                                   bottom: 0,
                                                   right: 0)
    }

// MARK: - Helper Functions
    private func showDonation(indexPath: IndexPath) {
        if #available(iOS 10, *) {
            ImpactFeedbackGenerator().selectionChanged()
        }
        let donationVC = VLCDonationViewController(nibName: "VLCDonationViewController", bundle: nil)
        let donationNC = UINavigationController(rootViewController: donationVC)
        donationNC.modalPresentationStyle = .popover
        donationNC.modalTransitionStyle = .flipHorizontal
        donationNC.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(donationNC, animated: true, completion: nil)
    }

    private func forceRescanAlert() {
        NotificationFeedbackGenerator().warning()
        let alert = UIAlertController(title: NSLocalizedString("FORCE_RESCAN_TITLE", comment: ""),
                                      message: NSLocalizedString("FORCE_RESCAN_MESSAGE", comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                      style: .cancel,
                                      handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_RESCAN", comment: ""),
                                      style: .destructive,
                                      handler: { _ in
            ImpactFeedbackGenerator().selectionChanged()
            self.forceRescanLibrary()
        }))
        present(alert, animated: true, completion: nil)
    }

    private func forceRescanLibrary() {
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            self.mediaLibraryService.forceRescan()
        }
    }

    private func openPrivacySettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func showActionSheet(title: String, preferenceKey: String) {
        specifierManager.playbackTitle = title
        specifierManager.preferenceKey = preferenceKey
        specifierManager.settingsBundle = settingsBundle
        actionSheet.delegate = specifierManager
        actionSheet.dataSource = specifierManager

        if preferenceKey == MainOptions.appearance.preferenceKey ||
            preferenceKey == GenericOptions.automaticallyPlayNextItem.preferenceKey {
            specifierManager.delegate = self
        }

        var numberOfColumns: CGFloat = 1
        if preferenceKey == GenericOptions.defaultPlaybackSpeed.preferenceKey ||
            preferenceKey == SubtitlesOptions.fontColor.preferenceKey {
            numberOfColumns = 2
        }
        actionSheet.numberOfColums = numberOfColumns

        present(actionSheet, animated: false) {
            if preferenceKey != kVLCAutomaticallyPlayNextItem {
                self.actionSheet.collectionView.selectItem(at: self.specifierManager.selectedIndex, animated: false, scrollPosition: .centeredVertically)
            }
        }
    }

    private func playHaptics(settingsItem: SettingsItem) {
        switch settingsItem.action {
        case .toggle:
            break
        default:
            ImpactFeedbackGenerator().selectionChanged()
        }
    }

    private func exportMediaLibrary() {
        self.mediaLibraryService.exportMediaLibrary()
    }

    private func displayResetAlert() {
        let alert = UIAlertController(title: NSLocalizedString("SETTINGS_RESET_TITLE", comment: ""),
                                      message: NSLocalizedString("SETTINGS_RESET_MESSAGE", comment: ""),
                                      preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                         style: .cancel)
        let resetAction = UIAlertAction(title: NSLocalizedString("BUTTON_RESET", comment: ""),
                                        style: .destructive) { _ in
            self.resetOptions()
        }

        alert.addAction(cancelAction)
        alert.addAction(resetAction)

        present(alert, animated: true)
    }

    private func resetOptions() {
        // note that [NSUserDefaults resetStandardUserDefaults] will NOT correctly reset to the defaults
        let appDomain = Bundle.main.bundleIdentifier!
        UserDefaults().removePersistentDomain(forName: appDomain)
    }
}

extension SettingsController {

    @objc func reloadSettingsSections2() {
        print("reloadSettingsSections2")
        reloadSettingsSections()
    }

    @objc func reloadSettingsSections() {
        settingsSections = SettingsSection
            .sections(isLabActivated: isLabActivated,
                      isBackingUp: isBackingUp,
                      isForwardBackwardEqual: userDefaults.bool(forKey: kVLCSettingPlaybackForwardBackwardEqual),
                      isTapSwipeEqual: userDefaults.bool(forKey: kVLCSettingPlaybackTapSwipeEqual))
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        settingsSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        settingsSections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? SettingsCell else {
            return UITableViewCell()
        }

        cell.settingsBundle = settingsBundle
        cell.delegate = self

        let section = settingsSections[indexPath.section]
        let settingsItem = section.items[indexPath.row]
        cell.settingsItem = settingsItem

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let section = settingsSections[indexPath.section]
        let settingsItem = section.items[indexPath.row]

        playHaptics(settingsItem: settingsItem)

        switch settingsItem.action {
        case .isLoading:
            break
        case .toggle:
            break // we get a notification from the switch and do our work there
        case .openPrivacySettings:
            openPrivacySettings()
        case .forceRescanAlert:
            forceRescanAlert()
        case .exportMediaLibrary:
            exportMediaLibrary()
        case .donation:
            showDonation(indexPath: indexPath)
        case .displayResetAlert:
            displayResetAlert()
        case .showActionSheet(let title, let preferenceKey, _):
            showActionSheet(title: title, preferenceKey: preferenceKey)
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView( withIdentifier: sectionHeaderReuseIdentifier) as? SettingsHeaderView else { return nil }
        guard let title = settingsSections[section].title else { return nil }
        headerView.sectionHeaderLabel.text = settingsBundle.localizedString(forKey: title, value: title, table: "Root")
        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionFooterReuseIdentifier) as? SettingsFooterView else { return nil }

        // Do not display a separator for the last section
        return section == tableView.numberOfSections - 1 ? nil : footerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section >= 2 ? 64 : 0
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 25
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

extension SettingsController: MediaLibraryDeviceBackupDelegate {

    func medialibraryDidStartExclusion() {
        DispatchQueue.main.async {
            self.isBackingUp = true
            self.reloadSettingsSections()
        }
    }

    func medialibraryDidCompleteExclusion() {
        DispatchQueue.main.async {
            self.isBackingUp = false
            self.reloadSettingsSections()
        }
    }
}

extension SettingsController: MediaLibraryHidingDelegate {
    func medialibraryDidStartHiding() {
        DispatchQueue.main.async {
            self.reloadSettingsSections()
        }
    }

    func medialibraryDidCompleteHiding() {
        DispatchQueue.main.async {
            self.reloadSettingsSections()
        }
    }
}

// MARK: - SwitchOn Delegates

extension SettingsController: SettingsCellDelegate {
    func settingsCellDidChangeSwitchState(preferenceKey: String, isOn: Bool) {
        userDefaults.set(isOn, forKey: preferenceKey)

        switch preferenceKey {
        case kVLCSettingPasscodeOnKey:
            passcodeLockSwitchOn(state: isOn)
        case kVLCSettingHideLibraryInFilesApp:
            medialibraryHidingLockSwitchOn(state: isOn)
        case kVLCSettingBackupMediaLibrary:
            mediaLibraryBackupActivateSwitchOn(state: isOn)
        case kVLCSettingsDisableGrouping:
            medialibraryDisableGroupingSwitchOn(state: isOn)
        case kVLCSettingPlaybackTapSwipeEqual, kVLCSettingPlaybackForwardBackwardEqual:
            reloadSettingsSections()
        default:
            break
        }
    }
}

extension SettingsController {

    func passcodeLockSwitchOn(state: Bool) {
        if state {
            let passcodeLockController = PasscodeLockController(action: .set)
            let passcodeNavigationController = UINavigationController(rootViewController: passcodeLockController)
            passcodeNavigationController.modalPresentationStyle = .fullScreen
            present(passcodeNavigationController, animated: true) {
                self.reloadSettingsSections() //To show/hide biometric row
            }
        } else {
            reloadSettingsSections()
        }
    }
}

extension SettingsController {
    func medialibraryHidingLockSwitchOn(state: Bool) {
        mediaLibraryService.hideMediaLibrary(state)
    }
}

extension SettingsController {
    func mediaLibraryBackupActivateSwitchOn(state: Bool) {
        mediaLibraryService.excludeFromDeviceBackup(state)
    }
}

extension SettingsController {
    func medialibraryDisableGroupingSwitchOn(state: Bool) {
        notificationCenter.post(name: .VLCDisableGroupingDidChangeNotification, object: self)
    }
}

extension SettingsController: ActionSheetSpecifierDelegate {
    func actionSheetSpecifierHandleToggleSwitch(for cell: ActionSheetCell, state: Bool) {
        switch cell.identifier {
        case .blackBackground:
            userDefaults.setValue(state, forKey: kVLCSettingAppThemeBlack)
            PresentationTheme.themeDidUpdate()
        case .playNextItem:
            userDefaults.setValue(state, forKey: kVLCAutomaticallyPlayNextItem)
            break
        case .playlistPlayNextItem:
            userDefaults.setValue(state, forKey: kVLCPlaylistPlayNextItem)
            break
        default:
            break
        }
    }
}
