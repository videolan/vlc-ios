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

import CoreMotion
import Foundation

@objc(VLCDeviceMotionDelegate)
protocol DeviceMotionDelegate: NSObjectProtocol {

    func deviceMotionHasAttitude(deviceMotion: DeviceMotion, pitch: Double, yaw: Double)
}

struct EulerAngles {
    var yaw: Double = 0
    var pitch: Double = 0
}

@objc(VLCDeviceMotion)
class DeviceMotion: NSObject {

    @objc weak var delegate: DeviceMotionDelegate? = nil
    @objc var yaw: CGFloat = 0
    @objc var pitch: CGFloat {
        //limiting the axis
        set { _pitch = min(max(newValue, -90), 90) }
        get { return _pitch }
    }
    var _pitch: CGFloat = 0
    private let motion = CMMotionManager()
    private let sqrt2 = 0.5.squareRoot()
    private var lastEulerAngle: EulerAngles? = nil

    private func multQuaternion(q1: CMQuaternion, q2: CMQuaternion) -> CMQuaternion {
        var ret = CMQuaternion()

        ret.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
        ret.x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y
        ret.y = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x
        ret.z = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x - q1.z * q2.w

        return ret
    }

    private func quaternionToEuler(qIn: CMQuaternion) -> EulerAngles {

        // Rotationquaternion of 90°
        let qRot = CMQuaternion(x: -sqrt2 / 2, y: 0, z: 0, w: sqrt2 / 2)

        // Perform the rotation
        let q = multQuaternion(q1:qRot, q2:qIn)

        let squaredNorm = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w
        let test = q.y * q.z - q.w * q.x

        //roll is 0 and we convert to degrees
        var vp = EulerAngles()
        vp.yaw = 2 * atan2(-q.y, q.w) * 180 / Double.pi
        vp.pitch = asin(2 * test / squaredNorm) * 180 / Double.pi

        return vp
    }

    @objc func startDeviceMotion() {
        if motion.isDeviceMotionAvailable {
            motion.gyroUpdateInterval = 1.0 / 60.0 // 60 Hz
            motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) {
                [weak self] (data, error) in
                guard let strongSelf = self, let data = data else {
                    return
                }

                let currentEuler = strongSelf.quaternionToEuler(qIn: data.attitude.quaternion)

                // if we panned we will have a lastEuler value that we need to take as beginning angle
                if let lastEulerAngle = strongSelf.lastEulerAngle {
                    //we get the devicemotion diff between start and currentangle
                    let diffYaw = currentEuler.yaw - lastEulerAngle.yaw
                    let diffPitch = currentEuler.pitch - lastEulerAngle.pitch
                    strongSelf.delegate?.deviceMotionHasAttitude(deviceMotion:strongSelf, pitch:diffPitch, yaw:diffYaw)
                }

                strongSelf.lastEulerAngle = currentEuler
            }
        }
    }

    @objc func stopDeviceMotion() {
        if motion.isDeviceMotionActive {
            lastEulerAngle = nil
            motion.stopDeviceMotionUpdates()
        }
    }
}
