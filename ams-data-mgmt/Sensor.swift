//
//  Sensor.swift
//  ams-data-mgmt
//
//  Created by John Doe on 03/01/2020.
//  Copyright © 2020 John Doe. All rights reserved.
//

import Foundation

class Sensor: NSObject, NSCoding {
    var name: String
    var desc: String
    
    // MARK: Archive paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first;
    static let ArchiveURL = DocumentsDirectory?.appendingPathComponent("sensors")
    
    struct PropertyKey {
        static let name = "name"
        static let desc = "desc"
    }
    
    init?(name: String, desc: String) {
        self.name = name
        self.desc = desc
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(desc, forKey: PropertyKey.desc)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.name) as! String
        let desc = aDecoder.decodeObject(forKey: PropertyKey.desc) as! String
        
        self.init(name: name, desc: desc)
    }
}
