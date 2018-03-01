/*****************************************************************************
 * DeviceMotion.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import CoreMotion

@objc(VLCDeviceMotionDelegate)
protocol DeviceMotionDelegate:NSObjectProtocol {

    func deviceMotionHasAttitude(deviceMotion:DeviceMotion, pitch:Double, yaw:Double, roll:Double)

}

@objc(VLCDeviceMotion)
class DeviceMotion:NSObject {

    let motion = CMMotionManager()
    var referenceAttitude:CMAttitude? = nil
    @objc weak var delegate: DeviceMotionDelegate? = nil

    @objc func startDeviceMotion() {

        if motion.isDeviceMotionAvailable {
            motion.gyroUpdateInterval = 1.0 / 60.0  // 60 Hz
            motion.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: .main) {
                [weak self] (data, error) in
                guard let strongSelf = self, let data = data else {
                    return
                }

                //We're using the initial angle of phone as 0.0.0 reference for all axis
                //we need to create a copy here, otherwise we just have a reference which is being changed in the next line
                if strongSelf.referenceAttitude == nil {
                    strongSelf.referenceAttitude = data.attitude.copy() as? CMAttitude
                }
                // this line basically substracts the reference attitude so that we have yaw, pitch and roll changes in
                // relation to the very first angle
                data.attitude.multiply(byInverseOf: strongSelf.referenceAttitude!)

                let pitch = -(180/Double.pi)*data.attitude.pitch // -90; 90
                let yaw = -(180/Double.pi)*data.attitude.yaw // -180; 180
                let roll = -(180/Double.pi)*data.attitude.roll// -180; 180

                //print(pitch,yaw,roll)
                strongSelf.delegate?.deviceMotionHasAttitude(deviceMotion:strongSelf, pitch:pitch, yaw:yaw, roll:roll)
            }
        }
    }

    @objc func stopDeviceMotion() {
        if motion.isDeviceMotionActive {
            motion.stopDeviceMotionUpdates()
            self.referenceAttitude = nil
        }
    }
}
