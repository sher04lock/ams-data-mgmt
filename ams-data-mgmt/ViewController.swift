//
//  ViewController.swift
//  ams-data-mgmt
//
//  Created by John Doe on 03/01/2020.
//  Copyright © 2020 John Doe. All rights reserved.
//

import UIKit

let YEAR_IN_SECONDS = 31556926.0
let NO_OF_READINGS = 50 * 1000

var sqlResults = Results();

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
    
    
    @IBOutlet weak var generateSQLLiteDataBtn: UIButton!
    @IBOutlet weak var startSQLLiteQueriesBtn: UIButton!
    @IBOutlet weak var sqliteGeneratingTime: UITextField!
    @IBOutlet weak var sqliteQueryTime: UITextField!
    
    @IBOutlet weak var resultsTextView: UITextView!
    
    @IBOutlet weak var totalSamplesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.totalSamplesLabel.text = "Total no. of readings: \(NO_OF_READINGS)"
        // Do any additional setup after loading the view, typically from a nib.
    }

    func setButtonsState(isEnabled: Bool) {
        let buttons = [
            generateArchivingDataBtn,
            startArchivingQueriesBtn,
            generateSQLLiteDataBtn,
            startArchivingQueriesBtn
        ]
        
        buttons.forEach({
            $0?.isEnabled = isEnabled
            $0?.setTitleColor(UIColor.gray, for: .disabled)
        })
    }

    func generateData() -> ([Sensor], [Reading]) {
        var sensors: [Sensor] = []
        
        for n in 1...20 {
            let sensor = Sensor(name: String(format: "S%02d", n), desc: String(format: "Sensor number %02d", n))
            sensors.append(sensor!)
        }
        
        var readings: [Reading] = []
        
        let now = Date().timeIntervalSince1970
        
        let yearBefore = now - YEAR_IN_SECONDS
        
        for _ in 1...NO_OF_READINGS {
            let sensor = sensors.randomElement()
            let timestamp = Double.random(in: yearBefore...now)
            
            let reading = Reading(timestamp: Date(timeIntervalSince1970: timestamp), sensor: sensor!.name, value: Float.random(in: 0...100))
            readings.append(reading!)
        }
        
        return (sensors, readings)
    }
    
    @IBAction func generateArchivingData(_ sender: Any) {
        setButtonsState(isEnabled: false)
        
        print("generating archiving");
        
        let startTime = Date();
        
        let data = generateData()
        
        let sensors = data.0
        let readings = data.1
        
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
        setButtonsState(isEnabled: true)
    }
    
    
    @IBAction func startArchivingTest(_ sender: Any) {
        setButtonsState(isEnabled: false)
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
        
        resultsTextView.text = String(describing: results)
        
        print("Unarchiving data took: ", elapsedTime)
        print(sensors.count)
        print(readings.count)
        
        archivingQueryTime.text = String(elapsedTime)
        setButtonsState(isEnabled: true)
    }
    
    @IBAction func generateSqliteData(_ sender: Any) {
        setButtonsState(isEnabled: false)
        print("generating sqlite3 data")
        let startTime = Date();
        
        let data = generateData()
        let sensors = data.0
        let readings = data.1
        
        let db = openDb();
        
        if db != nil {
            let dropSQL = "DROP TABLE IF EXISTS sensors; DROP TABLE IF EXISTS readings;"
            sqlite3_exec(db, dropSQL, nil, nil, nil)
            
            print ("dropped tables")
            
            let createSQL = "CREATE TABLE sensors (name VARCHAR(3) PRIMARY KEY, desc VARCHAR(20)); CREATE TABLE readings (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp NUMERIC, value REAL, sensor VARCHAR(3), FOREIGN KEY(sensor) REFERENCES sensors(name))"
            sqlite3_exec(db, createSQL, nil, nil, nil)
            
            print("created tables")
            
            insertSqliteData(sensors: sensors, readings: readings, db: db)
        }
        
        let finishTime = Date();
        
        let elapsedTime = finishTime.timeIntervalSince(startTime);
        
        sqliteGeneratingTime.text = String(elapsedTime)
        setButtonsState(isEnabled: true)
    }
    
    func openDb() -> OpaquePointer? {
        var db: OpaquePointer? = nil
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true).first!
        let dbFilePath = NSURL(fileURLWithPath: docDir).appendingPathComponent("demo.db")?.path
        
        if sqlite3_open(dbFilePath, &db) == SQLITE_OK {
         return db
        } else {
            print("couldn't connect to db file")
            return nil
        }
    }
    
    func insertSqliteData(sensors: [Sensor], readings: [Reading], db: OpaquePointer?) {
        var insertSensorsStatement: OpaquePointer? = nil
        var insertReadingsStatement: OpaquePointer? = nil
        let insertSensorStatementString = "INSERT INTO sensors (name, desc) values (?, ?);"
        let insertReadingStatementString = "INSERT INTO readings (timestamp, value, sensor) values (?, ?, ?);"
        
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil);
        
        if sqlite3_prepare_v2(db, insertSensorStatementString, -1, &insertSensorsStatement, nil) == SQLITE_OK {
            for sensor in sensors {
                sqlite3_bind_text(insertSensorsStatement, 1, sensor.name, -1, nil)
                sqlite3_bind_text(insertSensorsStatement, 2, sensor.desc, -1, nil)
                
                if sqlite3_step(insertSensorsStatement) == SQLITE_DONE {
                } else {
                    print ("couldn't insert sensor row")
                }
                
                sqlite3_reset(insertSensorsStatement)
            }
            
            sqlite3_finalize(insertSensorsStatement)
//            sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, nil)
        }
        
        
        print ("inserted sensors data")
//        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil);
        if sqlite3_prepare_v2(db, insertReadingStatementString, -1, &insertReadingsStatement, nil) == SQLITE_OK {
            for reading in readings {
                sqlite3_bind_int(insertReadingsStatement, 1, Int32(reading.timestamp.timeIntervalSince1970))
                sqlite3_bind_double(insertReadingsStatement, 2, Double(reading.value))
                sqlite3_bind_text(insertReadingsStatement, 3, reading.sensor, -1, nil)
                
                if sqlite3_step(insertReadingsStatement) == SQLITE_DONE {
                } else {
                    print ("couldn't insert reading row")
                }
                
                sqlite3_reset(insertReadingsStatement)
            }
            
            sqlite3_finalize(insertReadingsStatement)
            sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, nil);
        }
        
        print ("inserted readings data")
    }
    
    @IBAction func startSqliteQueryTest(_ sender: Any) {
        
        setButtonsState(isEnabled: false)
        print("generating sqlite3 data")
        let startTime = Date();
     
        let db = openDb();
        
        sqlResults.sensorsResults = [:]
        
        
        if db != nil {
            let selectSQL = "SELECT max(timestamp) as max, min(timestamp) as min, avg(value) as avg from readings;"
            let selectSensorsSQL = "SELECT sensor, count(*) as readings, avg(value) as avg from readings group by sensor;"
            
            sqlite3_exec(db, selectSQL, {_, columnCount, values, columns in
                let maxTimestamp = String(cString: values![0]!)
                let minTimestamp = String(cString: values![1]!)
                let avg = String(cString: values![2]!)
                
                sqlResults.largestTimestamp = Date(timeIntervalSince1970: Double(maxTimestamp)!)
                sqlResults.smallestTimestamp = Date(timeIntervalSince1970: Double(minTimestamp)!)
                sqlResults.avgValue = Float(avg)
   
                return 0
            }, nil, nil)
            
            
            sqlite3_exec(db, selectSensorsSQL, {_, columnCount, values, columns in
                let sensor = String(cString: values![0]!)
                let readings = String(cString: values![1]!)
                let avg = String(cString: values![2]!)

                sqlResults.sensorsResults![sensor] = SensorResults(readings: Int(readings)!, avg: Float(avg)!)
                return 0
            }, nil, nil)
        }
        
        
        let finishTime = Date();
        
        let elapsedTime = finishTime.timeIntervalSince(startTime);
        resultsTextView.text = String(describing: sqlResults)
        sqliteQueryTime.text = String(elapsedTime)
        setButtonsState(isEnabled: true)
        
    }
}

