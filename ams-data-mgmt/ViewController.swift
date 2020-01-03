//
//  ViewController.swift
//  ams-data-mgmt
//
//  Created by John Doe on 03/01/2020.
//  Copyright © 2020 John Doe. All rights reserved.
//

import UIKit

let YEAR_IN_SECONDS = 31556926.0
let NO_OF_READINGS = 10 * 1000

struct SensorResults: CustomStringConvertible {
    var readings: Int
    var avg: Float
    
    var description: String {
        return "avg: \(avg) (\(readings) samples)"
    }
}

struct Results: CustomStringConvertible {
    var largestTimestamp: Date?
    var smallestTimestamp: Date?
    var avgValue: Float?
    var sensorsResults: Dictionary<String, SensorResults>?
    
    var description: String {
        return """
        Largest timestamp: \(String(describing: largestTimestamp!))
        Smallest timestamp: \(String(describing: smallestTimestamp!))
        Avg value: \(String(describing: avgValue!))
        Sensors results: \(sensorsResults as AnyObject)
        """
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var generateArchivingDataBtn: UIButton!
    @IBOutlet weak var startArchivingQueriesBtn: UIButton!
    @IBOutlet weak var archivingGeneratingTime: UITextField!
    @IBOutlet weak var archivingQueryTime: UITextField!
    @IBOutlet weak var archivingResultsTxt: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


    @IBAction func generateArchivingData(_ sender: Any) {
        print("generating archiving");
        
        let startTime = Date();
        
        var sensors: [Sensor] = []
        
        for n in 1...20 {
            let sensor = Sensor(name: String(format: "S%02d", n), desc: String(format: "Sensor number %02d", n))
            sensors.append(sensor!)
        }
        
        var readings: [Reading] = []
        
        let now = Date().timeIntervalSince1970
        print(now)
        let yearBefore = now - YEAR_IN_SECONDS
        print(yearBefore)
        for _ in 1...NO_OF_READINGS {
            let sensor = sensors.randomElement()
            let timestamp = Double.random(in: yearBefore...now)
            
            let reading = Reading(timestamp: Date(timeIntervalSince1970: timestamp), sensor: sensor!.name, value: Float.random(in: 0...100))
            readings.append(reading!)
        }
        
        if let url = Sensor.ArchiveURL {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: sensors, requiringSecureCoding: false)
                try data.write(to: url)
            } catch {
                print("couldn't save sensors data")
            }
        }
        
        if let url = Reading.ArchiveURL {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: readings, requiringSecureCoding: false)
                try data.write(to: url)
            } catch {
                print("couldn't save readings data")
            }
        }
        
        let finishTime = Date();
        
        let elapsedTime = finishTime.timeIntervalSince(startTime);
        archivingGeneratingTime.text = String(elapsedTime);
        
        print("Generating archiving data took: ", elapsedTime)
    }
    
    
    @IBAction func startArchivingTest(_ sender: Any) {
        print("reading archiving data")
        let startTime = Date();
        var sensors: [Sensor] = []
        var readings: [Reading] = []
        
        var results = Results();
        
//
        do {
            sensors = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(Data(contentsOf: Sensor.ArchiveURL!)) as! [Sensor];

        } catch {
            print("couldn't unarchive sensors data");
        }

        do {
            readings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(Data(contentsOf: Reading.ArchiveURL!)) as! [Reading];

        } catch {
            print("couldn't unarchive readings data");
        }
        
        // 1. largest/smallest timestamp
        results.largestTimestamp = readings.max(by: {(a, b) -> Bool in return a.timestamp < b.timestamp})!.timestamp
        results.smallestTimestamp = readings.min(by: {(a, b) -> Bool in return a.timestamp < b.timestamp})!.timestamp
        
        // 2. avg reading
        results.avgValue = Float(readings.reduce(0, {$0 + $1.value})) / Float(readings.count)
        // 3. avg readings per sensor
        
        var sensorResults: Dictionary<String, SensorResults> = [:];
        
        let groupedReadings = Dictionary(grouping: readings, by: {$0.sensor})
        
        for reading in groupedReadings {
            let avg = Float(reading.value.reduce(0, {$0 + $1.value})) / Float(reading.value.count);
            sensorResults[reading.key] = SensorResults(readings: reading.value.count, avg: avg)
        }
        
        results.sensorsResults = sensorResults;
        
        let finishTime = Date();
        
        let elapsedTime = finishTime.timeIntervalSince(startTime);
        
        archivingResultsTxt.text = String(describing: results)
        
        print("Unarchiving data took: ", elapsedTime)
        print(sensors.count)
        print(readings.count)
        
        archivingQueryTime.text = String(elapsedTime)
    }
}

