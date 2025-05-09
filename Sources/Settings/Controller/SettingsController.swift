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

import LocalAuthentication
import UIKit

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
            // only reload when it's actually different
            if oldValue != settingsSections {
                tableView.reloadData()
            }
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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PlaybackService.sharedInstance().playerDisplayController.isMiniPlayerVisible ? miniPlayerIsShown() : miniPlayerIsHidden()
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
        title = NSLocalizedString("Settings", comment: "")
        tabBarItem = UITabBarItem(title: NSLocalizedString("Settings", comment: ""),
                                  image: UIImage(named: "Settings"),
                                  selectedImage: UIImage(named: "Settings"))
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.settings
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = false // Fix for iPad
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)
        view.backgroundColor = PresentationTheme.current.colors.background
        actionSheet.modalPresentationStyle = .custom
        guard let unsafeSettingsBundle = getSettingsBundle() else { return }
        settingsBundle = unsafeSettingsBundle
    }

    private func addObservers() {
        notificationCenter.addObserver(self,
                                       selector: #selector(reloadSettingsSections),
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
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = VLCAccessibilityIdentifier.about

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
#if os(iOS)
        ImpactFeedbackGenerator().selectionChanged()
#endif
        let aboutController = AboutController()
        let aboutNavigationController = AboutNavigationController(rootViewController: aboutController)
        present(aboutNavigationController, animated: true)
    }

    @objc private func showDocumentation() {
#if os(iOS)
        ImpactFeedbackGenerator().selectionChanged()
#endif
        UIApplication.shared.open(URL(string: "https://docs.videolan.me/vlc-user/ios/3.X/en/index.html")!)
    }

    @objc private func themeDidChange() {
        view.backgroundColor = PresentationTheme.current.colors.background
        setNavBarAppearance()
#if os(iOS)
        setNeedsStatusBarAppearanceUpdate()
#endif

        tableView.visibleCells.forEach { cell in
            guard let cell = cell as? SettingsCell else { return }

            cell.themeChanged()
        }

        reloadSettingsSections()
    }

    @objc private func miniPlayerIsShown() {
        tableView.contentInset = UIEdgeInsets(top: 0,
                                              left: 0,
                                              bottom: CGFloat(AudioMiniPlayer.height),
                                              right: 0)
    }

    @objc private func miniPlayerIsHidden() {
        tableView.contentInset = UIEdgeInsets(top: 0,
                                              left: 0,
                                              bottom: 0,
                                              right: 0)
    }

    // MARK: - Helper Functions

    private func showDonation(indexPath: IndexPath) {
#if os(iOS)
        ImpactFeedbackGenerator().selectionChanged()
#endif
        let donationVC = VLCDonationViewController(nibName: "VLCDonationViewController", bundle: nil)
        let donationNC = UINavigationController(rootViewController: donationVC)
        donationNC.modalPresentationStyle = .popover
        donationNC.modalTransitionStyle = .flipHorizontal
        donationNC.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(donationNC, animated: true, completion: nil)
    }

    private func forceRescanAlert() {
#if os(iOS)
        NotificationFeedbackGenerator().warning()
#endif
        let alert = UIAlertController(title: NSLocalizedString("FORCE_RESCAN_TITLE", comment: ""),
                                      message: NSLocalizedString("FORCE_RESCAN_MESSAGE", comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                      style: .cancel,
                                      handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_RESCAN", comment: ""),
                                      style: .destructive,
                                      handler: { _ in
#if os(iOS)
                                          ImpactFeedbackGenerator().selectionChanged()
#endif
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

        var numberOfColumns: CGFloat = 1

        switch preferenceKey {
        case MainOptions.appearance.preferenceKey, GenericOptions.automaticallyPlayNextItem.preferenceKey:
            specifierManager.delegate = self

        case GenericOptions.defaultPlaybackSpeed.preferenceKey, SubtitlesOptions.fontColor.preferenceKey:
            numberOfColumns = 2

        default:
            break
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
#if os(iOS)
            ImpactFeedbackGenerator().selectionChanged()
#endif
        }
    }

    private func exportMediaLibrary() {
        mediaLibraryService.exportMediaLibrary()
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
    @objc func reloadSettingsSections() {
        settingsSections = SettingsSection
            .sections(isLabActivated: isLabActivated,
                      isBackingUp: isBackingUp,
                      isForwardBackwardEqual: userDefaults.bool(forKey: kVLCSettingPlaybackForwardBackwardEqual),
                      isTapSwipeEqual: userDefaults.bool(forKey: kVLCSettingPlaybackTapSwipeEqual))
    }

    override func numberOfSections(in _: UITableView) -> Int {
        settingsSections.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        settingsSections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? SettingsCell else {
            return UITableViewCell()
        }

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
        case let .showActionSheet(title, preferenceKey, _):
            showActionSheet(title: title, preferenceKey: preferenceKey)
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionHeaderReuseIdentifier) as? SettingsHeaderView else { return nil }
        guard let title = settingsSections[section].title else { return nil }
        headerView.sectionHeaderLabel.text = title
        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionFooterReuseIdentifier) as? SettingsFooterView else { return nil }

        // Do not display a separator for the last section
        return section == tableView.numberOfSections - 1 ? nil : footerView
    }

    override func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section >= 2 ? 64 : 0
    }

    override func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 25
    }

    override func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return 64
    }

    override func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        SettingsCell.height(
            for: settingsSections[indexPath.section].items[indexPath.item],
            width: tableView.bounds.width
        )
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
    func settingsCellDidChangeSwitchState(cell _: SettingsCell, preferenceKey: String, isOn: Bool) {
        switch preferenceKey {
        case kVLCSettingAppThemeBlack:
            PresentationTheme.themeDidUpdate()
        case kVLCSettingPasscodeOnKey:
            passcodeLockSwitchOn(state: isOn)
        case kVLCSettingHideLibraryInFilesApp:
            medialibraryHidingLockSwitchOn(state: isOn)
        case kVLCSettingBackupMediaLibrary:
            mediaLibraryBackupActivateSwitchOn(state: isOn)
        case kVLCSettingsDisableGrouping:
            medialibraryDisableGroupingSwitchOn(state: isOn)
        default:
            break
        }
    }

    func settingsCellInfoButtonPressed(cell: SettingsCell, preferenceKey: String) {
        guard let settingSpecifier = getSettingsSpecifier(for: preferenceKey) else {
            return
        }

        let title = settingsBundle.localizedString(forKey: settingSpecifier.title, value: settingSpecifier.title, table: "Root")
        let alert = UIAlertController(title: title,
                                      message: settingsBundle.localizedString(forKey: settingSpecifier.infobuttonvalue,
                                                                              value: settingSpecifier.infobuttonvalue,
                                                                              table: "Root"),
                                      preferredStyle: .actionSheet)
        let donetitle = NSLocalizedString("BUTTON_DONE", comment: "")
        alert.addAction(UIAlertAction(title: donetitle, style: .cancel, handler: nil))

        // Set up the popoverPresentationController to avoid crash issues on iPad.
        alert.popoverPresentationController?.sourceView = cell
        alert.popoverPresentationController?.permittedArrowDirections = .any
        alert.popoverPresentationController?.sourceRect = cell.bounds

        self.present(alert, animated: true, completion: nil)
    }
}

extension SettingsController {
    func passcodeLockSwitchOn(state: Bool) {
        if state {
            KeychainCoordinator.passcodeService.setSecret { success in
                // If the user cancels setting the password, the toggle should revert to the unset state.
                // This ensures the UI reflects the correct state.
                UserDefaults.standard.set(success, forKey: kVLCSettingPasscodeOnKey)
                self.reloadSettingsSections() // To show/hide biometric row
            }
        } else {
            // When disabled any existing passcode should be removed.
            // If user previously set a passcode and then disable and enable it
            // the new passcode view will be showed, but if user terminates the app
            // passcode will remain open even if the user doesn't set the new passcode.
            // So, this may cause the app being locked.
            try? KeychainCoordinator.passcodeService.removeSecret()

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
        mediaLibraryService.includeInDeviceBackup(state)
    }
}

extension SettingsController {
    func medialibraryDisableGroupingSwitchOn(state _: Bool) {
        notificationCenter.post(name: .VLCDisableGroupingDidChangeNotification, object: self)
    }
}

extension SettingsController: ActionSheetSpecifierDelegate {
    func actionSheetSpecifierHandleToggleSwitch(for cell: ActionSheetCell, state: Bool) {
        switch cell.identifier {
        case .playNextItem:
            userDefaults.setValue(state, forKey: kVLCAutomaticallyPlayNextItem)
        case .playlistPlayNextItem:
            userDefaults.setValue(state, forKey: kVLCPlaylistPlayNextItem)
        default:
            break
        }
    }
}
