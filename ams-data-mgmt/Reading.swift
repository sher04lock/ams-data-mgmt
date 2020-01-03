//
//  Reading.swift
//  ams-data-mgmt
//
//  Created by John Doe on 03/01/2020.
//  Copyright © 2020 John Doe. All rights reserved.
//

import Foundation

class Reading: NSObject, NSCoding {
    var timestamp: Date
    var sensor: String
    var value: Float

    // MARK: Archive paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first;
    static let ArchiveURL = DocumentsDirectory?.appendingPathComponent("readings")
    
    struct PropertyKey {
        static let timestamp = "timestamp"
        static let sensor = "sensor"
        static let value = "value"
    }
    
    init?(timestamp: Date, sensor: String, value: Float) {
        self.timestamp = timestamp
        self.sensor = sensor
        self.value = value
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(timestamp, forKey: PropertyKey.timestamp)
        aCoder.encode(sensor, forKey: PropertyKey.sensor)
        aCoder.encode(value, forKey: PropertyKey.value)

    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let timestamp = aDecoder.decodeObject(forKey: PropertyKey.timestamp) as! Date
        let sensor = aDecoder.decodeObject(forKey: PropertyKey.sensor) as! String
        let value = aDecoder.decodeFloat(forKey: PropertyKey.value)

        self.init(timestamp: timestamp, sensor: sensor, value: value)
    }
}
