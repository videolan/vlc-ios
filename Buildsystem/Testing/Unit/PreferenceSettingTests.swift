/*****************************************************************************
 * PreferenceSettingTests.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2025 VideoLAN. All rights reserved.
 *
 * Authors: Craig Reyenga <craig.reyenga # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import XCTest
@testable import VLC

final class PreferenceSettingTests: XCTestCase {

    func testDecodeAll() {
        let fileURL = Bundle(for: type(of: self)).url(forResource: "PreferenceSettingTestsSuccess",
                                                      withExtension: "plist")!
        let data = try! Data(contentsOf: fileURL)

        let decoder = PropertyListDecoder()
        let decoded = try! decoder.decode(PreferenceSettingRoot.self, from: data)

        // Sample data is intentionally meant to have nothing to do with VLC.
        // This way, global string searches won't bring up this test as a result unnecessarily.

        let group = PreferenceSetting.Group(title: "First Section", footerText: "First")

        let titleChoices = PreferenceSetting.Choices
            .number([.init(title: "Zero", value: .from(integer: 0)),
                     .init(title: "One", value: .from(integer: 1)),
                     .init(title: "Two", value: .from(integer: 2)),
                     .init(title: "Three", value: .from(integer: 3))],
                    defaultValue: .zero)
        let title = PreferenceSetting.Title(key: "numberOfParkingTickets",
                                            title: "Number of Parking Tickets",
                                            choices: titleChoices)

        let multiChoices = PreferenceSetting.Choices
            .string([.init(title: "Zero", value: "Zero"),
                     .init(title: "One", value: "One"),
                     .init(title: "Two", value: "Two"),
                     .init(title: "Three", value: "Three")],
                    defaultValue: "Zero")
        let multi = PreferenceSetting.MultiValue(key: "numberOfSpeedingTickets",
                                                 title: "Number of Speeding Tickets",
                                                 choices: multiChoices)

        let textField = PreferenceSetting.TextField(key: "name",
                                                    title: "Name",
                                                    defaultValue: "")

        let toggle = PreferenceSetting.Toggle(key: "WashHandsBeforeEating",
                                              title: "Wash Hands Before Eating",
                                              defaultValue: true)

        let custom = PreferenceSetting.Custom.helloWorld(.init(title: "Greetings Earth",
                                                               population: 8_200_000_000))

        let expected: [PreferenceSetting] = [
            .groupSpecifier(group),
            .titleSpecifier(title),
            .multiValueSpecifier(multi),
            .textFieldSpecifier(textField),
            .toggleSwitchSpecifier(toggle),
            .custom(custom)
        ]

        XCTAssertTrue(decoded.specifiers == expected)
    }

    // TODO: create tests for failure cases.

}
