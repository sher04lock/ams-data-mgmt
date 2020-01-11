//
//  ReadingCD+CoreDataProperties.swift
//  ams-data-mgmt
//
//  Created by John Doe on 10/01/2020.
//  Copyright © 2020 John Doe. All rights reserved.
//
//

import Foundation
import CoreData


extension ReadingCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingCD> {
        return NSFetchRequest<ReadingCD>(entityName: "ReadingCD")
    }

    @NSManaged public var timestamp: NSDate?
    @NSManaged public var value: Float
    @NSManaged public var sensor: SensorCD?

}
