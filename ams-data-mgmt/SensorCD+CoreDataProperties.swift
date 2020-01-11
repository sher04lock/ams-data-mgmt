//
//  SensorCD+CoreDataProperties.swift
//  ams-data-mgmt
//
//  Created by John Doe on 10/01/2020.
//  Copyright © 2020 John Doe. All rights reserved.
//
//

import Foundation
import CoreData


extension SensorCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SensorCD> {
        return NSFetchRequest<SensorCD>(entityName: "SensorCD")
    }

    @NSManaged public var name: String?
    @NSManaged public var desc: String?

}
