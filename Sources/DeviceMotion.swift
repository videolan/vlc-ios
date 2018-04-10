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

struct EulerAngles {
    var yaw: Double = 0
    var pitch: Double = 0
    var roll: Double = 0
}

@objc(VLCDeviceMotion)
class DeviceMotion:NSObject {

    let motion = CMMotionManager()
    let sqrt2 = 0.5.squareRoot()
    var lastEulerAngle = EulerAngles()
    var lastQuaternion: CMQuaternion? = nil

    @objc weak var delegate: DeviceMotionDelegate? = nil

    private func multQuaternion(q1: CMQuaternion, q2: CMQuaternion) -> CMQuaternion {
        var ret = CMQuaternion()

        ret.x = q1.x * q2.x - q1.y * q2.y - q1.z * q2.z - q1.w * q2.w
        ret.y = q1.x * q2.y + q1.y * q2.x + q1.z * q2.w - q1.w * q2.z
        ret.z = q1.x * q2.z + q1.z * q2.x - q1.y * q2.w + q1.w * q2.y
        ret.w = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y

        return ret
    }

    private func quaternionToEuler(qIn: CMQuaternion) -> EulerAngles {
        // Change the axes
        var q = CMQuaternion(x:qIn.y, y:qIn.z, z:qIn.x, w:qIn.w)

        // Rotation of 90°
        let qRot = CMQuaternion(x: 0, y: 0, z: -sqrt2 / 2, w: sqrt2 / 2)

        // Perform the rotation
        q = multQuaternion(q1:qRot, q2:q)

        // Now, we can perform the conversion and manage ourself the singularities

        let sqx = q.x * q.x
        let sqy = q.y * q.y
        let sqz = q.z * q.z
        let sqw = q.w * q.w

        let unit = sqx + sqy + sqz + sqw // if normalised is one, otherwise is correction factor
        let test = q.x * q.y + q.z * q.w

        var vp = EulerAngles()

        if (test > 0.499 * unit) {
            // singularity at north pole
            vp.yaw = 2 * atan2(q.x, q.w)
            vp.pitch = Double.pi / 2
            vp.roll = 0
        } else if (test < -0.499 * unit) {
            // singularity at south pole
            vp.yaw = -2 * atan2(q.x, q.w)
            vp.pitch = -Double.pi / 2
            vp.roll = 0
        } else {
            vp.yaw = atan2(2 * q.y * q.w - 2 * q.x * q.z, sqx - sqy - sqz + sqw)
            vp.pitch = asin(2 * test / unit)
            vp.roll = atan2(2 * q.x * q.w - 2 * q.y * q.z, -sqx + sqy - sqz + sqw)
        }

        vp.yaw = -vp.yaw * 180 / Double.pi
        vp.pitch = vp.pitch * 180 / Double.pi
        vp.roll = vp.roll * 180 / Double.pi

        return vp
    }

    @objc func startDeviceMotion() {
        if motion.isDeviceMotionAvailable {
            motion.gyroUpdateInterval = 1.0 / 60.0  // 60 Hz
            motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) {
                [weak self] (data, error) in
                guard let strongSelf = self, let data = data else {
                    return
                }

                var euler = strongSelf.quaternionToEuler(qIn: data.attitude.quaternion)
                if let lastQuaternion = strongSelf.lastQuaternion {
                    let lastEuler = strongSelf.quaternionToEuler(qIn: lastQuaternion)
                    let diffYaw = euler.yaw - lastEuler.yaw
                    let diffPitch = euler.pitch - lastEuler.pitch
                    let diffRoll = euler.roll - lastEuler.roll

                    euler.yaw = strongSelf.lastEulerAngle.yaw + diffYaw
                    euler.pitch = strongSelf.lastEulerAngle.pitch + diffPitch
                    euler.pitch = strongSelf.lastEulerAngle.roll + diffRoll
                }
                strongSelf.delegate?.deviceMotionHasAttitude(deviceMotion:strongSelf, pitch:euler.pitch, yaw:euler.yaw, roll:euler.roll)
            }
        }
    }

    @objc func lastAngle(yaw:Double, pitch:Double, roll:Double) {
        lastEulerAngle.yaw = yaw
        lastEulerAngle.pitch = pitch
        lastEulerAngle.roll = roll
    }

    @objc func stopDeviceMotion() {
        if motion.isDeviceMotionActive {
            lastQuaternion = motion.deviceMotion?.attitude.quaternion
            motion.stopDeviceMotionUpdates()
        }
    }
}
