/*****************************************************************************
 * TestHelper.swift
 * VLC for iOSUITests
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Mike JS. Choi <mkchoi212 # icloud.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import XCTest

struct TestHelper {
    let localizationBundle: Bundle
    let inherantBundle = Bundle(for: UIApplication.self)

    init(lang: String, target: AnyClass) {
        localizationBundle = TestHelper.loadLocalizables(lang: lang, target: target)
    }

    func localized(key: String) -> String {
        let res = NSLocalizedString(key, bundle: localizationBundle, comment: "")
        return res
    }
    
    func tap(tabDescription: String, app: XCUIApplication) {
        let target = app.tabBars.buttons.element(matching: .button, identifier: tabDescription)
        
        if target.exists {
            target.tap()
        } else if app.tabBars.buttons.count == 5 {
            // 5 tabBar buttons for iPhone
            let moreTab = app.tabBars.buttons.element(boundBy: 4)
            moreTab.tap()
            app.cells.staticTexts[tabDescription].tap()
        }
    }
}

extension TestHelper {
    static func loadLocalizables(lang: String, target: AnyClass) -> Bundle {
        let mainBundle = Bundle(for: target.self)
        guard let path = mainBundle.path(forResource: lang, ofType: ".lproj") else {
            XCTFail("Could not resolve localization file for \(lang)")
            return Bundle()
        }

        guard let bundle = Bundle(path: path) else {
            XCTFail("Could not load bundle at \(path)")
            return Bundle()
        }

        return bundle
    }
}
