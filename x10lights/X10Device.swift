//
//  X10Device.swift
//  x10remote
//
//  Created by Sander Botman on 12/7/15.
//  Copyright © 2015 Botman Inc. All rights reserved.
//

class X10Device {
    var deviceRoom: String
    var deviceCode: String
    var deviceName: String
    var deviceId: String
    
    init(deviceId: String, deviceName: String, deviceCode: String, deviceRoom: String) {
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.deviceCode = deviceCode
        self.deviceRoom = deviceRoom
    }
}
