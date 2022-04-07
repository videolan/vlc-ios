/*****************************************************************************
 * SettingsController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2020 VideoLAN. All rights reserved.
 *
 * Authors: Swapnanil Dhol <swapnanildhol # gmail.com>
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
        view.backgroundColor = PresentationTheme.current.colors.background
        actionSheet.modalPresentationStyle = .custom
        guard let unsafeSettingsBundle = getSettingsBundle() else { return }
        settingsBundle = unsafeSettingsBundle
    }

    private func addObservers() {
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

        let tipJarBarButton = UIBarButtonItem(title: NSLocalizedString("GIVE_TIP", comment: ""),
                                             style: .plain,
                                             target: self,
                                             action: #selector(showTipJar))
        aboutBarButton.tintColor = PresentationTheme.current.colors.orangeUI
        navigationItem.rightBarButtonItem = tipJarBarButton
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
        if #available(iOS 10, *) {
            ImpactFeedbackGenerator().selectionChanged()
        }
        let aboutController = AboutController()
        let aboutNavigationController = AboutNavigationController(rootViewController: aboutController)
        present(aboutNavigationController, animated: true)
    }

    @objc private func showTipJar() {
        if #available(iOS 10, *) {
            ImpactFeedbackGenerator().selectionChanged()
        }
        let vc = StoreViewController(nibName: "VLCStoreViewController", bundle: nil)
        let storeVC = UINavigationController(rootViewController: vc)
        present(storeVC, animated: true, completion: nil)
    }

    @objc private func themeDidChange() {
        self.view.backgroundColor = PresentationTheme.current.colors.background
        setNavBarAppearance()
        self.setNeedsStatusBarAppearanceUpdate()
        self.tableView.reloadData() // When theme changes hide the black theme section if needed
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

    private func forceRescanAlert() {
        if #available(iOS 10, *) {
            NotificationFeedbackGenerator().warning()
        }
        let alert = UIAlertController(title: NSLocalizedString("FORCE_RESCAN_TITLE", comment: ""),
                                      message: NSLocalizedString("FORCE_RESCAN_MESSAGE", comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_CANCEL", comment: ""),
                                      style: .cancel,
                                      handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_RESCAN", comment: ""),
                                      style: .destructive,
                                      handler: { _ in
                                        if #available(iOS 10, *) {
                                            ImpactFeedbackGenerator().selectionChanged()
                                        }
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
        if #available(iOS 10.0, *) {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: nil)
        }
    }

    private func showActionSheet(for sectionType: SectionType?) {
        guard let sectionType = sectionType else { return }
        guard !sectionType.containsSwitch else { return }
        guard let preferenceKey = sectionType.preferenceKey else {
            assertionFailure("SettingsController: No Preference Key Available.")
            return
        }
        showActionSheet(preferenceKey: preferenceKey)
    }

    private func showActionSheet(preferenceKey: String?) {
        specifierManager.preferenceKey = preferenceKey
        specifierManager.settingsBundle = settingsBundle
        actionSheet.delegate = specifierManager
        actionSheet.dataSource = specifierManager
        present(actionSheet, animated: false) {
            self.actionSheet.collectionView.selectItem(at: self.specifierManager.selectedIndex, animated: false, scrollPosition: .centeredVertically)
        }
    }

    private func playHaptics(sectionType: SectionType?) {
        guard let sectionType = sectionType else { return }
        if #available(iOS 10, *), !sectionType.containsSwitch {
            ImpactFeedbackGenerator().selectionChanged()
        }
    }

    private func exportMediaLibrary() {
        self.mediaLibraryService.exportMediaLibrary()
    }
}

extension SettingsController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = SettingsSection.allCases.count
        // Remove the last section if the lab is deactivated
        if isLabActivated == false {
            numberOfSections = numberOfSections - 1
        }
        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return MainOptions.allCases.count
        case 1:
            return GenericOptions.allCases.count
        case 2:
            return PrivacyOptions.allCases.count
        case 3:
            return PlaybackControlOptions.allCases.count
        case 4:
            return VideoOptions.allCases.count
        case 5:
            return SubtitlesOptions.allCases.count
        case 6:
            return AudioOptions.allCases.count
        case 7:
            return CastingOptions.allCases.count
        case 8:
            return MediaLibraryOptions.allCases.count
        case 9:
            return NetworkOptions.allCases.count
        case 10:
            return Lab.allCases.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath == [SettingsSection.privacy.rawValue, PrivacyOptions.enableBiometrics.rawValue] && !userDefaults.bool(forKey: kVLCSettingPasscodeOnKey) {
            //If the passcode lock is on we return a default UITableViewCell else
            //while hiding the biometric option row using a cell height of 0
            //constraint warnings will be printed to the console since the cell height (0)
            //collapses on given constraints (Top, leading, trailing, Bottom of StackView to Cell)
            return UITableViewCell()
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? SettingsCell else {
            return UITableViewCell()
        }
        cell.settingsBundle = settingsBundle
        guard let section = SettingsSection(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        switch section {
        case .main:
            let main = MainOptions(rawValue: indexPath.row)
            let brightThemeForced = userDefaults.integer(forKey: kVLCSettingAppTheme) == kVLCSettingAppThemeBright
            if indexPath.row == MainOptions.blackTheme.rawValue {
                if brightThemeForced {
                    //If the user wants the bright theme, we hide black theme settings
                    cell.isHidden = true
                }
            }
            cell.sectionType = main
            cell.blackThemeSwitchDelegate = self
        case .generic:
            let generic = GenericOptions(rawValue: indexPath.row)
            cell.sectionType = generic
        case .privacy:
            let privacy = PrivacyOptions(rawValue: indexPath.row)
            let isPasscodeOn = userDefaults.bool(forKey: kVLCSettingPasscodeOnKey)
            if indexPath.row == PrivacyOptions.enableBiometrics.rawValue {
                if !isPasscodeOn || privacy?.preferenceKey == nil {
                    //If Passcode Lock Switch is off or Biometric Row Preference Key returns nil
                    //We hide the cell
                    cell.isHidden = true
                }
            }
            cell.sectionType = privacy
            cell.passcodeSwitchDelegate = self
            cell.medialibraryHidingSwitchDelegate = self
        case .gestureControl:
            let gestureControlOptions = PlaybackControlOptions(rawValue: indexPath.row)
            cell.sectionType = gestureControlOptions
        case .video:
            let videoOptions = VideoOptions(rawValue: indexPath.row)
            cell.sectionType = videoOptions
        case .subtitles:
            let subtitlesOptions = SubtitlesOptions(rawValue: indexPath.row)
            cell.sectionType = subtitlesOptions
        case .audio:
            let audioOptions = AudioOptions(rawValue: indexPath.row)
            cell.sectionType = audioOptions
        case .casting:
            let castingOptions = CastingOptions(rawValue: indexPath.row)
            cell.sectionType = castingOptions
        case .mediaLibrary:
            let mediaLibOptions = MediaLibraryOptions(rawValue: indexPath.row)
            if indexPath.row == MediaLibraryOptions.forceVLCToRescanTheMediaLibrary.rawValue {
                cell.mainLabel.textColor = PresentationTheme.current.colors.orangeUI
            }
            cell.mediaLibraryBackupSwitchDelegate = self
            cell.medialibraryDisableGroupingSwitchDelegate = self
            if indexPath.row == MediaLibraryOptions.includeMediaLibInDeviceBackup.rawValue {
                if isBackingUp {
                    cell.accessoryView = .none
                    cell.accessoryType = .none 
                    cell.activityIndicator.startAnimating()
                } else {
                    cell.activityIndicator.stopAnimating()
                }
                cell.showsActivityIndicator = isBackingUp
            }
            cell.sectionType = mediaLibOptions
            if indexPath.row == 0 {
                cell.accessoryView = .none
                cell.accessoryType = .none
            }
        case .network:
            let networkOptions = NetworkOptions(rawValue: indexPath.row)
            cell.sectionType = networkOptions
        case .lab:
            let lab = Lab(rawValue: indexPath.row)
            cell.sectionType = lab
            if indexPath.row == 1 {
                cell.accessoryView = .none
                cell.accessoryType = .none
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = SettingsSection(rawValue: indexPath.section) else { return }
        if section == .main && indexPath.row == 0 {
            openPrivacySettings()
            return
        }
        if section == .mediaLibrary && indexPath.row == 0 {
            forceRescanAlert()
            return
        }
        if section == .lab && indexPath.row == 1 {
            exportMediaLibrary()
            return
        }
        switch section {
        case .main:
            let mainSection = MainOptions(rawValue: indexPath.row)
            playHaptics(sectionType: mainSection)
            showActionSheet(for: mainSection)
        case .generic:
            let genericSection = GenericOptions(rawValue: indexPath.row)
            playHaptics(sectionType: genericSection)
            showActionSheet(for: genericSection)
        case .privacy:
            let privacySection = PrivacyOptions(rawValue: indexPath.row)
            playHaptics(sectionType: privacySection)
        case .gestureControl:
            break
        case .video:
            let videoSection = VideoOptions(rawValue: indexPath.row)
            playHaptics(sectionType: videoSection)
            showActionSheet(for: videoSection)
        case .subtitles:
            let subtitleSection = SubtitlesOptions(rawValue: indexPath.row)
            playHaptics(sectionType: subtitleSection)
            showActionSheet(for: subtitleSection)
        case .audio:
            break
        case .casting:
            let castingSection = CastingOptions(rawValue: indexPath.row)
            playHaptics(sectionType: castingSection)
            showActionSheet(for: castingSection)
        case .mediaLibrary:
            break
        case .network:
            let networkSection = NetworkOptions(rawValue: indexPath.row)
            playHaptics(sectionType: networkSection)
            showActionSheet(for: networkSection)
        case .lab:
            break
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView( withIdentifier: sectionHeaderReuseIdentifier) as? SettingsHeaderView else { return nil }
        guard let description = SettingsSection.init(rawValue: section)?.description else { return nil }
        headerView.sectionHeaderLabel.text = settingsBundle.localizedString(forKey: description, value: description, table: "Root")
        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionFooterReuseIdentifier) as? SettingsFooterView else { return nil }
        return section == 8 ? nil : footerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 64
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 25
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let automaticDimension = UITableView.automaticDimension
        if indexPath == [SettingsSection.main.rawValue, MainOptions.blackTheme.rawValue] {
            let brightThemeForced = userDefaults.integer(forKey: kVLCSettingAppTheme) == kVLCSettingAppThemeBright
            return brightThemeForced ? 0 : automaticDimension //If the user wants the bright theme, we hide black theme settings
        }
        if indexPath == [SettingsSection.privacy.rawValue, PrivacyOptions.enableBiometrics.rawValue] {
            let isPasscodeOn = userDefaults.bool(forKey: kVLCSettingPasscodeOnKey)
            let privacySection = PrivacyOptions(rawValue: indexPath.row)
            if privacySection?.preferenceKey == nil {
                //LAContext canEvaluatePolicy supports iOS 11.0.1 and above.
                //If canEvaluatePolicy is not supported the preference key for the biometric row is nil.
                //Therefore we never show the biometric options row in this case
                return 0
            }
            return isPasscodeOn ? automaticDimension : 0 //If Passcode Lock is turned off we hide the biometric options row
        }
        return automaticDimension
    }
}

extension SettingsController: MediaLibraryDeviceBackupDelegate {

    func medialibraryDidStartExclusion() {
        DispatchQueue.main.async {
            self.isBackingUp = true
            self.tableView.reloadData()
        }
    }

    func medialibraryDidCompleteExclusion() {
        DispatchQueue.main.async {
            self.isBackingUp = false
            self.tableView.reloadData()
        }
    }
}

extension SettingsController: MediaLibraryHidingDelegate {
    func medialibraryDidStartHiding() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func medialibraryDidCompleteHiding() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

// MARK: - SwitchOn Delegates

extension SettingsController: BlackThemeActivateDelegate {
    func blackThemeSwitchOn(state: Bool) {
        PresentationTheme.themeDidUpdate()
    }
}

extension SettingsController: PasscodeActivateDelegate {

    func passcodeLockSwitchOn(state: Bool) {
        if state {
            guard let passcodeLockController = PasscodeLockController(action: .set) else { return }
            let passcodeNavigationController = UINavigationController(rootViewController: passcodeLockController)
            passcodeNavigationController.modalPresentationStyle = .fullScreen
            present(passcodeNavigationController, animated: true) {
                self.tableView.reloadData() //To show/hide biometric row
            }
        } else {
            tableView.reloadData()
        }
    }
}

extension SettingsController: MedialibraryHidingActivateDelegate {
    func medialibraryHidingLockSwitchOn(state: Bool) {
        mediaLibraryService.hideMediaLibrary(state)
    }
}

extension SettingsController: MediaLibraryBackupActivateDelegate {
    func mediaLibraryBackupActivateSwitchOn(state: Bool) {
        mediaLibraryService.excludeFromDeviceBackup(state)
    }
}

extension SettingsController: MediaLibraryDisableGroupingDelegate {
    func medialibraryDisableGroupingSwitchOn(state: Bool) {
        notificationCenter.post(name: .VLCDisableGroupingDidChangeNotification, object: self)
    }
}
