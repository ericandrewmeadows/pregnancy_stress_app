//
//  SensorComms.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/23/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import Foundation
import UIKit
import SwiftCSV

infix operator ** { associativity left precedence 170 }

func ** (num: CGFloat, power: CGFloat) -> CGFloat{
    return pow(num, power)
}

class sensorComms: NSObject, MSBClientManagerDelegate {

    // User defaults
    let defaults = NSUserDefaults.standardUserDefaults()

    // Notifications Function
    let app_notifications = notifications()

    // View parameters
    var window: UIWindow!
    weak var mainView: ViewController! = ViewController()
    weak var stressMeter: StressMeter! = StressMeter()
    
    // Array variables
    let measurementMemory = 30
    var measurementArray:  [CGFloat] = [CGFloat](count: 30*4, repeatedValue: 0.0)
    var inputArray:  [CGFloat] = [CGFloat](count: 30*4, repeatedValue: 0.0)
    var gsr_history:  [CGFloat] = []
    var hr_history:  [CGFloat] = []
    var gsrDiffRatio_history:  [CGFloat] = []
    var hrDiffRatio_history:  [CGFloat] = []
    
    // Stress variables
    var stressIndex:  CGFloat = 0.0
    var stressSlope_limit:  CGFloat = 2.0
    var timeBetweenUpdates:  Double = 0.1 // Time between NN runs
    var timeBetweenStressUpdates:  Double = 60.0 // Time between updates of self.cumulativeStressPath file
    var timeBetween_weekStressFileUpdates: Double = 15 * 60.0 // Allows for all time zones
    var lastUpdateTime = NSDate().timeIntervalSince1970
    var lastCumulativeUpdateTime = NSDate().timeIntervalSince1970
    var lastCumulativeUpdateTime_major = NSDate().timeIntervalSince1970
    var lastWeeklyFileUpdate = NSDate().timeIntervalSince1970
//    var writeToStressFile_lastTime = NSDate().timeIntervalSince1970
//    var timeBetween_writesTo_stressFile:  Double = 60.0 // Time between writes to cumulative stress file
    var cumulativeStressTime:  CGFloat = 0.0
    var cumulativeStressTime_interim:  CGFloat = 0.0
    var cumulativeStressPeriod:  CGFloat = 24*60*60 // 1-Day running stress time
    var calmleeScore:  CGFloat = 100.0 //  Initialization
    var dailyCalmleeScore:  CGFloat = 0.0 //  Test
    var measurementsRecorded:  CGFloat = 0.0
    
    // Cumulative Stress variables
    var cStress_time:  [CGFloat] = []
    var cStress_stress_t:  [CGFloat] = []
    var cumulativeStressTime_inPeriod:  CGFloat = 0.0
    var cumulativeStressTime_weekly:  CGFloat = 0.0
    var cumulativeStressTimeToKeep = CGFloat(2*24*60*60)
    var hourlyStressFileTimeToKeep = CGFloat(10*24*60)
    
    // Plotting variables
    var calmleeScores_time:  [CGFloat] = []
    var calmleeScores_tmp_sum:  CGFloat = 0.0
    var calmleeScores_tmp_min:  CGFloat = 100.0
    var calmleeScores_tmp_max:  CGFloat = 0.0
    var calmleeScores_tmp_cnt:  CGFloat = 0.0
    var calmleeScores_avg:  [CGFloat] = []
    var calmleeScores_min:  [CGFloat] = []
    var calmleeScores_max:  [CGFloat] = []
    
    // Sensor variables
    var firstTime = 1
    weak var client: MSBClient?
    var lastHR:  CGFloat = 0
    var lastGSR:  CGFloat = 0
    var currentHR:  CGFloat = 0
    var currentGSR:  CGFloat = 0
    var currentGSR_DR:  CGFloat = 0
    var currentHR_DR:  CGFloat = 0
    
    // Logging variables
    var headerWritten = 0
    var stressHeaderWritten = 0
    var quitTesting = 0
    var destinationPath: String! = NSTemporaryDirectory() + "tempSensorDump.txt"
    var cumulativeStressPath: String! = NSTemporaryDirectory() + "cumulativeStress.txt"
    var camleeScoreHistoryPath: String! = NSTemporaryDirectory() + "calmleeScoreHistory.txt"
    var sentSuccessfully = false
    let stressCSV_class = stressCSV()
    let calmleeScoreCSV_class = calmleeScoreCSV()
    
    // Notification variables
    var extremeStress_notified = false
    var calm_min = 50
    var calm_extreme = 20 // If Calmlee score is under this value, it will send a notification
    var last_extremeStress: Double = 0.0
    var last_longDurationStress = NSDate().timeIntervalSince1970
    var currentlyStresed = false
    var stressStart = NSDate().timeIntervalSince1970
    var longDurationStress_notificationCount = 0
    
    // Timer elements
    var timer = NSTimer()
    
    // Microsoft Band Tile
    var tile: MSBTile = MSBTile()
    var tileExists = true
    var tileId:  NSUUID = NSUUID()
    
    // Custom Tiles
    func createTile() {
        
        var tileExists = false
        // Create a new tile
        // create the small and tile icons from UIImage
        // small icons are 24x24 pixels
        let smallImage = UIImage(named: "BandIcon_24x24")
        var smallIcon = try! MSBIcon.init(UIImage: smallImage)
        // tile icons are 48x48 pixels for Microsoft Band 2.
        let largeImage = UIImage(named: "BandIcon_48x48")
        var tileIcon  = try! MSBIcon.init(UIImage: largeImage)
        
        // Sample code uses random tileId, but you should persist the value
        // for your application's tileId.
        let tileId = NSUUID.init()
//        self.defaults.setValue(tileId, forKey: "tileInfo")
        if let prevTileId = (self.defaults.stringForKey("tileInfo")) {
            // Fetch tile list
            self.client?.tileManager.tilesWithCompletionHandler({
                (tiles, error:  NSError!) in
                for tile in tiles {
                    print((tile as! MSBTile).tileId.UUIDString)
                    if ((tile as! MSBTile).tileId.UUIDString == prevTileId) {
                        self.tileId = (tile as! MSBTile).tileId
                        tileExists = true
                        return
                    }
                }
                if !tileExists {
                    self.defaults.setValue(tileId.UUIDString, forKey: "tileInfo")
                    print("Not on Band")
                    
                    // create a new MSBTile
                    self.tile = try! MSBTile.init(id: tileId, name: "calmlee", tileIcon: tileIcon, smallIcon: smallIcon)
                    
                    // enable badging (the count of unread messages)
                    self.tile.badgingEnabled = true
                    
                    // Determine if there is free tile space
                    self.client?.tileManager.remainingTileCapacityWithCompletionHandler({
                        (remainingCapacity, error: NSError!) in
                        print(remainingCapacity)
                        if (remainingCapacity == 0) {
                            return
                        }
                    })
                    
                    // add created tile to the Band.
                    self.client?.tileManager.addTile(self.tile, completionHandler: { (error: NSError!) in
                        if error != nil {
                            self.tileExists = false
                            print(error)
                        }
                    })
                }
            })
        }
    }
    
    func removeTile() {
        self.client?.tileManager.removeTile(self.tile, completionHandler: { (error: NSError!) in
            if error != nil {
                print(error)
            }
        })
    }
    
//        // Remove tile from band
//        // get the current set of tiles
//        __weak typeof(self) weakSelf = self;
//        [self.client.tileManager tilesWithCompletionHandler:^(NSArray *tiles,
//            NSError *error){
//            for (MSBTile *aTile in tiles)
//            {
//            // remove this tile, can be async
//            [weakSelf.client.tileManager removeTile:aTile
//            completionHandler:^(NSError *error){
//            if (error) {
//            // failed to remove this tile
//            }
//            }];
//            }
//            }];
//    }
    
    // Norification Functions
    /*
    Log identifier 50
        - 0: Recorded as stressed, but user not stressed
        - 1: Recorded as not Stressed, but user stressed
     */
    @IBAction func reportIncorrectStress(sender:  AnyObject?) {
        let seconds = NSDate().timeIntervalSince1970
        let milliseconds = seconds * 1000.0
        if self.stressIndex > CGFloat(100 - self.calm_min) {
            self.logToFile(String(format: "50, %0.4f, 0\n",milliseconds))
            print("incorrectly reported as stressed")
        }
        else {
            self.logToFile(String(format: "50, %0.4f, 1\n",milliseconds))
            print("incorrectly reported as not stressed")
        }
    }
    
    func sendBuzzNotification() {
        // send a vibration request of type alert alarm to the Band
        self.client?.notificationManager.vibrateWithType(MSBNotificationVibrationType.Alarm, completionHandler: { (error) in
            print("buzzed")
        })
//        [self.client.notificationManager
//            vibrateWithType:MSBNotificationVibrationTypeAlarm
//            completionHandler:^(NSError *error)
//            {
//            if (error){
//            // handle error
//            }
//            }];
        
//        [self.client.notificationManager
//            sendMessageWithTileID:tileId
//            title:@"Message title"
//        body:@"Message body"
//        timeStamp:[NSDate date]
//        flags:MSBNotificationMessageFlagsShowDialog
//        completionHandler:^(NSError *error)
//        {
//            if (error){
//                // handle error
//            }
//        }];
    }
    
    func scheduleLocalNotification() {
        // Create reminder by setting a local notification
        let localNotification = UILocalNotification() // Creating an instance of the notification.
        localNotification.alertTitle = "Extreme Stress"
        localNotification.alertBody = "Calmlee detected an unusually high level of stress."
        localNotification.alertAction = "calm down"
        localNotification.fireDate = NSDate()//.dateByAddingTimeInterval(0) // 5 minutes(60 sec * 5) from now
        localNotification.timeZone = NSTimeZone.defaultTimeZone()
        localNotification.soundName = UILocalNotificationDefaultSoundName // Use the default notification tone/ specify a file in the application bundle
        localNotification.applicationIconBadgeNumber = 1 // Badge number to set on the application Icon.
        localNotification.category = "extremeStress" // Category to use the specified actions
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification) // Scheduling the notification.
    }
    
    // Historical Calmlee Score functions
    func readCalmleeScoreFile() {
        print("Reading CalmleeScore File")
        if let delete: Bool? = self.defaults.integerForKey("deleteData_rev") == 3 {
            print("keyExists")
        }
        else {
            self.defaults.setInteger(2, forKey: "deleteData_rev")
        }
        if (NSFileManager.defaultManager().fileExistsAtPath(self.camleeScoreHistoryPath)) {
            if self.defaults.integerForKey("deleteData_rev") == 3 {
                let fileContent = try? NSString(contentsOfFile: self.camleeScoreHistoryPath,
                                                encoding: NSUTF8StringEncoding)
                let attr:NSDictionary? = try! NSFileManager.defaultManager().attributesOfItemAtPath(self.camleeScoreHistoryPath)
                if let _attr = attr {
                    print("CalmleeScoreHistory FileSize: \(_attr.fileSize())")
                }
                
                let fileData = fileContent?.componentsSeparatedByString("\n")
                let time = NSDate().timeIntervalSince1970
                print(fileData![0])
                var loggingString = ""
                if (fileData![0] != "time,average,min,max") {
                    loggingString = "time,average,min,max\n" + String(fileContent)
                    let os:  NSOutputStream = NSOutputStream(toFileAtPath: self.camleeScoreHistoryPath,
                                                             append: false)!
                    os.open()
                    os.write(loggingString, maxLength: loggingString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                    os.close()
                }
                else {
                    loggingString = fileContent! as String
                }
                // My loading method
//                (self.calmleeScores_time,self.calmleeScores_avg,self.calmleeScores_min,self.calmleeScores_max) = self.calmleeScoreCSV_class.convertCSV(loggingString)
                let csv = try? CSV.init(name: self.camleeScoreHistoryPath)
                self.calmleeScores_time = (csv!.columns["time"]!).map {
                    CGFloat(($0 as NSString).doubleValue)
                }
                self.calmleeScores_avg = (csv!.columns["average"]!).map {
                    CGFloat(($0 as NSString).doubleValue)
                }
                self.calmleeScores_min = (csv!.columns["min"]!).map {
                    CGFloat(($0 as NSString).doubleValue)
                }
                self.calmleeScores_max = (csv!.columns["max"]!).map {
                    CGFloat(($0 as NSString).doubleValue)
                }
                
                if (Int(24*60*60 / timeBetweenStressUpdates) < (self.cStress_time.count-1)) {
                    print(self.cStress_time.count)
                    self.cStress_time = Array(self.cStress_time[Int(24*60*60 / timeBetweenStressUpdates)...self.cStress_time.count-1])
                    self.cStress_stress_t = Array(self.cStress_stress_t[Int(24*60*60 / timeBetweenStressUpdates)...self.cStress_stress_t.count-1])
                    print(NSDate().timeIntervalSince1970 - time)
                    print(self.cStress_time.count)
                    self.writeStressFile(0, initialize: true)
                }

                
                print("Section 1")
                print(NSDate().timeIntervalSince1970 - time)
            }
            else {
                self.defaults.setInteger(3, forKey: "deleteData_rev")
                let fileManager = NSFileManager.defaultManager()
                do {
                    try! fileManager.removeItemAtPath(self.camleeScoreHistoryPath)
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
                self.readCalmleeScoreFile()
            }
            
        }
        else {
            self.writeCalmleeScoreFile(true, closing: false, time: 0, avg: 0, min: 0, max: 0)
            print("File didn't exist...creating...")
        }
    }

    // Cumulative Stress functions
    func readStressFile() {
        print("Reading Stress File")
        if let delete: Bool? = self.defaults.integerForKey("deleteStressFile") == 1 {
            print("keyExists")
        }
        else {
            self.defaults.setInteger(0, forKey: "deleteStressFile")
        }
        if (NSFileManager.defaultManager().fileExistsAtPath(self.cumulativeStressPath)) {
            if self.defaults.integerForKey("deleteStressFile") == 1 {
                let fileContent = try? NSString(contentsOfFile: self.cumulativeStressPath,
                                                encoding: NSUTF8StringEncoding)
                let attr:NSDictionary? = try! NSFileManager.defaultManager().attributesOfItemAtPath(self.cumulativeStressPath)
                if let _attr = attr {
                    print("Stress FileSize: \(_attr.fileSize())")
                }
                let fileData = fileContent?.componentsSeparatedByString("\n")
                let time = NSDate().timeIntervalSince1970
                print(fileData![0])
                var loggingString = ""
                if (fileData![0] != "time,stressTime") {
                    loggingString = "time,stressTime\n" + String(fileContent)
                    let os:  NSOutputStream = NSOutputStream(toFileAtPath: self.cumulativeStressPath,
                                                             append: false)!
                    os.open()
                    os.write(loggingString, maxLength: loggingString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                    os.close()
                }
                else {
                    loggingString = fileContent! as String
                }
                // My loading method
//                (self.cStress_time,self.cStress_stress_t) = self.stressCSV_class.convertCSV(loggingString)
                // SwiftCSV method
//                time = NSDate().timeIntervalSince1970
                let csv = try? CSV.init(name: self.cumulativeStressPath)
                self.cStress_time = (csv!.columns["time"]!).map {
                    CGFloat(($0 as NSString).doubleValue)
                }

                self.cStress_stress_t = (csv!.columns["stressTime"]!).map {
                    CGFloat(($0 as NSString).doubleValue)
                }
                if (Int(24*60*60 / timeBetweenStressUpdates) < (self.cStress_time.count-1)) {
                    print(self.cStress_time.count)
                    self.cStress_time = Array(self.cStress_time[Int(24*60*60 / timeBetweenStressUpdates)...self.cStress_time.count-1])
                    self.cStress_stress_t = Array(self.cStress_stress_t[Int(24*60*60 / timeBetweenStressUpdates)...self.cStress_stress_t.count-1])
                    print(NSDate().timeIntervalSince1970 - time)
                    print(self.cStress_time.count)
                    self.writeStressFile(0, initialize: true)
                }
                
                print("Section 1")
                print(NSDate().timeIntervalSince1970 - time)
            }
            else {
                self.defaults.setInteger(1, forKey: "deleteStressFile")
                let fileManager = NSFileManager.defaultManager()
                do {
                    try! fileManager.removeItemAtPath(self.cumulativeStressPath)
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
                print("Section 2")
            }
        
        }
        else {
            self.writeStressFile(0,initialize: true)
            print("Section 3")
        }
    }
    
    func dot_cumulativeStress(a: [CGFloat], b_val: CGFloat, c: [CGFloat]) -> CGFloat {
        let b = [CGFloat](count: a.count, repeatedValue: b_val)
        let stress_valid = zip(a, b).map{ (CGFloat($0 >= $1)) }
        return zip(stress_valid,c).map{ (CGFloat($0*$1)) }.reduce(0, combine: +)
    }
    
    func dot_stressValuesToWrite_uponClose(timeStamps: [CGFloat], minTime: CGFloat, arrayVariable: [CGFloat]) -> [CGFloat] {
        let mintimeArray = [CGFloat](count: timeStamps.count, repeatedValue: minTime)
        let timeStamps_valid = zip(timeStamps,mintimeArray).map{ ($0 >= $1) }
        return zip(timeStamps_valid,arrayVariable).filter { (time,val) in time == true }.map{ (time,val) in return val   }
    }
    
    func writeCalmleeScoreFile(initialize: Bool, closing: Bool, time: CGFloat, avg: CGFloat, min: CGFloat, max: CGFloat) {
        var loggingString:  String
        let os:  NSOutputStream = NSOutputStream(toFileAtPath: self.camleeScoreHistoryPath, append: initialize == false)!
        os.open()
        if (initialize == true) {
            loggingString = "time,average,min,max\n"
        }
        else if (closing == true) {
            loggingString = "time,average,min,max\n"
            self.calmleeScores_avg = dot_stressValuesToWrite_uponClose(self.calmleeScores_time,
                                                                       minTime: time - self.cumulativeStressTimeToKeep,
                                                                       arrayVariable: self.calmleeScores_avg)
            self.calmleeScores_max = dot_stressValuesToWrite_uponClose(self.calmleeScores_time,
                                                                       minTime: time - self.cumulativeStressTimeToKeep,
                                                                       arrayVariable: self.calmleeScores_max)
            self.calmleeScores_min = dot_stressValuesToWrite_uponClose(self.calmleeScores_time,
                                                                       minTime: time - self.cumulativeStressTimeToKeep,
                                                                       arrayVariable: self.calmleeScores_min)
            self.calmleeScores_time = dot_stressValuesToWrite_uponClose(self.calmleeScores_time,
                                                                        minTime: time - self.cumulativeStressTimeToKeep,
                                                                        arrayVariable: self.cStress_time)
            
            if self.calmleeScores_time.count != 0 {
                for index in 0...(self.calmleeScores_time.count - 1) {
                    loggingString += String(format: "%0.20f,%0.2f,%0.2f,%0.2f\n",
                                            self.calmleeScores_time[index],
                                            self.calmleeScores_avg[index],
                                            self.calmleeScores_min[index],
                                            self.calmleeScores_max[index])
                }
            }
        }
        else if (time != 0) {
            loggingString = "\(time),\(avg),\(min),\(max)\n"
        }
        else {
            os.close()
            return
        }
        os.write(loggingString, maxLength: loggingString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        os.close()
    }
    
    func writeStressFile(closing: Int, initialize: Bool) {
        let time = NSDate().timeIntervalSince1970
        print("writing")
        var loggingString:  String
        let os:  NSOutputStream = NSOutputStream(toFileAtPath: self.cumulativeStressPath,
                                                 append: initialize == false)!
        os.open()
        if (initialize == true) {
            loggingString = "time,stressTime\n"
        }
        else if (closing == 1) {
            loggingString = "time,stressTime\n"
            self.cStress_stress_t = dot_stressValuesToWrite_uponClose(self.cStress_time,
                                                                      minTime: CGFloat(time) - self.cumulativeStressTimeToKeep,
                                                                      arrayVariable: self.cStress_stress_t)
            self.cStress_time = dot_stressValuesToWrite_uponClose(self.cStress_time,
                                                                  minTime: CGFloat(time) - self.cumulativeStressTimeToKeep,
                                                                  arrayVariable: self.cStress_time)
            if self.cStress_stress_t.count != 0 {
                for index in 0...(self.cStress_stress_t.count - 1) {
                    loggingString += String(format: "%0.20f,%0.2f\n",
                                            self.cStress_time[index],
                                            self.cStress_stress_t[index])
                }
            }
        }
        else {
            loggingString = String(format: "%0.20f,%0.2f\n",
                                   self.lastCumulativeUpdateTime_major,
                                   self.cumulativeStressTime_inPeriod)
        }
        os.write(loggingString, maxLength: loggingString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        os.close()
    }
    
    func start() {
        MSBClientManager.sharedManager().delegate = self
        if let client = MSBClientManager.sharedManager().attachedClients().first as? MSBClient {
            self.client = client
            MSBClientManager.sharedManager().connectClient(self.client)
            // Attempting to connect
        } else {
            // change meter icon to a frown
        }
    }
    
    /*
     
     Number Sensor                      Number Format   Units
     ---    ----------------------      -------------   -----
     0*     Accelerometer
     1*     Altimeter
     2      Ambient Light
     3      Air Temperature
     4      Barometric Pressure
     5*     Calories Burned
     6      Contact of Band (Real-time monitor:  GSR == 340330)
     7*     Distance
     8      Galvanic Skin Resistance
     9*     Gyroscope
     10     Heart Rate
     11     Motion Type                 enum
     12*    Pedometer
     13*    Resting Rate Interval
     14     Skin Temperature
     15     Ultraviolet Light
     16     Heart Rate Type
     17     Band speed                  Float           ms/m
     18     Band pace                   Float           cm/s
     50     False stress reading        0 - F. Positive, 1 - F. Negative
     
     */
    
    /* enum:MOTION TYPE
     Value  Motion Type
     -----  -----------
     0      Unknown
     1      Idle
     2      Walking
     3      Jogging
     4      Running
     */
    
    func startTesting() { //I NEED TO RESET ARRAYS here!
        let delay: NSTimeInterval = NSTimeInterval(2) // Time until connection retry
        if let client = self.client {
            if client.isDeviceConnected == false {
                mainView?.calmleeQuip!.text = "I'm connecting to your sensor..."
                self.timer = NSTimer.scheduledTimerWithTimeInterval(delay,
                                                                    target: self,
                                                                    selector: #selector(self.startTesting),
                                                                    userInfo: nil,
                                                                    repeats: false)
                self.firstTime = 1
                return
            }
            
            
            if self.firstTime == 1 {
                mainView?.calmleeQuip!.text = "Nice to see you again!  I'm just getting your baseline."
                self.firstTime = 0
            }
            
            // Get User Consent for Heart Rate
            if client.sensorManager.heartRateUserConsent() == MSBUserConsent.Granted {
                // Heart Rate is being captured
                self.gatherHeartRate(client)
            } else {
                mainView?.calmleeQuip!.text = "I'm going to need to access your heart rate..."
                client.sensorManager.requestHRUserConsentWithCompletion( { (userConsent: Bool, error: NSError!) -> Void in
                    if userConsent {
                        self.gatherHeartRate(client)
                    } else {
                        self.mainView?.calmleeQuip!.text = "I need you to select \"Yes\" when the prompt comes up the next time"
                        self.timer = NSTimer.scheduledTimerWithTimeInterval(delay,
                            target: self,
                            selector: #selector(self.startTesting),
                            userInfo: nil,
                            repeats: false)
                    }
                })
            }
            
            // Launch tile onto Band
            self.createTile()
            
            // Fetch Band Contact readings
            try! client.sensorManager.stopBandContactUpdatesErrorRef()
            try! client.sensorManager.startBandContactUpdatesToQueue(nil, withHandler: {
                (bandContactData:  MSBSensorBandContactData!, error:  NSError!) in
                print(bandContactData.wornState)
                switch bandContactData.wornState {
                case MSBSensorBandContactState.NotWorn:
                    print("NOT worn")
                case MSBSensorBandContactState.Worn:
                    print("worn")
                case MSBSensorBandContactState.Unknown:
                    print("UNK")
                default:
                    print("uhoh")
                }})
            
            // Fetch Barometer readings
            try! client.sensorManager.startBarometerUpdatesToQueue(nil, withHandler:  {
                (barometerData:  MSBSensorBarometerData!, error:  NSError!) in
                
                let seconds = NSDate().timeIntervalSince1970
                let milliseconds = seconds * 1000.0
                
                self.logToFile(String(format: "3, %0.4f, %0.8f\n",milliseconds,barometerData.temperature))
                self.logToFile(String(format: "4, %0.4f, %0.8f\n",milliseconds,barometerData.airPressure))
            })
            
            // Fetch Galvanic Skin Resistance readings
            try! client.sensorManager.startGSRUpdatesToQueue(nil, withHandler: {
                (skinResistanceData: MSBSensorGSRData!, error: NSError!) in
                
                let seconds = NSDate().timeIntervalSince1970
                let milliseconds = seconds * 1000.0
                
                self.addToInputs(String("GSR"), value: CGFloat(skinResistanceData.resistance))
                
                self.logToFile(String(format: "8, %0.4f, %d\n",milliseconds,skinResistanceData.resistance))
            })
            
            // Fetch Distance readings
            try! client.sensorManager.startDistanceUpdatesToQueue(nil, withHandler: {
                (distanceData:  MSBSensorDistanceData!, error: NSError!) in
                
                let seconds = NSDate().timeIntervalSince1970
                let milliseconds = seconds * 1000.0
                
                self.logToFile(String(format: "11, %0.4f, %d\n",milliseconds,distanceData.motionType.rawValue))
                self.logToFile(String(format: "17, %0.4f, %f\n",milliseconds,distanceData.speed))
                self.logToFile(String(format: "18, %0.4f, %f\n",milliseconds,distanceData.pace))
            })
            
            // Fetch Skin Temperature readings
            try! client.sensorManager.startSkinTempUpdatesToQueue(nil, withHandler: {
                (skinTempData:  MSBSensorSkinTemperatureData!, error: NSError!) in
                
                let seconds = NSDate().timeIntervalSince1970
                let milliseconds = seconds * 1000.0
                
                self.logToFile(String(format: "14, %0.4f, %0.3f\n",milliseconds,skinTempData.temperature))
            })
            
            //Stop stream updates after <repeatTime> seconds
            let repeatTime = 60.0 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(repeatTime))
            dispatch_after(time, dispatch_get_main_queue(), {
                self.stopSensors()
                if self.quitTesting == 1 {
                    self.headerWritten = 0
                    self.quitTesting = 0
                }
                self.startTesting()
            })
        } else {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(delay,
                                                                target: self,
                                                                selector: #selector(self.startTesting),
                                                                userInfo: nil,
                                                                repeats: false)
        }
    }
    
    /*
     Microsoft Band Functons
     */
    func clientManager(clientManager: MSBClientManager!, clientDidConnect client: MSBClient!) {
        //self.output("Band connected.")
        print("Connection")
    }
    func clientManager(clientManager: MSBClientManager!, clientDidDisconnect client: MSBClient!) {
        //self.output("Band disconnected.")
        print("Disconnection")
    }
    func clientManager(clientManager: MSBClientManager!, client: MSBClient!, didFailToConnectWithError error: NSError!) {
        //self.output("Failed to connect to Band.")
        //self.output(error.description)
        print("Error")
        print(error.description)
    }
    
    // Fetch Band Contact readings
    //            try! client.sensorManager.startBandContactUpdatesToQueue(nil, withHandler: {
    //                (bandContactData: MSBSensorBandContactData!, error: NSError!) in
    //
    //                let seconds = NSDate().timeIntervalSince1970
    //                let milliseconds = seconds * 1000.0
    //
    //                self.logToFile(String(format: "6, %0.4f, %d\n",milliseconds,bandContactData.wornState.rawValue))
    //            })
    func determineBandDisconnect() {
        let delay: NSTimeInterval = NSTimeInterval(0.1) // Time until connection retry
        if let client = self.client {
            if client.isDeviceConnected == true {
                try! client.sensorManager.startBandContactUpdatesToQueue(nil, withHandler: {
                    (bandContactData: MSBSensorBandContactData!, error: NSError!) in
                    print(bandContactData.wornState.rawValue)
                })
//                self.timer = NSTimer.scheduledTimerWithTimeInterval(delay,
//                                                                    target: self,
//                                                                    selector: #selector(self.determineBandDisconnect),
//                                                                    userInfo: nil,
//                                                                    repeats: false)
            }
//            else {
//                self.timer = NSTimer.scheduledTimerWithTimeInterval(delay,
//                                                                    target: self,
//                                                                    selector: #selector(self.determineBandDisconnect),
//                                                                    userInfo: nil,
//                                                                    repeats: false)
//            }
        }
    }

    func stop_bandDisconnectUpdates() {
        if let client = self.client {
            try! client.sensorManager.stopBandContactUpdatesErrorRef()
            self.stopSensors()
        }
    }

    func gatherHeartRate(client:  MSBClient) {
        try! client.sensorManager.startHeartRateUpdatesToQueue(nil, withHandler: { (heartRateData: MSBSensorHeartRateData!, error: NSError!) in
            
            let seconds = NSDate().timeIntervalSince1970
            let milliseconds = seconds * 1000.0
            
            self.addToInputs(String("HR"), value: CGFloat(heartRateData.heartRate))
            
            self.logToFile(String(format: "10, %0.4f, %u\n",milliseconds,heartRateData.heartRate))
            self.logToFile(String(format: "16, %0.4f, %d\n",milliseconds,heartRateData.quality.rawValue))
        })
    }
    
    func stopSensors() {
        if let client = self.client {
            try! client.sensorManager.stopBandContactUpdatesErrorRef()
            try! client.sensorManager.stopBarometerUpdatesErrorRef()
            try! client.sensorManager.stopDistanceUpdatesErrorRef()
            try! client.sensorManager.stopGSRUpdatesErrorRef()
            try! client.sensorManager.stopHeartRateUpdatesErrorRef()
            try! client.sensorManager.stopSkinTempUpdatesErrorRef()
        }
    }
    
    /*
     File Logging Functions
     *  resetData:  Clears all logged information
     *  logToFile:  Logs given string to the temporary file
     */
    @IBAction func resetData(sender:  AnyObject?) {
        self.headerWritten = 0 // Resets file
    }
    
    func logToFile(logString: String) {
        // For logging purposes
        if self.headerWritten == 0 {
            let written = try! logString.writeToFile(self.destinationPath, atomically: true, encoding: NSUTF8StringEncoding)
            self.headerWritten = 1
        }
        
        let os:  NSOutputStream = NSOutputStream(toFileAtPath: self.destinationPath, append: true)!
        os.open()
        os.write(logString, maxLength: logString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        os.close()
    }
    
    
    /*
     Array Functions
     *  dot:
     */
    func dot_multiply(a: [CGFloat], b: [CGFloat]) -> CGFloat {
        return zip(a, b).map(*).reduce(0, combine: +)
    }
    func dot_gain(a: [CGFloat], b: [CGFloat]) -> [CGFloat] {
        return zip(a,b).map(*)
    }
    func dot_divide(a: [CGFloat], b: [CGFloat]) -> [CGFloat] {
        return zip(a,b).map(/)
    }
    func dot_add(a: [CGFloat], b: [CGFloat]) -> [CGFloat] {
        return zip(a, b).map(+)
    }
    func dot_subtract(a: [CGFloat], b: [CGFloat]) -> [CGFloat] {
        return zip(a, b).map(-)
    }
    func sigmoid(a: [CGFloat]) -> [CGFloat] {
        // 1 / (1 + e^a) -> out
        let b = a.map({b in 1 / (1 + CGFloat(M_E) ** (-b))})
        return b
    }
    func tansig(a: [CGFloat]) -> [CGFloat] {
        // (1 - e^(-2a)) / (1 + e^(-2a)) -> out
        let b = a.map({b in ((1 - CGFloat(M_E) ** (-2*b)) / (1 + CGFloat(M_E) ** (-2*b)))})
        return b
    }
    
    /*
     Neural Network Functions
     */
    func addToInputs(sensor: String, value: CGFloat) {
        
        if sensor == "GSR" {
            // kOhm --> uSiemen conversion
            // pow(allSamples_data['GSR']/100000,-1)
            self.currentGSR = (value / 100000) ** (-1)
            self.currentGSR_DR = (self.currentGSR - self.lastGSR) / self.lastGSR
            // Update Input Vector .. index 0--129
            /*
             GSR:       0....29
             GSR_diff:  30...59
             HR:        60...89
             HR_diff:   90..119
             */
            // Update(GSR)
            self.measurementArray.insert(CGFloat(self.currentGSR), atIndex: 0)
            self.measurementArray.removeAtIndex(30)
            // Update(GSR_diff)
            self.measurementArray.insert(CGFloat(self.currentGSR_DR), atIndex: 30)
            self.measurementArray.removeAtIndex(60)
            // Update(HR)
            self.measurementArray.insert(CGFloat(self.currentHR), atIndex: 60)
            self.measurementArray.removeAtIndex(90)
            // Update(HR_diff)
            self.measurementArray.insert(CGFloat(self.currentHR_DR), atIndex: 90)
            self.measurementArray.removeAtIndex(120)
            
            // Apply GAIN and OFFSET
            //            norm_data = (bla - minVal) / ( maxVal - minVal )
            
            self.inputArray = dot_subtract(self.measurementArray, b: self.xMin)
            self.inputArray = dot_divide(self.inputArray,b:self.xRange)
            self.inputArray = dot_gain(self.inputArray, b: yRange)
            self.inputArray = dot_add(self.inputArray, b: yMin)
            
            // Store vectors and call on NeuralNetwork
            var output_Sequence:  [CGFloat] = [(dot_multiply(self.inputArray,b: self.IW_r1)),
                                               (dot_multiply(self.inputArray,b: self.IW_r2)),
                                               (dot_multiply(self.inputArray,b: self.IW_r3)),
                                               (dot_multiply(self.inputArray,b: self.IW_r4)),
                                               (dot_multiply(self.inputArray,b: self.IW_r5)),
                                               (dot_multiply(self.inputArray,b: self.IW_r6)),
                                               (dot_multiply(self.inputArray,b: self.IW_r7)),
                                               (dot_multiply(self.inputArray,b: self.IW_r8)),
                                               (dot_multiply(self.inputArray,b: self.IW_r9)),
                                               (dot_multiply(self.inputArray,b: self.IW_r10)),
                                               (dot_multiply(self.inputArray,b: self.IW_r11)),
                                               (dot_multiply(self.inputArray,b: self.IW_r12)),
                                               (dot_multiply(self.inputArray,b: self.IW_r13)),
                                               (dot_multiply(self.inputArray,b: self.IW_r14)),
                                               (dot_multiply(self.inputArray,b: self.IW_r15)),
                                               (dot_multiply(self.inputArray,b: self.IW_r16)),
                                               (dot_multiply(self.inputArray,b: self.IW_r17)),
                                               (dot_multiply(self.inputArray,b: self.IW_r18)),
                                               (dot_multiply(self.inputArray,b: self.IW_r19)),
                                               (dot_multiply(self.inputArray,b: self.IW_r20))]
            output_Sequence = dot_add(output_Sequence,b: self.b1)
            output_Sequence = tansig(output_Sequence)
            output_Sequence = [dot_multiply(output_Sequence,b:self.L2W_r1),
                               dot_multiply(output_Sequence,b:self.L2W_r2),
                               dot_multiply(output_Sequence,b:self.L2W_r3),
                               dot_multiply(output_Sequence,b:self.L2W_r4),
                               dot_multiply(output_Sequence,b:self.L2W_r5),
                               dot_multiply(output_Sequence,b:self.L2W_r6),
                               dot_multiply(output_Sequence,b:self.L2W_r7),
                               dot_multiply(output_Sequence,b:self.L2W_r8),
                               dot_multiply(output_Sequence,b:self.L2W_r9),
                               dot_multiply(output_Sequence,b:self.L2W_r10),
                               dot_multiply(output_Sequence,b:self.L2W_r11),
                               dot_multiply(output_Sequence,b:self.L2W_r12),
                               dot_multiply(output_Sequence,b:self.L2W_r13),
                               dot_multiply(output_Sequence,b:self.L2W_r14),
                               dot_multiply(output_Sequence,b:self.L2W_r15),
                               dot_multiply(output_Sequence,b:self.L2W_r16),
                               dot_multiply(output_Sequence,b:self.L2W_r17),
                               dot_multiply(output_Sequence,b:self.L2W_r18),
                               dot_multiply(output_Sequence,b:self.L2W_r19),
                               dot_multiply(output_Sequence,b:self.L2W_r20)]
            output_Sequence = dot_add(output_Sequence,b: self.b2)
            output_Sequence = tansig(output_Sequence)
            output_Sequence = [dot_multiply(output_Sequence,b:self.L3W_r1),
                               dot_multiply(output_Sequence,b:self.L3W_r2),
                               dot_multiply(output_Sequence,b:self.L3W_r3),
                               dot_multiply(output_Sequence,b:self.L3W_r4),
                               dot_multiply(output_Sequence,b:self.L3W_r5),
                               dot_multiply(output_Sequence,b:self.L3W_r6),
                               dot_multiply(output_Sequence,b:self.L3W_r7),
                               dot_multiply(output_Sequence,b:self.L3W_r8),
                               dot_multiply(output_Sequence,b:self.L3W_r9),
                               dot_multiply(output_Sequence,b:self.L3W_r10)]
            output_Sequence = dot_add(output_Sequence,b: self.b3)
            output_Sequence = tansig(output_Sequence)
            output_Sequence = [dot_multiply(output_Sequence,b:self.L4W_r1)]
            output_Sequence = dot_add(output_Sequence,b: self.b4)
            var desiredOutput = output_Sequence[0]
            desiredOutput -= self.yMin[0]
            desiredOutput /= self.yGain
            desiredOutput += self.xOffset
            
            // Boot-up sequence!!
            if desiredOutput.isNaN {
                desiredOutput = 0
            }
            else {
                let diff = desiredOutput - self.stressIndex
                if fabs(diff) <= self.stressSlope_limit {
                    self.stressIndex = desiredOutput
                }
                else if diff > self.stressSlope_limit {
                    self.stressIndex += self.stressSlope_limit
                }
                else {
                    self.stressIndex -= self.stressSlope_limit
                }
                self.stressIndex = round(self.stressIndex * 10) / 10 // Not necessary, but it's nice
            }
            var relayedStress = max(0,round(self.stressIndex))
            relayedStress = min(100,relayedStress)
            relayedStress = 100-relayedStress
            
            let time = NSDate().timeIntervalSince1970
            if !(relayedStress.isNaN) {
                self.measurementsRecorded += 1
//                self.dailyCalmleeScore += relayedStress
                if relayedStress < 50 {
                    self.cumulativeStressTime_interim += CGFloat(time - self.lastCumulativeUpdateTime)
                }
                self.lastCumulativeUpdateTime = time
            }
            else {
                relayedStress = 100;
            }
            
            // Notifications for Long Duration Stress
            if (relayedStress < CGFloat(self.calm_min)) {
                if self.currentlyStresed == false {
                    self.currentlyStresed = true
                    self.stressStart = NSDate().timeIntervalSince1970
                }
                else {
                    let currentWarning_notificationCount = Int(floor((time - self.stressStart) / self.defaults.doubleForKey("intervalSecondsInStress_toWarn")))
                    if currentWarning_notificationCount != self.longDurationStress_notificationCount {
                        
                        let stressTime_minutes = Int(floor((time - self.stressStart) / 60))
                        
                        if self.tileExists {
                            self.client?.notificationManager.sendMessageWithTileID(self.tileId,
                                                                                   title: "Continued Stress",
                                                                                   body: "Go to Calmlee App to ease your stress.",
                                                                                   timeStamp: NSDate(),
                                                                                   flags: MSBNotificationMessageFlags.ShowDialog, completionHandler: { (error: NSError!) in
                                                                                    if (error != nil) {
                                                                                        print(error)
                                                                                    }
                            })
                        }
                        self.app_notifications.longDurationStress.alertBody = "Calmlee detected that you have been stressed for \(stressTime_minutes) minutes.\n\nGo to Calmlee App to ease your stress."
                        UIApplication.sharedApplication().scheduleLocalNotification(self.app_notifications.longDurationStress)
                        self.longDurationStress_notificationCount = currentWarning_notificationCount
                    }
                }
            }
            else {
                self.currentlyStresed = false
            }
            
            // Notifications for Extreme Stress
            if (relayedStress < CGFloat(self.calm_extreme)) &&
                (time - self.last_extremeStress > self.defaults.doubleForKey("secondsBetween_extremeStress")) {
                UIApplication.sharedApplication().scheduleLocalNotification(self.app_notifications.extremeStress)
                
                if self.tileExists {
                    print("sending notification")
                    self.client?.notificationManager.sendMessageWithTileID(self.tileId,
                                                                           title: "Extreme Stress",
                                                                           body: "Go to Calmlee App to ease your stress.",
                                                                           timeStamp: NSDate(),
                                                                           flags: MSBNotificationMessageFlags.ShowDialog, completionHandler: { (error: NSError!) in
                        if (error != nil) {
                            print(error)
                        }
                    })
//                    [self.client.notificationManager
//                        sendMessageWithTileID:tileId
//                        title:@"Message title"
//                    body:@"Message body"
//                    timeStamp:[NSDate date]
//                    flags:MSBNotificationMessageFlagsShowDialog
//                    completionHandler:^(NSError *error)
//                    {
//                        if (error){
//                            // handle error
//                        }
//                    }];
                    
                    print("sent :)")
                }
                
                self.extremeStress_notified = true
                self.last_extremeStress = NSDate().timeIntervalSince1970
            }
            
            // Update of Stress Meter
            if ((time - self.lastUpdateTime) > self.timeBetweenUpdates) {
                self.lastUpdateTime = NSDate().timeIntervalSince1970
                stressMeter?.stressIndex = relayedStress
                stressMeter?.stressIndex_number.text = String(format: "%0.0f",relayedStress)
                self.calmleeScore = relayedStress
                
                // For plotting
                calmleeScores_tmp_sum += relayedStress
                calmleeScores_tmp_cnt += 1
                calmleeScores_tmp_min = min(calmleeScores_tmp_min, relayedStress)
                calmleeScores_tmp_max = max(calmleeScores_tmp_max, relayedStress)
                
                self.cumulativeStressTime_inPeriod += cumulativeStressTime_interim
                self.cumulativeStressTime_interim = 0
            }
            if ((time - self.lastCumulativeUpdateTime_major) > self.timeBetweenStressUpdates) {
                self.lastCumulativeUpdateTime_major = time
                self.cumulativeStressTime = self.dot_cumulativeStress(
                    self.cStress_time,
                    b_val: CGFloat(time) - self.cumulativeStressPeriod,
                    c: self.cStress_stress_t)
                self.dailyCalmleeScore = self.cumulativeStressTime
                
                self.writeStressFile(0,initialize: false)
                
                // Stress File
                self.cStress_time.append(CGFloat(time))
                self.cStress_stress_t.append(self.cumulativeStressTime_inPeriod)
//                self.cumulativeStressTime_weekly += cumulativeStressTime_inPeriod
                self.cumulativeStressTime_inPeriod = 0
                
                // For plotting
                let calmleeScores_tmp_avg = calmleeScores_tmp_sum / calmleeScores_tmp_cnt
                self.calmleeScores_avg.append(calmleeScores_tmp_avg)
                self.calmleeScores_min.append(calmleeScores_tmp_min)
                self.calmleeScores_max.append(calmleeScores_tmp_max)
                self.calmleeScores_time.append(CGFloat(time))
                
                // Update Log File
                self.writeCalmleeScoreFile(false,
                                           closing: false,
                                           time: CGFloat(time),
                                           avg: calmleeScores_tmp_avg,
                                           min: calmleeScores_tmp_min,
                                           max: calmleeScores_tmp_max)
                self.calmleeScores_tmp_sum = 0.0
                self.calmleeScores_tmp_min = 100.0
                self.calmleeScores_tmp_max = 0.0
                self.calmleeScores_tmp_cnt = 0.0
            }
            if ((time - self.lastWeeklyFileUpdate) > self.timeBetweenStressUpdates) {
//                self.cumulativeStressTime_weekly
                self.lastWeeklyFileUpdate = time
            }
            
            self.lastGSR = self.currentGSR
        }
        if sensor == "HR" {
            self.currentHR = value
            self.currentHR_DR = (self.currentHR - self.lastHR) / self.lastHR
            self.lastHR = self.currentHR
        }
    }
    
    /*
     All file transmission information
     */
    func sendFile() {
        let semaphore = dispatch_semaphore_create(0);
        
        //        self.sendButton.alpha = 0.1
        //        UIView.animateWithDuration(2) {
        //            self.sendButton.alpha = 1
        //        }
        // https:  currently the main certificate has not been "Trusted".
        // CHANGE BEFORE DEPLOYMENT!
//        let url:  NSURL? = NSURL(string: "http://52.40.26.30/experiment_collection.php")
        let url:  NSURL? = NSURL(string: "https://io.calmlee.com/experiment_collection.php")
        
        let request = NSMutableURLRequest(URL:url!);
        request.HTTPMethod = "POST"
        
        let boundary = generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageData:  NSData? = NSData(contentsOfFile: self.destinationPath)!
        
        if (imageData == nil) {return;}
        
        let param = [
            "user" : "Eric",
            "experimental" : "yes"
        ]
        
        request.HTTPBody = createBodyWithParameters(param, filePathKey: "file", imageDataKey: imageData!, boundary: boundary)
        
        let task =  NSURLSession.sharedSession().dataTaskWithRequest(request,
                                                                     completionHandler: {
                                                                        (data, response, error) -> Void in
                                                                        if let data = data {
                                                                            
                                                                            // You can print out response object
                                                                            print(">>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<")
                                                                            
                                                                            print("******* response = \(response)")
                                                                            
                                                                            
                                                                            print("STATUS CODE!!!  >>")
                                                                            if let httpResponse = response as? NSHTTPURLResponse {
                                                                                print(httpResponse.statusCode == 200)
                                                                                if (httpResponse.statusCode == 200) {
                                                                                    print("woot")
                                                                                }
                                                                            }
                                                                            print("STATUS CODE!!!  <<")
                                                                            
                                                                            print(data.length)
                                                                            
                                                                            let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
                                                                            print("****** response data = \(responseString!)")
                                                                            
                                                                            print(">>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<")
                                                                            
                                                                        dispatch_get_main_queue()
                                                                            
//                                                                            dispatch_async(dispatch_get_main_queue(),{
//                                                                            });
                                                                            
                                                                        } else if let error = error {
                                                                            print(error.description)
                                                                        }
                                                                        
                                                                        self.sentSuccessfully = true
                                                                        
                                                                        dispatch_semaphore_signal(semaphore);

        })
        task.resume()
        self.quitTesting = 1
        dispatch_semaphore_wait(semaphore, 4*(NSEC_PER_SEC));
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if sentSuccessfully {
            let fileManager = NSFileManager.defaultManager()
            try! fileManager.removeItemAtPath(self.destinationPath)
        }
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, imageDataKey: NSData, boundary: String) -> NSData {
        print("======")
        print(imageDataKey)
        print("======")
        let body = NSMutableData();
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }
        
        let filename = "testing.csv"
        
        let mimetype = "text/csv"
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.appendData(imageDataKey)
        body.appendString("\r\n")
        
        body.appendString("--\(boundary)--\r\n")
        
        return body
        
    }
    
    /*
     Neural Network Layer Parameters
     */
    // Initialization of Weights and Biases
    // Input Min
    let xMin:  [CGFloat] = [0.293832456733000013660017657457501627504825592041015625,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,-0.99461698939300002830776747941854409873485565185546875,48,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375,-0.283783783783999987715418455991311930119991302490234375]
    
    // Input Delta (max-min)
    let xRange:  [CGFloat] = [67.27373511086699409133871085941791534423828125,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,67.5675675675999940494875772856175899505615234375,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,128.712468729393009425621130503714084625244140625,44,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,92,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875,0.73661397246299997743079757128725759685039520263671875]
    
    let yRange:  [CGFloat] = [CGFloat](count: 30*4, repeatedValue: CGFloat(2))
    let yMin:  [CGFloat] = [CGFloat](count: 30*4, repeatedValue: CGFloat(-1.0))
    
    // Output Adjustments
    let yGain: CGFloat = CGFloat(0.0209811860075027)
    let xOffset:  CGFloat = CGFloat(0.579220936993)
    
    // Input Weights (load from CSV later)
    let IW_r1:  [CGFloat] = [-0.1556447487230403214919505217039841227233,-0.06092286321609169386093185494246426969767,0.1213965016522900453033173562289448454976,0.1957947529146086551588012980573694221675,0.09140004000685916785151619023963576182723,0.2231698800390230774670641267221071757376,0.1559498314161375520647823122999398037791,-0.07855104125522860414321257849223911762238,0.1341106465340228814930867429211502894759,-0.1614264760949688792823764060813118703663,0.1953732588197962527498674489834229461849,-0.004541064247686377522428280428812286118045,-0.1581855550332380289102474080209503881633,0.1836790008672699592295884940540418028831,0.06195089861450864265890459137153811752796,0.01301154924482746631786422852883333689533,0.1736790932260278141896492343221325427294,-0.1278511665106719930040668486981303431094,0.1831629633511084598307405713057960383594,-0.196844487701478054741954792916658334434,-0.05876173272910847900085684614168712869287,0.1108214761258118769005065473720605950803,-0.08667671847172005172854625243417103774846,-0.2170782888983133762650368225877173244953,-0.124518199856388581125976600105786928907,0.03282380797625982643550557327216665726155,-0.06381949345297018016953671804003533907235,-0.1668936829644976360675912019360112026334,0.03203953998983150031065747498359996825457,-0.09581684675481499935401075163099449127913,-0.09561821713439654091271080460501252673566,-0.2073023136110825337397045586840249598026,-0.1782865479091902405350822391483234241605,0.07258328365822980243748929751745890825987,-0.1242381877673164741748834671852819155902,0.1051079554668793020200112664497282821685,-0.1415262949074308773678154693698161281645,-0.1393687774035830551078163352940464392304,0.0239498752050556033832418023621357860975,-0.1423970101805850374532269597693812102079,0.003774238645008530599472829081264535489026,0.02988491233385772924413537054988410091028,0.001991895550921465168903168319047836121172,-0.02904370551377927558989178180581802735105,-0.1844740172468558592200338352995458990335,-0.07442636758967569043932144268183037638664,-0.05927955370156130082692769178720482159406,0.1031882655122850211970586542520322836936,-0.0612894971366322940942161778821173356846,0.1733631922430827199121949888649396598339,0.1259263256644077011436877455707872286439,-0.1552621824463067401467242234502919018269,-0.03745945886804100122269289840915007516742,0.08669919163357556191051855876139597967267,-0.03711884595833975231116141912934836000204,-0.2107593304829704639047349701286293566227,-0.04330703895308547074494143203082785475999,-0.1843172267819390974796789350875769741833,-0.06018083530723237345450016277936811093241,0.07329645189168315644323570268170442432165,-0.04028576465875963186213937206048285588622,-0.03753496597683509544696178750200488138944,0.190988679410444145423397799277154263109,0.2165122212854445060692398783430689945817,0.1028324539148178506930975117938942275941,0.08764090717682913866948268832857138477266,-0.1134515334204954650765273527213139459491,-0.07056493001786257046603623166447505354881,0.1281745982298070074545393026710371486843,-0.06202628746555714778221357619258924387395,0.01876672535856463430725682428601430729032,-0.03795680576318489346521189986560784745961,-0.18628437328945793294288080232945503667,-0.1205209743696084717656802354213141370565,-0.1044491048106031966247186915097699966282,-0.1376114128798807956233218874331214465201,0.07703573170358753163800002994321403093636,-0.01491496403702245038269680321718624327332,-0.2204649684959083810742441755792242474854,-0.05649075887314673055650260380389227066189,0.07695773466650741856387440975595382042229,0.07236608440227960958868180796343949623406,-0.1841805441173174351376928825629875063896,-0.07121618066944887526226182217214955016971,0.08941737978758430849257621275683050043881,-0.002709624890457528346293658572108142834622,0.209740000408063592685081744093622546643,0.1028481078749557409146575537306489422917,0.2139801016208325301626302916702115908265,-0.1878931602232776221228505164617672562599,-0.2203714149901709884460387911531142890453,0.1899186349417917307746961341763380914927,-0.1905378759137608124518692420679144561291,0.09682087401602028353675422067681211046875,0.1336561298631599725705854098123381845653,0.1525732054808809634582900116583914496005,0.002918141670368849804884092691281693987548,-0.02673394287758388068731996156657260144129,-0.1857658556397095983570011412666644901037,0.1331305821463191763065481154626468196511,0.1068912697957882379506955317083338741213,-0.08543102729836576925137592297687660902739,0.2117637990025155736439899101242190226912,-0.1405137273940269271310654630724457092583,0.1201590234266766976656271026513422839344,0.07627613575995308148325335650952183641493,0.08768500256615567589602022735562059096992,-0.1075435206706945034937916716444306075573,-0.111752396739358286770205097582220332697,-0.1700033947732675632114052177712437696755,-0.1234652429063028272748780977963178884238,0.09133966683115789242375370804438716731966,-0.1058073457502495956505939034286711830646,-0.1190809800059249579096132265476626344025,0.1940815543011347732438309776625828817487,0.1558795021067111707946395426915842108428,-0.1480020648937858396276823214066098444164,-0.2140372940679839963706854177871719002724,-0.1620170784261506236045846662818803451955,0.1517635524029351257180309175964794121683]
    let IW_r2:  [CGFloat] = [-0.04849896389333756968609279169868386816233,0.05956428813165823288322542339301435276866,-0.1210152183419246768592003604680940043181,-0.1648420573114856846341780283182743005455,0.01574045084106050901295859034689783584327,0.1197791059972648508580306270232540555298,0.163704704847627779962238037114730104804,-0.0614696895978713991892661283600318711251,-0.1539175424831487892785020221708691678941,-0.02449925661940257834436884820661362027749,0.03824544363383348272167339132465713191777,-0.1369183191133465093969334702705964446068,0.06161050802810187632108096522642881609499,0.1964688707096080011460514924692688509822,-0.02639295908859033354398881954239186597988,0.06753390079065417495041145912182400934398,0.01380374561931391880209574196669564116746,-0.03111732870671057860079145029885694384575,0.006889233143954678721676554431496697361581,-0.1607662466251400246175506936197052709758,0.02307932664462686647710576437475538114086,-0.1196073821294124789327284474893531296402,0.1085790525457010491372500382567523047328,-0.1987982327790743519724259158465429209173,0.217860051297496554179033978471125010401,-0.1543234025564571010313841270544799044728,-0.2122136127117635606698087258337181992829,0.1969930468533820921983590324089163914323,0.1420220732640509464506095582692069001496,0.1422172817395120636430050353737897239625,-0.2125770903439546388735692517002462409437,-0.06989412831624505773042699274810729548335,-0.09015787629259065794062877330361516214907,0.1931729528311621202352199588858638890088,0.1670526074194386978444271107946406118572,-0.06746586126309302156034419795105350203812,0.1469426628494984732320460807386552914977,0.2078899513186579783852181435577222146094,-0.08524503589792030433525127364191575907171,0.1304306394591558948548026819480583071709,0.01824170625192910594192241546807053964585,0.04277930531268032271485779460817866493016,-0.04795103701676205198989322298075421713293,-0.1258641537717226088766153679898707196116,0.1427011432417434610986362031326279975474,0.1042831627601454314024920222436776384711,0.1212843770612900551331136966837220825255,0.01862142990341753359673226952963887015358,-0.2092107506692642560075512392359087243676,-0.1451870937274913897496730896818917244673,-0.1527933314555935950806997425388544797897,-0.2239944849515158598052266825106926262379,-0.2192867493475653961620963627865421585739,0.1917718772935586846184463638564920984209,-0.05926067197336953862318864594271872192621,0.0005660367449779207284221715923422380001284,-0.2242302227757615173953098519632476381958,-0.06310733502042165099510384607128798961639,-0.106859699235301655595442582580290036276,-0.03643160999133225608215269630818511359394,-0.07867143153439967728779436129116220399737,-0.04874866603875895737507661920062673743814,0.1067259328023910658345130286761559545994,0.08223729795979346779422058943964657373726,0.05888469219987117753145611231957445852458,-0.2152527359539561646606387057545362040401,-0.02338555795130342965237879582218738505617,-0.1164734282154775701911830765311606228352,-0.1028365857253914356084223413745348807424,-0.1413116339715288494183198508835630491376,-0.1844711056072335930711147966576390899718,-0.1036550683228138480806990173732629045844,0.1274177760932658221015856270241783931851,0.1471015300951921123129295665421523153782,0.1197018421202302868033839899908343795687,0.1364871081251536333311946691537741571665,0.1536746334467627428388425414595985785127,-0.1063775238567092884522935491986572742462,-0.1338490390559848031148959535130416043103,0.123569438467643843981846885071718133986,0.2230558058670955856594986244090250693262,0.03700623655082957430551005018060095608234,0.05036604718075555348066885130720038432628,-0.09759907502181508487382188832270912826061,-0.19727699003590556947607126403454458341,0.1865318707364126693537542678313911892474,0.1912396290372355145414928756508743390441,0.02361481439605435730944016370358440326527,0.09646311941260002353892843984795035794377,-0.2169206005732900455207357026665704324841,0.1735175568386709277213242330617504194379,-0.05478529576822305929839629357047670055181,-0.009295060059543214930899424075505521614105,-0.08122577519681292712583342563448240980506,-0.1378748687173768638913884387875441461802,0.03113941133403029873361056445446592988446,-0.1425659709935483965281832752225454896688,0.02105216532098076742673953276607790030539,-0.117179712303788832739037673036364139989,-0.01062691036436480378213342845583611051552,0.1694861967520749357341003360488684847951,-0.02879251462182580434401302227342966943979,0.06561037405673286748708505911054089665413,0.2154481522119965908323990788630908355117,-0.1527474123259661697993294637853978201747,0.2010943749479741360364215552181121893227,-0.05004739820926105281495566146077180746943,-0.1287122774478295927913507057382958009839,-0.1634374911561911891677567609804100356996,-0.07639914263961943008407473598708747886121,-0.06515238347500335036599494742404203861952,0.1858586081406888024236678802481037564576,-0.1771442802236004865346075121124158613384,-0.097936401520575519508149398006935371086,0.2042793759367858008602070185588672757149,-0.07839993420526145118110150633583543822169,0.146368498200850349899582170110079459846,0.06125845734283239668593878946012409869581,0.08454193900985766674249788366068969480693,-0.162535896658064338282656535739079117775]
    let IW_r3:  [CGFloat] = [0.1618022302641463905370500242497655563056,-0.05068275091151679817569331021331890951842,-0.04282206322429070455282129614715813659132,0.009795519043955869253892387860105372965336,0.009081639862509377145172173584342090180144,-0.1839802541474268859911234130777302198112,0.1593801682734625191351085504720686003566,0.01753123406693476993289948495657881721854,0.07171633070432294199125777822700911201537,-0.06735644368804968862285420527769019827247,0.004920619655424752006411814875264099100605,0.1284188601984494748631249194659176282585,0.01901315762698158745580556683307804632932,0.1280423019330848843910786172273219563067,0.02002850039537856785543112891900818794966,-0.05556167745127651297343263081529585178941,0.1869180839358421941653887188294902443886,0.187150753355702886837619303150859195739,0.02446785758747122008216479116526897996664,-0.1019074803629236719570982927507429849356,0.1961627950924784979935822093466413207352,-0.2086848277572604659635402413186966441572,-0.08697275972382569053653611490517505444586,0.005151891058681051793755045764555688947439,-0.0916011544188825299617207065239199437201,0.1495143845953394445835726855875691398978,0.1917590405451090052046936307306168600917,-0.1316801413309881541024992657185066491365,-0.08952338444988225396592440574750071391463,-0.04122636156292004694368102946100407280028,-0.2086022874559361750534947077539982274175,-0.06294742589593346759890835073747439309955,-0.198643744018720647126485800981754437089,-0.07459454008191458707077714507249766029418,0.2151422894578576272550662906724028289318,0.07214675844505762103420209996329504065216,0.07125299978623114705023056103527778759599,-0.194379330886611884077197487386001739651,-0.1208947626973934791339004846122406888753,-0.1967448102154615019454553248579031787813,-0.1570955547490016923628530776113620959222,0.2021176419757089448570042122810264118016,0.02439583718298441936123133189084910554811,0.08581211744616885905845293791571748442948,-0.04686215469152539558894687843348947353661,0.147312259424714708799797335814218968153,0.05581921980935872218410054301784839481115,-0.132150660310063339242248048321926034987,-0.1669895327764856496344236802542582154274,-0.1066290708623781613439973625645507127047,0.004976958766225341064537435187276059878059,0.02882711482333330521576897353952517732978,-0.1389939331649223674958193441852927207947,-0.1311152136646137056352756644628243520856,0.1471644387356238481423531538894167169929,-0.2220075525699952978531115377336391247809,0.03026519169741869602630046642843808513135,-0.04230286211137947172122864003540598787367,0.1967730454046191512773589238349813967943,-0.1260531554320917790867895291739841923118,0.07724243516686891963818339945646584965289,0.1846642557666160755491802092365105636418,-0.00145337105106367148014967494162874572794,-0.1571267364114101172667403716332046315074,-0.1344522213996754145259870938389212824404,-0.1477574852654145176611422130008577369153,0.1883005830070962061117967323298216797411,-0.1522259929690409907543369172344682738185,0.006503621037470216394160704709292986080982,0.1865780475369192281664965094023500569165,-0.003880408708551948571835454870893045153935,0.002130275112924436345385181823530729161575,0.01484784152176795574140655276096367742866,0.1597012842760693884791578511794796213508,0.1426632362558555022769013476136024110019,-0.1499971495989532721537784709653351455927,0.2023794597120715799132284473671461455524,0.06468371696094223077810880795368575491011,0.1860879238551811643009870067544397898018,-0.1972140600734597348786536485931719653308,-0.2180684294254454369532680857446393929422,0.03711017057893649384592293927198625169694,0.1295836388160603036556750566887785680592,-0.2245592497255059494243312201433582231402,-0.2253070162912308438407649191503878682852,0.04850893847980139450548620061454130336642,0.1236703572999156564016232096037128940225,0.001760861355791761354017133101024228380993,0.08779054042211280328711353604376199655235,0.1823367656710805639885819573464686982334,0.1304292597703205491832534335117088630795,0.2042201056144360427069273100642021745443,0.113932713388617656846690806560218334198,-0.08283960937796656931464411854904028587043,0.004055177438730279623757546403339802054688,0.07867553830268932124614167378240381367505,0.1536690396241754963391201727063162252307,0.1335898242046765493906690380754298530519,-0.1458675702676581198424798913038102909923,0.1283596597999730748451696626943885348737,0.03936701741219845313013436793880828190595,0.1838284348682970859023555476596811786294,0.043949557438249992058487691792834084481,-0.02137552260341108248398178659499535569921,-0.1024869629566250717189745955693069845438,-0.1868036053598725876323527472777641378343,0.1624902265153812530584787054976914077997,-0.08782084609013902920526817297286470420659,-0.1561873460664811863463086183401173911989,0.1478463727379375480808221254847012460232,-0.1499145250635572357289504452637629583478,-0.148451453545214800966434154361195396632,-0.02022740268600362739670472933539713267237,0.1149763693318159862855054598185233771801,0.01281809545089461141453845982596249086782,-0.2167091124279283687048547335507464595139,-0.05569438570683505479452790609684598166496,0.1440158170989848662735255402367329224944,0.1454450360629377658749916690794634632766,-0.08695377421999567202348657701804768294096]
    let IW_r4:  [CGFloat] = [-0.2206534534302868610922132575069554150105,-0.1310635309152782257413605293550062924623,-0.1247686892092172150636741889684344641864,0.04714439194970157509523289718345040455461,0.08500080376088359201958155608735978603363,0.0253671565008968015464407841363936313428,-0.1069053123122996468152834381726279389113,-0.03918949621691381751675820055424992460757,-0.2083691457603731589376394595092278905213,0.2333683767818634513524500562198227271438,-0.04963401500352764700307872658413543831557,-0.1618072148984668334747993867495097219944,0.1156234907748479728839541280649427790195,0.1371894483782018780981815098130027763546,-0.1401917253044957512031487567583099007607,0.03170755265713309095643168689093727152795,0.1117813904019154813695990924315992742777,-0.217311735773557640483133468478627037257,-0.0092254553547739624047574480414368736092,-0.1729645469589665696119595850177574902773,0.07882765118805336312934883835623622871935,-0.1753901120725046558490589632128830999136,-0.07054279911480963727310466993003501556814,0.1884691140961916588913993564347038045526,0.1902570102026444054388321092119440436363,0.1928611017856097509248769483747310005128,-0.1890085834730698133299142682517413049936,0.1234922635817440328409588801150675863028,-0.1734830624807664478659319229336688295007,-0.0840082219390172191264554157896782271564,-0.07837119290976485297406384233909193426371,-0.1184992673410745628315154931442521046847,-0.09763846070632480056428192938255961053073,-0.04886078629000661921466530657198745757341,-0.04795728843088036680297747693657584022731,0.2125885251106605644544345068425172939897,-0.06654606396369798504419890150529681704938,-0.1373349618596828303207502131044748239219,0.1660313489530480801636969090395723469555,-0.07753082386100954015439867816894548013806,0.1355253503263409708967657252287608571351,-0.04499922667243570068018598817616293672472,-0.1951042259507212994762426205852534621954,-0.1115230186055760769336941962137643713504,-0.1355999689108359496092504059561179019511,-0.1149634338772362318614739251643186435103,0.1427369351408877273801323326551937498152,-0.1603852262880683110513047040512901730835,-0.1082252434812375485595481450218358077109,-0.07547466364043009523498994894907809793949,-0.1240055915907035677392400430107954889536,0.01055833738157201454055389433506206842139,0.02772647011158211466375078657620179001242,-0.040063583079948748844056893858578405343,0.1285500249350760293420847801826312206686,-0.127745014616371749260892443089687731117,-0.1746311001737210211182116381678497418761,-0.2494459435168970562468615526086068712175,0.1004499094705516293313252162988646887243,0.1520054480368542570989376372381229884923,-0.08111422706328956511168115639520692639053,0.1484895059618919765931366328004514798522,-0.2191856417492134556646021792403189465404,0.09931106337978573561642292588658165186644,-0.1863552854594934804488559620949672535062,0.07117770989081988186608640489794197492301,-0.06474067177726620936351054069746169261634,0.07720433563370800167380281209261738695204,-0.09724495555061749008096683155599748715758,-0.2307897542727702644427267841820139437914,-0.05231660044635331324736071678671578411013,-0.104512972225031891548852058804186526686,0.03760740234946267912530259991399361751974,-0.2094389975525107749909636822849279269576,0.1684477713596433667841978376600309275091,0.1806847053734453589779462845399393700063,0.1361251296198254523428516904459684155881,-0.03235769306270464690244992311818350572139,-0.1360776089633030372372246574741438962519,0.2134012869185313576725349093976547010243,-0.08020372683639186150994504487243830226362,-0.07922310922990234705043377516631153412163,-0.01037030537423132628416233558255044044927,-0.0448292843626724585304188508416700642556,-0.1557467672094432764584581718736444599926,0.07229550552383705308567840575051377527416,-0.0468657622563015408001518835590104572475,0.13850873831493315524454601472825743258,-0.1206038783365171729311526860328740440309,-0.1045946159692241472782825439935550093651,0.112847158536135999673533092391153331846,-0.1284635596795450640517088913838961161673,-0.02466582333619456168793959704998997040093,-0.1324105738725945280442886087257647886872,-0.06390158851005349471829930507738026790321,0.0006285022459415747983491051797955151414499,0.1751555779006110091788883664776221849024,0.01542806546239181529622808142221401794814,0.1703346187790741594891841259595821611583,0.06930589497414853250578659071834408678114,0.01239871971586443619162132279143406776711,0.04109762140383110134989053108256484847516,0.1005484875772721525821751242801838088781,-0.03699077749056871311506000665758620016277,-0.2108049327147697160622641376903629861772,0.03714220951435909939819524083759461063892,-0.07467675939217688352300683618523180484772,-0.002510364046243256791468567712399817537516,-0.01236387117261548984625818548011011444032,0.2163633705015039210284299997510970570147,0.1780111904653458587688419356709346175194,-0.03225766309931707431779557282425230368972,-0.1077548366297197274255026400169299449772,-0.1943066715286935475237584114438504911959,-0.2405345608860022521557908703471184708178,-0.06068670598601603322075348501130065415055,-0.06985607930553748567970018257256015203893,0.2134040227848898740869998391644912771881,-0.06190769497460157227974875127074483316392,0.2226686448254143191327614204055862501264]
    let IW_r5:  [CGFloat] = [-0.1981696993221510327831680342569597996771,0.002226714895548062220220764118039369350299,-0.1247194791269410490963664983610215131193,-0.2395296455696307169613845644562388770282,-0.1128147731542690074268975308768858667463,0.2036335788696455317836608855941449292004,0.04897335454194524234639018800407939124852,-0.1942256574761452581068255085483542643487,0.07631638720491046301575011057138908654451,0.2385405992762684723729194047336932271719,0.08516188398448257257378202211839379742742,0.1461899850728429206547787089220946654677,0.1668396835219226326252339731581741943955,-0.04738957106356320170270635117049096152186,-0.2067545885839606745193464121257420629263,0.1875337274642392138002122692341799847782,-0.03449871433153713778940741008227632846683,-0.04775936006994214305665380493337579537183,0.1189173521223486906794875039850012399256,0.1992551689704772643896291128839948214591,0.06787505636725033042466748156584799289703,0.1555854178200214155136649196720100007951,-0.1075696170202583290542719396398751996458,-0.1666928325955958634096987225348129868507,0.227411844427574227900379355560289695859,-0.2008458474381065450575789554932271130383,-0.1404521280552309125955190438617137260735,0.1436038308370825578030860469880281016231,0.02193549939190580708170408286150632193312,0.007296234606464271563175394419431540882215,-0.2324372532710349548157324761632480658591,-0.04004676756833264184010090502852108329535,0.155295506619978956885930188036581967026,0.02414722525729017660323094673913146834821,-0.1204466244993259577134026017120049800724,-0.08801931500516778361653535966979688964784,-0.02091792338940943324354648780172283295542,-0.1850340764847665242509577865348546765745,-0.1360927177524654807516668597600073553622,-0.09951962421269669456513895511307055130601,0.2006081537205588460892613511532545089722,0.07805431883362790035363332208362407982349,-0.215294439046689267680534385362989269197,0.1136260475256285762402086447764304466546,-0.2007668231537269032394021905929548665881,-0.1130566066151814236251382794762321282178,0.1476223963241491410336436729267006739974,-0.002472376097467385812345153084379489882849,-0.05949053348646756583795180972629168536514,-0.1594128081359218462864646426169201731682,0.133853357903457315103423752589151263237,-0.05784422887878646474257848808520066086203,0.03135439319863549123557078246449236758053,0.04965876385670775494673989669536240398884,-0.06861980583882966444608797473847516812384,-0.1573716335663278287348987305449554696679,0.01041908779727797329517358093653456307948,0.06989717428937275434108755689521785825491,-0.1616772037594427779971795189339900389314,-0.1000542218528472637739668016365612857044,0.02077549763188493020527047860923630651087,0.142335759587633975398190955274912994355,0.1233314979055561144694053155035362578928,0.08455351204121405728209026619879296049476,0.0345700641806426928193118897070235107094,0.07233787886122750032669159736542496830225,0.2383120216903666932495298169669695198536,-0.1401618899341287305393422002453007735312,-0.177891033619769434181989709031768143177,0.001146938428910694194803876477806170441909,0.09522865445457673327922520911670289933681,0.1362477363752194470247758317782427184284,0.06353298524473117991906434554039151407778,-0.003866939964434534197229575980259141942952,-0.188628973072998612492412462415813934058,0.03163857409393988628920624250895343720913,-0.1837847239643717600632299991048057563603,-0.09062119800804646629899252729956060647964,-0.002031454802416396594744174564084460143931,0.1922468323812158708108199789421632885933,-0.02722790311373757959900743230718944687396,-0.1333954212737245847986145008690073154867,0.1498978434934080394835831384625635109842,0.1992208284226932857308156599174253642559,0.07423722343278355007001323428994510322809,0.04036276478862732552954639686504378914833,-0.1595450296879374341152413308009272441268,-0.1254728444074502402560966629607719369233,0.09784437771154504137616214620720711536705,-0.0820343045831670586442996295772900339216,0.02913391229207291585612260575999243883416,-0.03030807204802794460607451298983505694196,-0.002415290091057805451496554027812635467853,0.2039717949423692777699557154846843332052,-0.04757323635807978595702039115167281124741,-0.212103919407531593677163073152769356966,0.0822867452996637188666895212918461766094,0.2328301022669065079018224651008495129645,-0.05364066442343626284205981846753275021911,0.02358890316014049942650032676283444743603,-0.1553212765651586224624480792044778354466,-0.09562115323277431411241877867723815143108,0.2237201465948006617878718316205777227879,0.09788990033844245652883131469934596680105,-0.2000670837055416040328736926312558352947,-0.1674672473500764535714324665605090558529,0.1135997706289926661993305856412916909903,0.09974892844215869913693239823260228149593,-0.01513592778363182303480449775179295102134,-0.1726987182579016455452602940567885525525,-0.0886596967084883613718915285062394104898,-0.09954718493834402437414610176347196102142,-0.03957594913628553062734383161114237736911,-0.04918038575320154981440623487287666648626,-0.07286854784278196106583891378249973058701,0.1058857896835450063122152641881257295609,-0.008024206300980005548972862072787393117324,-0.2307846989353488920126977745894691906869,0.05517130868288778328123456162757065612823,0.09362516968944352424575328086575609631836]
    let IW_r6:  [CGFloat] = [0.154896274815883416842154929327080026269,0.1278999491646894970386938439332880079746,-0.2410915882119815945028307169195613823831,0.04255545763953734461626510210408014245331,-0.01621386615877214859571253668946155812591,-0.03237798992058350810996358859483734704554,0.006923144587438229136111544903542380779982,-0.05032987730300477607903175680803542491049,0.03097971309843311482623562369553837925196,-0.007524281134807743812165092833765811519697,-0.08657053935131821253978756658398197032511,0.02568248396960292473378828503882687073201,0.2211961696603132188077012187932268716395,-0.1063692570777614587740345086785964667797,-0.1477630352329782348341780107148224487901,0.01546746378412653354084138612734022899531,-0.2038051088653405895634307398722739890218,-0.09324216170357962907289106624375563114882,-0.01358280112716658480365161665304185589775,-0.1622871132722023546079981315415352582932,0.07745550516225184478624754547126940451562,-0.1654458959430347708696729114308254793286,-0.1156416143190070328072849292766477447003,-0.1217990753932689934613264881591021548957,0.0301658449553308949386831727679236792028,-0.005675275891911758449626113076647015986964,-0.05236488423803325326089108671112626325339,-0.1787013208117422535803342498184065334499,-0.2109554423569043046793325402177288196981,0.01577273061818066854367081930377025855705,-0.1693042281859313546998890842587570659816,-0.1282737949356419215884983486830606125295,0.1217443846246227118212956952447711955756,0.07758919880212056252588581628515385091305,-0.1953393989963067567394716661510756239295,-0.2055919657754835261354031672453857026994,-0.2128187831814556951748329538531834259629,0.2097204416530364379234185889799846336246,-0.1972994110418083979485714962720521725714,-0.09761792836003663209609726436610799282789,0.1554176755453575420329315193157526664436,-0.1248595878294373739958444957665051333606,-0.005626573953016408141669657538841420318931,-0.1071378806856636139999139345491130370647,-0.1778894248159181568080811075560632161796,-0.05655563588960081655709899450812372379005,-0.02298671786380421938611462451262923423201,0.09235418442222310952960384611287736333907,-0.1296707521548129682376071514227078296244,-0.1497762853171165364773997907832381315529,0.1701505396353755750205039021238917484879,0.20429065230579837586510905111936153844,-0.05054174566890795583518070088757667690516,0.1113610465864872667296481267840135842562,0.1241071201929825201792922939603158738464,0.1458925878921062124771168555525946430862,0.01483505423679090662325563698686892166734,-0.07149886791812534725387706657784292474389,-0.1158544109957132112187494499266904313117,0.07981211126960938151420066333230352029204,-0.1400260735370261189203233698208350688219,-0.1198853831812807801959763764898525550961,-0.09525593292327359795645946860531694255769,0.2036876852418676997480417867336655035615,-0.08833254601747586587379146294551901519299,0.102567946027952355825263452970830257982,0.1247699078715178572229760334266757126898,-0.05386797786797734716168761792687291745096,0.05710613786554104287507271919821505434811,0.1656247904303287943328371056850301101804,0.1105322919576579854261666469028568826616,-0.1511339747370338271181822165090125054121,-0.1094082760969550399687832964445988181978,0.1018520089733077338411959544828278012574,0.1051818467603706924728967919691058341414,-0.1216378438144180978985886554255557712168,0.0429752998662075169633567384153138846159,-0.1691097977974995170136196520616067573428,-0.002524424644417588240591365789100564143155,-0.004932280817379295148605855558798793936148,0.07757476158545507927133400016828090883791,-0.06135784968347777340591520101042988244444,-0.119014345083390940538414781713072443381,-0.1376521353210110876208460695124813355505,0.1936498505379559975647651981489616446197,0.2110059690513893249086407877257443033159,-0.08062600474691050678188730671536177396774,0.04811124296230673280660994350910186767578,-0.1986156168376186637036795445965253748,0.05933005499516175174079535281634889543056,0.009669043759102231155866391532072157133371,-0.09037713022952945096655241741245845332742,0.098082000532256713443146622921631205827,0.1468998493060217902517194943357026204467,-0.08642190645291628059432298414321849122643,0.1482646732605235884161487547316937707365,-0.1866188786387828479895745203975820913911,-0.1341232418099571888081555925964494235814,0.03078675826529313555579570049758331151679,0.007201049009145493555450467937362191150896,-0.007283411558642071022273700720006672781892,0.1957433439081864290365331271459581330419,0.1622827915992973712988600709650199860334,-0.2088140460815102739111637220048578456044,0.1117056977505416770490853650699136778712,0.2239770391836936047624817547330167144537,-0.2183674506143254978596246473898645490408,0.1398194915238533120316333224764093756676,0.1098280155354502546360961900973052252084,-0.07840899408396664882481275071768322959542,-0.03169385985382342646454745249684492591769,-0.1669425500859569866385356817772844806314,-0.2134628474907709905217245704989181831479,-0.09864840021304425998760478933036210946739,-0.1438612086689720903631695136937196366489,0.04307750796386684843941594635907677002251,-0.2011994160325260572186323315690970048308,0.06829197161554001471728270189487375319004,-0.2176735572854223144112495447188848629594,0.1329564782346738804896801866561872884631]
    let IW_r7:  [CGFloat] = [-0.1173467738651258335247362651898583862931,-0.03647573311751853286644120544224279001355,-0.2368651966904019023907324026367859914899,0.1859363026533993323852200774126686155796,-0.0288642628986188060080664286033425014466,-0.248125167661565060317485631458112038672,0.1097319442864920502334058483029366470873,-0.2137485815008523248881289191558607853949,-0.09609840806400075929882831360373529605567,0.1635119450901038606893678206688491627574,-0.08535723633303753110634914946786011569202,0.07494741070647936709292480372823774814606,-0.1285636122395461267142735550805809907615,-0.18055252143921085572486617820686660707,-0.08117411787183202720452612766166566871107,-0.01719449808906726648305429705487767932937,-0.07370325750662289066017507366268546320498,0.1369907879346381196494775167593616060913,0.1779623179310312330869692232226952910423,0.1275240292112962414705634728306904435158,-0.01076660616369374406930958798511710483581,0.1067883464430663953415034939098404720426,0.1385108440544263463944929526405758224428,0.2262770664429166744824328816321212798357,0.2080700818921435157893284895180840976536,0.1061594622407761590032748699741205200553,0.09451907125954461807992856847704388201237,0.1289346886186043261712796947904280386865,-0.2286780943213729822005575442744884639978,-0.1499884814528009702172539618914015591145,0.03494010047624643289232437837199540808797,-0.1704020583968501589833266507412190549076,0.1261281727093650495419296930776908993721,-0.09057506967190934177303063279396155849099,-0.01960925809413426382232792377635632874444,-0.0201812588037543795549400016398067236878,-0.008251114479007422633505264286668534623459,-0.09364428767395208130785988487332360818982,0.09323878702410903773767358870827592909336,-0.101323570714505387102555289402516791597,0.1637783723953636916270681922469520941377,0.06539538391274242468131916439233464188874,0.07252897866809927818199099647245020605624,0.2110508729160870955432471873791655525565,-0.1861874649873918319276100419301656074822,0.1791088238878391913910803623366518877447,0.02225695366398760741133422413895459612831,-0.1962963927951356379875136326518259011209,0.2267618401725609023067420366714941337705,0.03695357372601155293567742887717031408101,0.04285348106704762322083368530911684501916,0.07320015585018574411080294339626561850309,0.1997651225714340283978742718318244442344,0.1207816074069311962357886613972368650138,-0.2080296705772302634507298080279724672437,-0.02301135791074072206585654498667281586677,0.1472493431791346008008503076780471019447,-0.09293720017812812095314711768878623843193,0.02470521231292726466177711586169607471675,0.1822848833830497394803416000286233611405,0.1115557874383122788364275379535683896393,0.1059527994287104563086998609833244699985,-0.2134862468951959357799097460883785970509,0.1493215893805537874960975841531762853265,0.1890169365843044069208644941681995987892,0.0840969724351992020672241778811439871788,0.1864421459880511999784857835038565099239,0.1025423498123627652489631145726889371872,-0.01611006713881674504151853000166738638654,-0.1166276451614828985059446608829603064805,-0.07018311824797254794283674073085421696305,-0.03130358243140097390666554133531462866813,0.03691326485175542432282114191366417799145,0.03279974609170553667691905275205499492586,0.1414805817988651348571238486329093575478,0.1651015355103503667866249315920867957175,-0.08095227164656207397008813586580799892545,-0.177880058375109145751835626469983253628,0.2428768518352294458750861849694047123194,-0.2022612412060990350060052378466934897006,0.1700418807955240974028043865473591722548,-0.06991012407561535135780417249407037161291,0.1100295001077430945279900242894655093551,0.01358683458330842488970269243964139604941,-0.05999787979743700927492966457066358998418,0.05239555185995010966326645984736387617886,-0.1757220663270134264344335406349273398519,-0.1673910765272264011827019203337840735912,0.07510216275619190084977816468381206505001,0.1301454980409968709142987108862143941224,-0.06789982620889178921430584523477591574192,0.2304207812327640214622448411319055594504,0.08526630400245348295751313116852543316782,-0.0001597706450939996721764130294118899655587,0.053311348487001988805111807323555694893,0.01881312863738918844669356644772051367909,-0.08318195046015268434569378541709738783538,0.2117795371171401486165564165276009589434,0.09300594820536348117379077393707120791078,-0.1849047220018264214846936965841450728476,-0.07157297950936476749195236379819107241929,0.2027336727138382421742335282033309340477,-0.06663924347520654156706854109870619140565,-0.07128741837642271761410484032239764928818,-0.1887468320158394996521877828854485414922,0.2384728860778895787042586107418173924088,-0.0142259938304308691803257147512340452522,0.1400300547197083633754743914323626086116,0.04455187428762242413116112516036082524806,-0.1865072539170454790635744757310021668673,0.05050332919469029124837078370546805672348,-0.1718361344862490147633593551290687173605,-9.953631286216120359344738943718766677193e-05,0.08437250761167955359631775991147151216865,0.003217701509318702125100886135555811051745,-0.1674821543313902705296669637391460128129,-0.0235571845399347376548426780118461465463,-0.01665595442457275254799498043212224729359,-0.09743807944319941849453670101866009645164,0.04065921632299317883818545737995009403676]
    let IW_r8:  [CGFloat] = [0.315814753017812588353763203485868871212,0.03041647858832014286734057861849578330293,-0.114445752680599421857721154083264991641,0.09177615604389605108437422131828498095274,-0.08470728800781782141804399088869104161859,0.2207462503099034689668656028516124933958,-0.116795015751325628738932493888569297269,0.1599894889479216153471696770793641917408,-0.03258532966373122591319244634178176056594,0.1967161644473230108776107272205990739167,0.04764451422987340395431843376172764692456,-0.03400327521551877590910706317117728758603,0.1199039783645662882172189256380079314113,-0.08199763732330109244905713694606674835086,-0.01734811191009320505140856027992413146421,-0.006794388144029559276071417173170630121604,-0.1440220424106656571527906862684176303446,0.2356736026309263209999045329823275096714,-0.05158429661478407257657607942746835760772,-0.1920196917597299657298748343237093649805,0.02009583413667821727432993839101982302964,0.09196887127013937679453903228932176716626,-0.1080028873751315426909869188420998398215,-0.09201968654230681388117574215357308275998,-0.1620657536768399520354932974441908299923,0.2165116426569315688510641848552040755749,-0.004588343154702324670768387449015790480189,0.0008863391078058507118603293051251057477202,-0.0676039135357965198513952032044471707195,0.1485749720792071681962909224239410832524,0.1068106202396804232934712786118325311691,-0.05599133732278112340896569776305113919079,0.0838234299357704659705348149145720526576,-0.05442406905810002332168906491460802499205,-0.07194111138880983358223630830252659507096,-0.06959792736599684781495511742832604795694,0.1779484544164222914464090763431158848107,0.1920470569120285297959327408534591086209,0.1385916539631474597715765639804885722697,0.210888208206957250556712324396357871592,-0.1704546274291498797470723047808860428631,-0.1488920788148488660862511778759653680027,0.1760387613329834344266799917022581212223,-0.1642448677321129424377943450963357463479,-0.04955173732713375606140360218887508381158,-0.2261056816032383787185011669862433336675,-0.1961491502560607225191802172048483043909,0.2326208972930428053871310112299397587776,0.2211866662452107445968607635222724638879,-0.2321755706749932257615398611960699781775,-0.09768430044067738515778387409227434545755,0.09988558341203272739061702623075689189136,0.04084538168378811645586878853464440908283,0.07832947375122337185793242042564088478684,0.04937877767481042151631598358108021784574,-0.134303924827404053132795525016263127327,-0.04596922183479521667459621880880149547011,-0.09280314272728848457028050233930116519332,-0.1589017760254426425703400127531494945288,0.04102574479730127648968718290234392043203,-0.1369876759567340285261849430753500200808,-0.03448166491174647907413941538834478706121,-0.1382641380165909039678950875895679928362,-0.179882063647866546896025852220191154629,0.008548538114721133257534191329796158242971,-0.1995888110829718287142497956665465608239,0.05871259788562605691497608972895250190049,0.04334821857267578959493903312250040471554,0.02341542871449219312407485915628058137372,9.060299132898977370054183211323106661439e-05,0.2302583630829481142754389111360069364309,0.05957215538391791992411938849727448541671,0.1258887794770790213849664951339946128428,0.1660573299065820629394352181407157331705,-0.02136053920984083351330973243875632761046,0.203103459759139265417005049130239058286,0.1755970943492106139949271437217248603702,-0.1637463955433412221562861077472916804254,0.202621986423927702425373809091979637742,0.1103939338663717656396912047966907266527,-0.09793216806095578208513074969232548028231,-0.1842983964272773278469941260482301004231,-0.06106398019244233671409816111008694861084,-0.06792562592908669982794123143321485258639,0.1911038405241472226681054280561511404812,0.1376216543446625029112340143910842016339,0.02157519153760694211041659684724436374381,0.03874014897513377436721881963421765249223,-0.1465898984390414661049817368621006608009,0.06090861398734401244148273235623491927981,-0.05868122414871029118854650619141466449946,-0.07509114464025981594552661135821836069226,-0.1156682165499809122888308365872944705188,-0.1025625073739727111110653368086786940694,0.2146122689491460344690665351663483306766,-0.09034473389300856638328696135431528091431,0.1106354558538424487368345694449089933187,-0.1824020350883553409637727327208267524838,-0.07272605420939413922720717664560652337968,0.002799529398663600215230173873237617954146,0.0837591499427646213327136592852184548974,0.02476830202354832546896012956949562067166,-0.06763904253170469060840730435302248224616,-0.09463256090972933798344257638746057637036,0.002704062590154948479692631480020281742327,0.1694459293195707538792760260548675432801,0.2023075737042008270805126812774688005447,-0.1516373111025547670838165004170150496066,-0.08295418329216880382048771025438327342272,0.004975895417448884631983485604678207891993,-0.1648441490395563258086752966846688650548,-0.005416471519197370819431736066462690359913,0.1912107379898603520818056722418987192214,-0.004216241050892265140870307504883385263383,0.07239591347199481052854252993711270391941,0.1679739035155821680334042866888921707869,-0.1207360767268172707655793374215136282146,0.05289735183460494982732313928863732144237,0.1195156715630977251052513565809931606054,0.1370816516328730305662730870608356781304]
    let IW_r9:  [CGFloat] = [-0.05209097092215972391038292244047624990344,0.0429592879508457689552436420399317285046,-0.0736764329662393246955787162733031436801,0.000388953617670961078120472897978743276326,0.06594874013640232568445043170868302695453,-0.002509376577899080813793819544343932648189,0.1756282773249779327606745482626138255,0.09233127965840923212503810191265074536204,-0.01325041540176614789092734980613386142068,0.001529370858121111443478357116987353947479,0.1490864462618402552784857562073739245534,-0.1826627737288596953213470897026127204299,-0.1144094783892765920807477186826872639358,0.1220271649383116024933926269113726448268,-0.09369724484845456946580100066057639196515,0.1310274846232913625865279527715756557882,-0.08315529128570164907330308778909966349602,0.1754719173163240275581387095371610485017,-0.2266225747124255285314120555995032191277,-0.2174359321843065129264971346856327727437,-0.1092958820387233548343530742386064957827,-0.09753706413466912972243250123938196338713,0.04755524707588616728504149477885221131146,0.04625628742861984110668061020987806841731,-0.1727672560466992357497417742706602439284,-0.1774933367266404438122862075033481232822,-0.1457340054652773719823244391591288149357,-0.2079724613453828307996218427433632314205,0.0297238354201709992219448963624017778784,0.1737377707789515557390558342376607470214,0.05812075179849329753523079489241354167461,0.1893223624169100838265933361981296911836,0.1788110126491172791052264301470131613314,-0.1306852401276633046656172609800705686212,-0.1048783350687313292715074908301176037639,-0.02196114197255437383571319287511869333684,-0.1024966998596125861142880353327200282365,0.1194126357474608463027365701236703898758,-0.08698179377824991065359938602341571822762,0.08753263653424224466359504503998323343694,-0.055317815554647264963961106332135386765,0.2108156488971727193781902087721391580999,0.03997571044032010439961410952491860371083,0.0845092830471425859872880437251296825707,-0.229273751921259510977435525092005264014,-0.002452631814676396911079070406458413344808,-0.2135244749801882835349431388749508187175,-0.03880283687582179730224396507765050046146,0.1752777941875824363471281230886233970523,-0.1661111627691541081652815137204015627503,-0.0624175752515747639392884593689814209938,-0.02323324109311706783809192700118728680536,0.200030322369744634203314603837497998029,0.03535012140358133325701572857724386267364,-0.171943725658707968761973461369052529335,0.1374960509299132938032528272742638364434,-0.1959791573168887524047931947279721498489,-0.1417917378255577065537806902284501120448,0.164933893879554566153089467661629896611,-0.2120030765280802032002327450754819437861,-0.07931160923782248906022118717373814433813,0.056570584053768011023599626696523046121,0.1981714477818983799473073759145336225629,0.2275332554098388471164327029327978380024,-0.07705071849458786092945672407950041815639,0.2383163824863744062465542583595379255712,-0.1872407780212994032886797413084423169494,0.05875483800080728846726429992486373521388,-0.02028125102732365389601731919810845283791,0.03196942458162001926558204445427691098303,-0.1354914768922698409259197660503559745848,0.1329479934623815085004139291413594037294,0.02356044600562032589885497202430997276679,-0.1720195721547051748157031170194386504591,-0.1758597441833522068144191052851965650916,-0.09167709859087710966285555969079723581672,0.1735479549503613772021282102286932058632,0.102113878930576065795499118848965736106,-0.03864667336899419575191316766904492396861,-0.2002899691805418713741460123856086283922,0.05860033097768787418990754645164997782558,-0.04273380080529337599060113461746368557215,0.02202226191050110984392951252175407717004,-0.1209068616171685428550830465610488317907,0.2318091886975802151660275285394163802266,-0.0870314095764931350274196120153646916151,-0.06303170600655177979732002313539851456881,0.03228872863946182641958770886958518531173,-0.05835657942920811913634082657154067419469,0.1536220414983285043053484741903957910836,-0.05109362568805515814052142786749755032361,-0.01220573527557352981609550823804966057651,0.1812259164682840095750293585297185927629,0.1001775796187682893156889463170955423266,-0.04449078674023133894710468894118093885481,0.09402121771191980503790119882978615351021,0.06362826347326759612865743065412971191108,-0.180205063516235802767440077332139480859,0.1969967900912227287690825505706015974283,-0.09652181594683723053762491872475948184729,0.03323550878732042801466661785525502637029,-0.02660684032305178289834479699038638500497,0.02969354348738647425554049164020398166031,-0.1376635608567479407415845571449608542025,-0.1383719007115456200995851077095721848309,-0.02555081493700885747477613563205522950739,0.1193885399907302774513695453606487717479,0.08021432105143753987785970593904494307935,-0.03340876130209599614850901616591727361083,-0.0485253479199510076580459383421839447692,0.1682148566007245216180621127932681702077,-0.2360768322174762179344043033779598772526,-0.2366687714537820119709010668884729966521,-0.1672163527687144379818562356376787647605,-0.2360140654244099744918372607571654953063,0.1292564237157288464796778271193034015596,-0.1094374269840450719648572430742206051946,-0.1988654503592336142414609412298887036741,0.0826981944721799089315084074769401922822,0.06205018566256388645729913378090714104474]
    let IW_r10:  [CGFloat] = [0.1856150070641786331560041389820980839431,-0.01087559546988521586019516007581842131913,-0.1839109318247317548244978979710140265524,0.1682957572735638285266190905531402677298,-0.08577431913914117245223422969502280466259,0.1975666358594871940823622935567982494831,-0.01778713285453602244157167433513677679002,-0.01187077947278940281972126058462890796363,-0.1935756234151825849743033813865622505546,-0.171939591345301068248119236159254796803,-0.04167826858832895942086338436638470739126,-0.06592870475419014553164487324465881101787,-0.1572438060391414260674736169676179997623,-0.2127140553053444016473605415740166790783,-0.1926642118335757936087304642569506540895,-0.02633507315166319986965426380720600718632,0.07565589500228576957940873626284883357584,-0.1845374657505070847829387048477656207979,0.1900832587750155289185727269796188920736,-0.1007749342246148926971471837532590143383,-0.1723174744212410680610503277421230450273,0.1206501642213156921812355903966818004847,0.1724641929309199128717011717526474967599,0.06254940241891969454623989577157772146165,0.1276665996434135086357031241277582012117,-0.1624582310683797270467465523324790410697,-0.1444789136390561556932965459054685197771,-0.1615908069847277195307810870872344821692,0.08242301347431857383440956255071796476841,0.1718439637501467665003929141676053404808,-0.1379035135145253998523173777357442304492,0.1223500904263665756133150352980010211468,-0.1737041902746008503743979645150830037892,0.1178960647612889156565785242491983808577,0.03502492712463048385451713784277671948075,0.1514170188013080065037030408348073251545,0.17898800413773877093781550229323329404,-0.194992182511194378502494828353519551456,-0.09071220811184083077094442160159815102816,-0.1013960224270572252347477615330717526376,0.1064125296604486181628601570992032065988,0.2061551750149663575495395662073860876262,0.005682889565459340805442245425638247979805,-0.1962500873995912942238106779768713749945,-0.1324010576082486900784118688534363172948,0.1110128800631522694164488029855419881642,-0.03717124216027765243319791466092283371836,0.05377790537299564910256322036730125546455,0.06723679719010114408384026774001540616155,0.01995406470614291202791967805296735605225,-0.0253697722407507826603012546229365398176,0.2183101982991023648494888220739085227251,0.03685648949697618859122627554825157858431,0.1905573479369190026400104898129939101636,0.1921584091718015474548053589387563988566,0.05284476512846180557003705757779243867844,0.08332081404179450534464024258340941742063,-0.0399390585481599960648857461364968912676,0.09213127837641676975977134134154766798019,-0.004378828793740327345040963535893752123229,-0.2122657480337468427489255873297224752605,-0.07165834148074852472110052303833072073758,-0.04691870745992187535788886521004315000027,0.03775389704875227459002218211026047356427,-0.04508244007995500929331100792296638246626,-0.08798650137960820072358103516307892277837,0.1957284559228499865035644234012579545379,-0.05564726268920154594876947840020875446498,0.1421030535003012518213694193036644719541,-0.1639126343538539753996730041762930341065,-0.1221774927608203498152761312667280435562,-0.01800413858463921490393744306857115589082,-0.2041809738620079528459427820052951574326,0.1382892529408014381520075630760402418673,0.1339896257484629593648151058005169034004,0.001002049545385904922439879172202381596435,-0.08342197105051091243765881699800956994295,0.06108488238291437388838289734849240630865,-0.0289474265879816720914430305811038124375,-0.1677259929806272087393637093555298633873,-0.0802625929767009776982789048815902788192,-0.1674424312645625967377327469876036047935,0.04398349798182652620193167081197316292673,0.1063059340086685150561507384736614767462,-0.1178933591250978379916247718028898816556,0.1588943662678591606240985356635064817965,0.2159231675214585977062853316965629346669,-0.1570907891965618863316933584428625181317,0.07059251625044798972297144246113020926714,0.2232178717412318658119829706265591084957,0.1477352924200253936337645654930383898318,-0.02040759893547548428638371831311815185472,0.1512372380112560199538762617521570064127,0.1436533739420355337834678266517585143447,-0.07798709005258525062131980121193919330835,-0.188621022662423254434571617821347899735,-0.06810931468448627734701972258335445076227,0.05429167939360497047163178763184987474233,0.1054082289333819061338815004091884475201,-0.02564609158036638275612872917008644435555,0.0497733119250809638578481042259227251634,0.201316572778770463969522097613662481308,0.1571951018207149441963110803044401109219,0.188476689433106053828126391636033076793,-0.07122842620624843246179835887232911773026,-0.01265423286774866942772099775993410730734,0.1281606657597788301305996583323576487601,0.1800314334045438890985479929440771229565,-0.2087705164568120497214920305850682780147,0.06928134615641924620721425753799849189818,0.08646120454187157522429885148085304535925,-0.01180777175650508936666227555178920738399,0.1556747933591269561492964612625655718148,-0.125567669386957042609864743099024053663,0.05770254750910253777052005830228154081851,0.02822557249708259469178628364716132637113,-0.02906266710731895616670605875242472393438,-0.1253140468535908769176501209585694596171,0.220452676739886777035337672714376822114,0.1876812249997868164985703742786427028477]
    let IW_r11:  [CGFloat] = [0.1728404290859508474209604855786892585456,0.01140392436289094577062108726295264204964,-0.02568034044016254818787459157647390384227,0.1036616069994327066217110200341267045587,0.09041658092782994815550523526326287537813,-0.1885098519596436483780621529149357229471,0.1605080489984898328703621928070788271725,0.2398968401524905202926163383381208404899,-0.09589714625500017630699289838958065956831,0.1246812736222288886533959839653107337654,-0.0724113233067663897291055263849557377398,-0.2125722059808070052433492946875048801303,-0.03040651743349759641987795077966438839212,-0.1967919275847712368143760386374196968973,0.1226866699474151167770230586029356345534,-0.04918039264524962095315174792631296440959,-0.0861898957077941452187275217511341907084,0.02063035593177782803242514830799336778,-0.001929267237041990337709229663687438005581,-0.1457736798790367771516685024835169315338,-0.06840626575255054353519312826392706483603,0.1068367536280716567631543512106873095036,0.127759327764075392153131360828410834074,-0.01438170622829183092905580565457057673484,-0.2408899211597901601766835710805025883019,-0.04869081115194290321213088645890820771456,-0.09662186033421928110787035848261439241469,-0.05744450786719906831834236982103902846575,0.0592926927119703170432352123953023692593,0.172255105176448236603548025414056610316,0.004086754522724615062978514856695255730301,-0.04994796584596930544286408348853001371026,-0.06035838225551691527126507708089775405824,-0.1147514766262387186923632498292136006057,0.07245350592135220424427899388319929130375,-0.1619997477782995909389995858873589895666,-0.05969358494423997185673869125821511261165,0.006612804125391648357723539675134816206992,-0.03608332417750974296932753304645302705467,-0.1934435771549008475922448724304558709264,0.1414009432066871407851493813723209314048,-0.1567587737028624528257125803065719082952,0.1169275965346883994211424351306050084531,0.2483331699956997096201405383908422663808,0.180155103569454022593987474465393461287,-0.06008762952956741426602249589450366329402,-0.190346504231583418809137242533324752003,-0.0780049508650748207871927775158837903291,-0.2435865274758742260452493155753472819924,0.1037696465926196548457127732945082243532,-0.1725747484034551026965687015035655349493,-0.01494217354295472414971168717556793126278,0.01958346789880873253797410882270924048498,0.0702886537437099195857470590453885961324,-0.1489690336927504688002699140270124189556,-0.1361760868211170927288833354396047070622,-0.01233188996787834730561872476073403959163,-0.2023547377373171862746659144249861128628,0.05038869139999693769205180160497548058629,0.005735736439102546817270233958652170258574,0.2192501279288212034934701932797906920314,0.005973666903849725838548945233696940704249,-0.1595270588732585759217386112140957266092,-0.0154097034134699096413756436163566831965,0.07638883785682172578024307085797772742808,0.1542894026850801236783183867373736575246,-0.1101962708558739539865811707386455964297,-0.2090740894087961265768171870149672031403,0.08091206352197170825757410739242914132774,-0.1211704557758228328889771319154533557594,0.151247776761302299419753580878023058176,-0.003484436165779522098090437154382925655227,-0.1200722394875221449295210618402052205056,-0.06261938076142258002843021813532686792314,0.2336875813819536407134336286617326550186,-0.03595228116322286143757835930045985151082,0.1631218305619875352796555034728953614831,0.2349784345695154486044486930040875449777,-0.1953219888957435368403992015373660251498,-0.1746058455903705119993674088618718087673,-0.1753824754819814368822505912248743698001,0.1857608552372120858109383334522135555744,-0.1119298349531215874819167765963356941938,-0.06457695314434051814256321222273982129991,0.07958834970064175562409758413195959292352,-0.2428554969380982697657600510865449905396,0.1555812162855876312761438384768553078175,0.05369145127361909380914184453104098793119,0.1203375632815906620676216220999776851386,-0.1901124255898805071041124392650090157986,0.1566237511777048840855286471196450293064,0.1133407870247902793359173756471136584878,0.2362078633326577248308097978224395774305,0.2474452834480556917551297146928845904768,0.1291629684664601096510949673756840638816,-0.127889451511351476264977122809796128422,-0.001004685098234111770287846354676730697975,-0.00724270149737836922004818873688236635644,-0.07030146586587332491191659755713772028685,0.2134687776938273273685808817390352487564,-0.1273028941032565974911250350487534888089,-0.190413872017303198447280010441318154335,-0.1685609352942521177443069291257415898144,0.01948679274701158384286436842103285016492,-0.08644928211484191604707660872009000740945,-0.03309613875472847133174525424692546948791,0.04204146581423966883006571038094989489764,-0.005970598087298007936030153075535054085776,-0.1093127730352943111080676885649154428393,0.07835921873159766570804407592731877230108,-0.05141848145998102748155389463136089034379,-0.02929879292183599354126855018876085523516,0.1340657263073084526361355983681278303266,-0.04117433498093898275316249169009097386152,-0.1092372241863296955521889231022214516997,0.1776516791500595271457996204844675958157,0.1155456549645483971255899291463720146567,-0.09056491670136003480084951888784416951239,-0.002351167511708870516001779193970833148342,0.08754196243488886197692266932790516875684]
    let IW_r12:  [CGFloat] = [-0.04600250562214223265522505812441522721201,-0.18800112447932226800162425206508487463,-0.06258661564278565625496497659696615301073,-0.166622817043841769946155295656353700906,-0.03404057985205974357079128367331577464938,-0.1671872785041870479449954700612579472363,-0.2021427773272541639215660325135104358196,0.1603651867501250660730249819607706740499,-0.1653292028857933637642219082408701069653,0.1030547794621481383359196115634404122829,-0.112724570828251671739117512061056913808,0.1682537084404510940860433265697793103755,0.09596922167234760159271189650098676793277,-0.1137314096380602906899426329800917301327,-0.06168438359868963494214710863161599263549,0.1414530497400311170874687149989767931402,-0.1315563565737297435642716436632326804101,0.06821205768647149725314449142388184554875,0.1814309600094076158072198268200736492872,-0.04139423670939907512478228568397753406316,-0.01413682833482468592656289274600567296147,-0.1706240689148915967709996266421512700617,0.1553825838606397169439077288188855163753,0.04871169650992412253343033512464899104089,-0.1871293948810413831917998095377697609365,-0.1938363211251405149315729659065254963934,-0.08978721173958829904204748117990675382316,-0.1966729525177426940452107828605221584439,0.1552209336345153622982451224743272177875,-0.1312679839186460251099219931347761303186,0.1904541450407354619134281392689445056021,-0.09722207085420810079856579477564082480967,0.09080017570937559678867501133936457335949,0.1214732170740470407199751434745849110186,-0.188106050211885394984889785519044380635,-0.09658204670493922283647236781689571216702,-0.03120689152580669728509477067746047396213,0.04501102761025804754879686697677243500948,0.1919312362524052961720855137173202820122,-0.09510897805553637784914400299385306425393,-0.1818876744430776015715167659436701796949,-0.1461469425519772158406084372472832910717,-0.1732277774598216246726423150903428904712,0.0206042567531158002380742289005866041407,0.2043502162573332392447866823204094544053,-0.09160811947581005976193324613632285036147,0.07600051039152876108939693722277297638357,-0.1996074518325323399192683382352697663009,-0.08697545110144327962231614037591498345137,-0.007038501354886498619090051676039365702309,0.05242938229584973020003246801934437826276,0.2047128603863946072483059879232314415276,-0.07146853830062294132829947557183913886547,-0.1100774139636844783929348068340914323926,-0.03518190813519393028707682447020488325506,-0.1967965333692301976853400446998421102762,0.1859191078009754249933394021354615688324,0.0169954792508158342156932008037983905524,-0.04640877439504193652242136636232316959649,-0.1407773716592663759694659120214055292308,-0.006632006445400132760292777334143465850502,0.1514622439372023399162259238437400199473,0.1069815283862355220767526020608784165233,-0.1153852845257150733226936267783457878977,-0.09206541819814847982250682889571180567145,-0.1246189485574138999801618865603813901544,-0.07380799011042388224623778114619199186563,0.1872420547944088076164348422025796025991,0.2122557349134758242215070822567213326693,-0.05897488693925649616556228238550829701126,-0.04829425183581760594453413659721263684332,-0.01710668373717002740952430883680790429935,-0.06219502919775857924244988339523843023926,0.2104398300702556290353584245167439803481,0.1224664399074038845238732164943940006196,0.01915685023616070514762554921617265790701,0.03331477693701957037974992203999136108905,0.05111741424137686978790284797469212207943,0.1832259415236968669304928880592342466116,-0.01242970930624367163763732690995311713777,0.1363399107974662405329269176945672370493,-0.196298992728772825344663033320102840662,0.1918814315376945189850488304728060029447,0.1881109383176908511625669007116812281311,0.05198155564082101304235195016190118622035,0.1560169712644686457192477746502845548093,0.06555650005055298212841563554320600815117,0.1015255742008285000377298956664162687957,-0.1826020924193927363887723913649097084999,-0.1075232713317375160544386858418874908239,0.05452977071225287297728812063724035397172,0.1438229321484339184866740879442659206688,-0.131513184982569503178595482495438773185,0.04077091503145906237204343369739945046604,0.0226374259879464009848071270880609517917,-0.1413922409965285287292147131665842607617,0.09815040119643891891598741494817659258842,0.1926089112526348512410834246111335232854,-0.1362645113271937491461471836373675614595,0.1851741546500109136808021048636874184012,0.0522613936063574952006760554468201007694,0.02782082353945201924627639300524606369436,0.0568506139979580438215123194822808727622,0.1619338685768754448890405228667077608407,-0.1387263058066144361113458671752596274018,0.1716115376023235883362616505110054276884,0.2051265388726443705813551332539645954967,0.2068145769386363075348356233007507398725,-0.08026931904793667416075919618378975428641,0.04695615209286824881518285224046849180013,0.1295631984101067168957399644568795338273,0.1390182611521993683023623589178896509111,0.04959665572304091524236113741608278360218,0.1189720558842511238806238793586089741439,-0.1867559584740373090916421006113523617387,0.1319011921444945834025475051021203398705,-0.03642366007400482663669549765472766011953,0.1117164753690176037803638564582797698677,0.2040262213443575223248416250498848967254,0.1547747318231386115527925539936404675245]
    let IW_r13:  [CGFloat] = [0.08811184794522575192132762822438962757587,0.1643716734056240857952957412635441869497,-0.123414870091763273496354713643086142838,0.16693737198635266727464454561413731426,0.1852551208522117964783149091090308502316,-0.1180996411125596889934996625015628524125,-0.1535850404740368990719190378513303585351,-0.1260750935333146971473183839407283812761,-0.1685279362658717583478562573873205110431,0.1579892256164981689803283870787709020078,-0.07896343911804706849899559983896324411035,0.2057872135448004791147269543216680176556,0.1701465479909663180979606522669200785458,-0.1882328743552822147844238998004584573209,0.2050004298084686926717523647312191314995,-0.04306795089599117082324042371510586235672,0.03089205880104505322347741014255007030442,-0.137664067871493267514182434752001427114,-0.06275012888184484938225438099834718741477,0.01572999233798496460101645766371802892536,0.1821428952278907886785930259065935388207,0.1222785893474102603128983446367783471942,-0.03990145861643389774142676174051302950829,0.1795018859947585254666080345486989244819,-0.1878550056793173717029077351980959065259,-0.08004681590101386801094918155285995453596,0.03209108451200595735208764835988404229283,-0.2007960886363124308751082480739569291472,-0.1308345961062121476370379014042555354536,-0.1500156073949478752194153230448137037456,0.1348482558972300959787560259428573772311,-0.2045783178593446605120220738172065466642,-0.05916394428860988208285220935067627578974,0.09666797533886033189087783057402702979743,0.06985933659503362758158573342370800673962,-0.2134116225692963275673008638477767817676,0.06076002396940174965500602866086410358548,-0.005466736059179785889305946966487681493163,0.1681605513860282841154258903770823962986,0.06065550558429454175435324714271700941026,0.1453073651091001672330804694865946657956,-0.009701205731988567920742738692752027418464,-0.2081817215816344490697531455225544050336,-0.1926277419671773016851545889949193224311,-0.03794827352529937108949198432128468994051,0.1622093855326683653483854641308425925672,-0.1818469263605007046891159916413016617298,0.1482921929200624600042601741733960807323,-0.1990591857546165355241640781969181261957,-0.1792415223060053741654940040461951866746,-0.04231967137782591259487219303991878405213,0.177950472276377946734271517925662919879,0.2000761747649171251595134890521876513958,-0.1462125443048210571284073466813424602151,0.01768018703720045797789239827579876873642,-0.07522212984634150945151276346223312430084,-0.1525671541559186217273946795103256590664,0.01440223831798967749073803190640319371596,0.005264123337821220542653843921243606018834,0.0973302751203245636313354793855978641659,-0.1523710804126490736543075854569906368852,0.01080601214194563779169566686277903500013,-0.02480489154586406827518452189451636513695,0.1391637148708177451617018505203304812312,0.1914815614439827340387267895494005642831,-0.01391979225811766640585886989356367848814,-0.02616755968480592373093251978843909455463,0.1421317080590525638861265633750008419156,-0.03033856337345690670770359531616122694686,0.04974997372882530161097847098972124513239,-0.1380833104377713616006673191805020906031,-0.005609318856789824274400313441901744226925,0.0473140858482631876391621972288703545928,0.1611136962953098050732592128042597323656,-0.1645730846986707407442196426927694119513,0.203412329874283509534294012155442032963,0.08254825102962209948387339863984379917383,0.1152791584421835741069983782836061436683,0.05187542335240290930498119337244133930653,-0.1634119332095405052740488827112130820751,-0.1139219741049547762745675072437734343112,-0.1353031405911624962534745009179459884763,-0.03083346521495631056830610816632542992011,0.1326702571906760164122118794693960808218,0.1155589434890010314127550827834056690335,0.1530895707348819412274565365805756300688,-0.2034055788832711542113429459277540445328,0.1896240687006085223753615309760789386928,0.1866501382654532636973243597822147421539,0.05109904845028771791515254108162480406463,0.2033093928838300423755924839497311040759,-0.007890967772695612822420052623328956542537,-0.1860311624597567881078674645323189906776,0.1028951338353196326425020856731862295419,-0.09513276139198147129949489908540272153914,0.1657748427822208214799104553094366565347,0.005003038370437006172875005205469278735109,0.09564651343534805172375001802720362320542,0.006460138875180534631659234889866638695821,0.03746114907942464655743464163606404326856,-0.001414658023736907032502641001769916329067,-0.1370423421304362010531008309044409543276,-0.04652346861535040095647630664643656928092,-0.1362830535261562725501960358087671920657,-0.1273312935571248583066505943861557170749,-0.1933404349198324934100412519910605624318,0.150450422495052249516334086365532130003,0.05603683787818787565004896578102489002049,-0.1811865372646073724105519886506954208016,-0.07795852348893472782975777590763755142689,0.1275046855073039553385427780085592530668,0.02005027970725380831451545304844330530614,-0.2066576896541377494909141887546866200864,-0.004938733793470114971646545143357798224315,-0.1034641225053579000059400527788966428488,0.114978760641279001419867711319966474548,-0.1165704687509318132621061181453114841133,-0.06771131707949699929383058361054281704128,-0.1328746091041692889422876078242552466691,0.1766196778052012417159488677498302422464]
    let IW_r14:  [CGFloat] = [0.0279969753991160530404158635064959526062,0.06773977701505677628812662760537932626903,-0.06282828435987605764090346838202094659209,-0.1368306222779937242339798331158817745745,-0.00531762762226805490994863134801562409848,-0.0208086399898332156943592252673624898307,0.0007030191959576315629751319669082931795856,-0.1852171929209818213024618671624921262264,0.1752068189010676235728425353954662568867,0.1022270104140063778919156334268336649984,0.03396434675344583986600355274276807904243,-0.1491280718126921922550565113851916976273,-0.1859839170136765307272952441053348593414,-0.01618958789213840315790449153610097710043,0.2067193678860561878440904592935112304986,0.1835316724604568183742969722516136243939,0.1305410396550607254884113217485719360411,-0.02061495249521412900794992140163230942562,0.09198284953954180553914454776531783863902,0.009519941154832661095452905897218442987651,-0.1524885947096736305006459133437601849437,-0.1868464344863426940257511432719184085727,-0.09049393027674795808579233380442019551992,0.08518973870616659838095330314899911172688,0.05355954978195340970836824112666363362223,-0.06182499963677026005859360680005920585245,0.1876532970910525510710442631534533575177,0.2452579487987044948305026537127560004592,-0.1072566377511569302161120731398114003241,-0.1466415277408887885002286566304974257946,0.003288151247577251676257326096219912869856,0.1877278255341785218046624095222796313465,0.1195253845909795969992828190697764512151,-0.1593101243175230330439973158718203194439,-0.01834862300409257143685159974211273947731,0.08810350038290097607340811691756243817508,-0.07232141412755366260967093694489449262619,0.2111609448034732217092113160106237046421,-0.1473083942633774123809331513257347978652,0.03808669579634557655900550798833137378097,-0.1374666817159028164851974906923715025187,0.0009331907499558133537581605665423012396786,-0.1246897601989712250913910907001991290599,0.1343536100786690556940783380923676304519,0.2367508939191419747860578581821755506098,0.2285307658071389635967562981022638268769,0.1046540519164873839219609408246469683945,-0.2007674057769098518999584257471724413335,0.2400718702656281511309543930110521614552,-0.04277412372164211135094902260789240244776,0.1581569687918168154450171414282522164285,-0.1411489109144691000974347616647719405591,0.1936447711736570265195211959508014842868,-0.02922282798333077080688013893450261093676,-0.01966195618629315577940985804161755368114,-0.03806048023169184696401501355467189569026,-0.1962761188606974294135198988442425616086,0.02580722947578137013713295289107918506488,-0.07642767018052745719991492023837054148316,0.2100105878571620343642223360802745446563,0.1865947644959841666967292894696583971381,0.1879801083905386083205968361653503961861,0.1872272743908977854498942861027899198234,0.04671275449243410954336397367114841472358,0.1268420388411374000181552901267423294485,0.0001533704384234183958242436762731131238979,0.167999874131725929204961289542552549392,0.1797785537724737037201805378572316840291,-0.09572525377067592211588475947792176157236,0.1293815110386046796087100574368378147483,-0.02166908962225849374916286649295216193423,-0.04722756590693163308847246639743389096111,-0.1889824961619127607903578791592735797167,0.1467976514189466841209252834232756868005,-0.2092865301782590448098630986351054161787,0.1645647414466200886273838932538637891412,0.03896688612373420262935397317960450891405,-0.06108556618444617447583055991344735957682,-0.09270247385740185142033453757903771474957,0.1333345015440561276420794456498697400093,-0.1912937476303436246105604823242174461484,-0.1055954785542102813966636176701285876334,-0.1354531303621398230507821835999493487179,-0.231291841364386990820278811042953748256,-0.03924072348008263155794139720455859787762,-0.0172342741738578976440354750820915796794,-0.05253151203349079589877135276765329763293,0.1331900574745718823788109830275061540306,-0.1594689942346197708555877170510939322412,-0.1101187786776977178826442127501650247723,-0.1362443300794110023765881578583503141999,-0.1152528431112499335275956013902032282203,0.04023884940498669016140098619871423579752,-0.1432174236347616147480010795334237627685,0.04680015570542839925538558532025490421802,-0.2119365526302539048941753208055160939693,0.1473850837310959616122119086867314763367,-0.1140055671124564351526231575917336158454,-0.122431941868127072692296053446625592187,-0.06811914576924966990834064972659689374268,0.0448988109930901976851735923901287605986,-0.1764797992523892133931440184824168682098,-0.02925839462375295907392569461080711334944,-0.03954420503473075193534569393705169204623,-0.05473679876329940602319723552682262379676,-0.1704159983275128631419192970497533679008,-0.2057345308850238863040971182272187434137,0.1423717978862064081901905865379376336932,-0.01135904340127597000886794376128818839788,-0.04632646675821362747260678816019208170474,0.02369356355609487582714045572629402158782,0.06290486386329785517546042683534324169159,-0.2098417075092605110775423327140742912889,0.1716602505213472851242073602406890131533,0.009694484013647350351128295642411103472114,-0.1186377952171175503837119435956992674619,-0.05895553009938495764297172740953101310879,-0.007994296720861073651809292073266988154501,0.1439263281516684200855848985156626440585,-0.1370766434203768702193571016323403455317]
    let IW_r15:  [CGFloat] = [-0.1058999435132828431660456658391922246665,0.1494175212589452239608789341218653135002,0.1816489210484613925356001118416315875947,0.2175154860856255978340811907401075586677,0.1391868987097468757241358616738580167294,-0.1788510195433206106940815516281872987747,-0.1882638642558433494933467500231927260756,0.06998440988990431432803518418950261548162,-0.2173333027779558168646190097206272184849,-0.131783866038274327658896822867973241955,0.1588708730007760971947305961293750442564,-0.05759815192033189423792549632707959972322,0.03893639809526192735456007198990846518427,0.02550548069499997475007013747472228715196,0.1767704053759480975482887288308120332658,0.1156194999129009914895505062304437160492,0.02004045452614861347329089369395660469308,-0.1228907473339201084083782689049257896841,-0.2191483460384812675947330262715695425868,-0.1046370700314599722080544097480014897883,-0.1540916928347778880326046646587201394141,-0.03921800493197309667170458169493940658867,-0.2183323193941519302363474253070307895541,-0.1941325542962995254203661943392944522202,0.1002129218403759874922442918432352598757,0.1730321353427707875560770389711251482368,-0.1724338133988410903807420027078478597105,-0.09444025962488961090102179696259554475546,-0.01984970006761200764233699089800211368129,-0.04357399240021288949753497377059829887003,0.08604742285568869886169807159603806212544,0.06979270053201803991616003486342378892004,-0.1554004414952631085711232117319013923407,-0.1536671888175799582931801978702424094081,0.0629776994651116278634006562242575455457,0.08722609460746784393325725659451563842595,0.2044082555868852180136485685579827986658,-0.2090468873244160918911660473895608447492,-0.06893687816669707979500003602879587560892,0.1334295205442085074931668486897251568735,-0.05870970396074318142787262786441715434194,-0.1996234279107145515030907745313015766442,-0.001891215277797811140231276638701274350751,-0.2054737225637542075151742437810753472149,0.05576512181157704250988871308436500839889,0.1498634747238743736286181729155941866338,-0.1153851297746570220281725482891488354653,-0.1340408407016834835268070946767693385482,0.1116690477587541363568846009002299979329,0.06429525385005199766830230601044604554772,0.05367025368085293762776544213011220563203,-0.07297147735592258988024383370429859496653,0.00654280877691186188438443593895499361679,-0.01138052067296559978493153408862781361677,-0.09781376612745190657349780849472153931856,0.1474513254032623621458952811735798604786,0.1440484869104962095676114586240146309137,0.02279872798264833549941599244448298122734,0.1749154158210750042989900521206436678767,-0.1519110676062183362677870945844915695488,0.04119443355396828349013205183837271761149,0.1695278592620267366086750371323432773352,-0.1375316310400137020941713217325741425157,-0.07829332644214380410030429402468143962324,-0.1847970322286384414756099658916355110705,0.1928036019992986072058016588925966061652,0.03241306429462642579863995706546120345592,-0.07491965206355497008949839710112428292632,-0.1491997743288664690641809329463285394013,-0.03514023543700238449982720112529932521284,-0.01624841716277227246512104841258405940607,-0.1076501012332585632824688559594505932182,-0.07699863309353378870714124104779330082238,0.215076715591265205107518454497039783746,-0.117615724830512552445682672441762406379,0.2052096547643208479527743293147068470716,0.1806887394749751296618711648989119566977,0.1062257742860238246551674023976374883205,0.02113135624234707687918444207753054797649,0.1663820106026054623793442033274914138019,0.1370057843151653576008186519175069406629,-0.01074978486140038685947573071644001174718,-0.1338725934025310482233805942087201401591,0.1584734302983020204358410865097539499402,-0.1745104640641065574246937330826767720282,0.08884480059153708475516708631403162144125,0.1100906337226447290200681550231820438057,-0.03577466543790305819605634951585670933127,-0.2207856650385229546618148788184043951333,-0.04345259756433702408306984921182447578758,0.03570756115418627363311543376767076551914,-0.01015030420737176274081914328917264356278,-0.0274044598268853786815490991557453526184,0.08934955733401282740313575914115062914789,0.1772690097451222746016696873994078487158,0.09699417466081947103440086266346042975783,0.04841202494331864336629678291501477360725,0.07003274396483862018758514977889717556536,-0.0220289010530053987191312359072981053032,0.1379694458951211399888592268325737677515,0.1252041438746496204714730993146076798439,-0.1750237250857325232988870311601203866303,0.1506133963843735990018046777549898251891,0.1282214594529932916167069834045832976699,-0.1829069899947305954945875328121474012733,-0.1350009349500428668111595698064775206149,-0.09496664923928437029854165984943392686546,-0.1689577777188230045535277668022899888456,-0.09164676194589764512965501808139379136264,-0.1028270626407813692626547208419651724398,-0.1897288932965593699631057234000763855875,0.1549702367033525818307282406749436631799,-0.1129800018009323725465264942613430321217,-0.1131070198369032303586934062877844553441,-0.01461211248745687002470461379743937868625,0.06748394524947490258348636871232884004712,0.2175771631737441758058793084273929707706,0.1717264569155650677512170432237326167524,-0.1267919700681873484970907384195015765727,0.182692426202651664324250191384635400027]
    let IW_r16:  [CGFloat] = [0.2030410884992663589354577879930729977787,-0.1394953808667643846419537112524267286062,-0.2055550484026091584421891411693650297821,0.002430700073592564815910810338550618325826,0.06862136780278045578018719652391155250371,-0.1737217470830117460600661161151947453618,0.02195944993178756618479319229209067998454,-0.129499795151544999649573242095357272774,0.05358269306490057865000053993753681425005,0.100828933746029594797910533543472411111,-0.01633270175883189123666738851170521229506,0.03918149808954467933075349606042436789721,-0.07967574914860926782456118644404341466725,-0.1130285053191808913863880547978624235839,-0.1440501504011594546827979002046049572527,0.1226013542136654560499309241095033939928,-0.1962609234295792925983903387532336637378,0.07541264758094989861803014719043858349323,0.09103454776110486701412582988268695771694,0.2125001553815667187929960846304311417043,-0.1706187026366520198550347231503110378981,0.1669041489701824365621263268621987663209,0.1925304611617174588289458370127249509096,-0.0008156896383053496325798992216959959478118,0.03830982371064847041841616714918927755207,-0.08799955623435361251605257848495966754854,0.03463923706532177210215550644534232560545,-0.02419643178628366406157645940311340382323,0.139535177578499230977016054566774982959,0.1507765233392295289860385310021229088306,-0.02838812532288141621261701175171765498817,0.2083408815904254918205396052144351415336,0.2237309468798451272952831914153648540378,-0.0945394460962017540994750675054092425853,-0.09187133002539724091484174550714669749141,-0.07761854158620527799339328112182556651533,-0.0647850659478793056145207174267852678895,-0.1696493419034729999150812318475800566375,-0.0229775678227815624565799623724160483107,-0.06212126546797118453735464527198928408325,0.1537485631321934831383657638070872053504,-0.03530543995051593775258425011998042464256,-0.1771766848913381153796109401810099370778,0.2053855712410349032559508941631065681577,0.08730737553450103327623565974135999567807,-0.03227010222426130586770298691590141970664,0.06376346928742328279415829683784977532923,0.03289009239845866461315893047867575660348,-0.03553112292126199556197008178060059435666,0.1772653336119545675053643662977265194058,0.07299207407196647845459835934889269992709,0.1317819299422716416980705389505601488054,0.005762992694366950857665088392423058394343,0.1642147238346960136379237837900291197002,0.1276586190779071539047606620442820712924,0.01833030883000768065937968742673547239974,-0.1802964307904486307432279090789961628616,0.03828599063646604544475238185441412497312,0.009340083660394293829654088767711073160172,-0.06257908671985124016146073699928820133209,-0.2029343686128934343138041640486335381866,-0.01955407781686561985434735788658144883811,0.1678164692298995119834614797582617029548,0.09422322783069091156615826321285567246377,0.0262591412157539630389813112287811236456,0.02470612420434077291520047481299116043374,-0.09129542496912221305471746291004819795489,-0.07191949059694567603084891516118659637868,0.08844669951113746930726478012729785405099,-0.2243534528580539977316021804654155857861,-0.1602005971970691389216767674952279776335,-0.06477887633460387151185244647422223351896,0.06403321473738007862941401526768459007144,-0.1914952111449814697863303081248886883259,-0.2327238911758365558224426195010892115533,-0.1283984288410593699314432569735799916089,-0.1377609397286058134923791840265039354563,0.2132306628588894747977633414848241955042,-0.1264002796167920106285009751445613801479,0.08313959877265943154700522654820815660059,-0.2240006319061644268764155185635900124907,-0.2076329176449101809875941171412705443799,-0.06384455225890289797874288524326402693987,0.021696265884420060793269513510495016817,-0.2248024466789750319684060286817839369178,0.1255236213040239467986225463391747325659,-0.01021378401756180970272325225778331514448,-0.05124470265693722992317304942844202741981,0.04792948286244839289915731228575168643147,0.03983339772372831294466877238846791442484,0.105836994850295088022029688090697163716,0.01175888257638761646983738273775088600814,-0.2003510358220454423694434353819815441966,0.1574289199441233910725657096918439492583,-0.07479462873112895093807850344092003069818,-0.05346445985008108775504709342385467607528,-0.2220829505615688481690028766024624928832,-0.155483534303687109812130984209943562746,0.07697460308026041198026234724238747730851,0.00495593435641266625429901537813748291228,0.06640424842908204672298211335146334022284,0.1979704425305256476619319983001332730055,0.1980945450402014917923310122205293737352,-0.2093522990485560120177410681208129972219,0.04111489394224748100681310347681574057788,0.1846614074169965757921119120510411448777,-0.2102015520567192263801103990772389806807,0.2045827933797256248382723242684733122587,-0.01189865428276299166854279576455155620351,-0.1836112838045548256715733259625267237425,0.1974556648019414051287157008118811063468,-0.1172850384558168090887164680680143646896,0.1662107234816082024231320701801450923085,-0.1286016294240818202965215277799870818853,0.1467423487301210971445186714845476672053,-0.2016463507319384562688213691217242740095,0.1609588700942136407778804141344153322279,0.06263604399077692119757188038420281372964,0.1131499597599773254685828760557342320681,0.08204762965267368979294104747168603353202]
    let IW_r17:  [CGFloat] = [-0.06584581092618847775188584137140423990786,0.1047536828940535402754363758504041470587,0.2172174277150682175641094318052637390792,-0.1231190751392401833141931888349063228816,0.1751505147289160457813039784014108590782,-0.1429503458147772798625396717397961765528,-0.0936423647293874727992601947335060685873,0.1886700655687207073274436197607428766787,0.005712240749653056150203500607176465564407,0.03081711833558381866127184878223488340154,-0.0657982479837673633893402325156785082072,-0.1190271690372272928026831095849047414958,0.1313258008196902248965187709472957067192,-0.01176960142547490983933045072262757457793,-0.09441992172011075268311941499632666818798,0.01225213127366897233883058504488872131333,0.1998081415062502030899338478775462135673,-0.1770378299889938944478018356676329858601,0.1789938389334654045281780554432771168649,-0.03411732991221219646327256214135559275746,0.1375300100286405147187451802892610430717,0.2097685234301085999142344462597975507379,0.1747308471440530697194049025711137801409,-0.1017186893426543503604619900215766392648,-0.01634302406257288550750494948715640930459,-0.07975046405159839923992848298439639620483,0.2074574317715806304196490827962406910956,-0.09029089453916980256842350627266569063067,-0.1505722416229990645586411801559734158218,0.1422508384955226690138374578964430838823,-0.01528770131574429952392435438923712354153,0.1181489880601767350487563135175150819123,0.2013596688487962194091807077711564488709,0.1498856897796100040576305900685838423669,-0.06594684486121818456361154403566615656018,0.1872957570377480895906785463012056425214,-0.2216863130908535706176110124943079426885,-0.1597752409635113668429085009847767651081,0.08723050645940169656178397872281493619084,-0.1194941585144890655589833272642863448709,-0.1508379470145081169274448029682389460504,0.1950623630468905633783549546933500096202,0.06687704627908457044593859563974547199905,0.1788181863104892632687636933042085729539,0.1663697999124036652762725907450658269227,0.006055122779873254972027307729831591132097,0.04372305879779470050294776228838600218296,-0.08935857274718385367950901354561210609972,-0.04046401133554497486777279391390038654208,0.02708095352130642993748743663218192523345,0.1836084436215874582387641567038372159004,-0.2222352193918570861796979443170130252838,0.04435549657915491272852648307889467105269,0.01244360696304751788543452306612380198203,-0.1327887918822369672788852312805829569697,-0.1428810738301733440636098748655058443546,-0.003526713965815880293119821686786963255145,0.02220114842864418999712761149112338898703,-0.1704669348356022406942855695888283662498,-0.09751090804083872853880166076123714447021,0.1664737143550438502881405611333320848644,-0.03456480973087291963530276461824541911483,0.1212545414075005545395669059871579520404,0.05549600064839813051698058643523836508393,-0.03835438025463715899787686680610931944102,0.008109163863801513785767305364515777910128,-0.2109118481737203565362648305381298996508,-0.08892372273515961045298183762497501447797,-0.08979841297306603853378703661292092874646,-0.1398150937802630500161882309839711524546,-0.08064805569322343326010837927242391742766,0.03351773846095185832583140950191591400653,-0.1529242303460686402960533314399071969092,-0.03209794854061095298325412272788526024669,0.0463268916533247296363207112790405517444,-0.167344412263021297126996955739741679281,-0.1920293944221264093030754338542465120554,-0.0578211370607737626392541585573781048879,-0.1510572122565517205750040830025682225823,0.1294123425171097296892952499547391198575,0.1051853356595866956224583077528222929686,-0.1636042815105766823347011040823417715728,0.107986183610973007773736753733828663826,-0.1870229018161166656408767039465601556003,-0.1346728138789443640632725873729214072227,-0.1931892204575716420755782110063591971993,0.1092565689712825388602013276795332785696,-0.07217877821552327877174803916204837150872,-0.001214653454065023644933840607507136155618,-0.1423818977819896192116289057594258338213,-0.1943360339509314915762416831057635135949,-0.1724998086020419207908815906193922273815,0.06872461330826565295559760215837741270661,0.1171268939883723519956859604462806601077,-0.1003234359162962219258474760863464325666,-0.03153411959063877334497050242134719155729,-0.1125969356365834617150767371640540659428,-0.2104770371072476053964095399351208470762,0.2070714398048196513979490873680333606899,-0.1170177196380365186589855852616892661899,0.07611036034023410667970210852217860519886,-0.1845322420572237942515414488298119977117,0.09423964021485385644805177207672386430204,0.210978767090803542849641871725907549262,-0.1315405275678904473135588659715722315013,-0.1784775477061471549156124183355132117867,0.05766718436528106561667073037824593484402,-0.05218900206027086985383078854283667169511,-0.1463003993835073901497167980778613127768,-0.1897904979815484838301387071624048985541,0.09727777268858005255136589539688429795206,-0.100123168601882542305681056404864648357,-0.03044070385206449486092949996418610680848,0.01352734122145140757687009624987695133314,-0.04438203103921487674421442193306575063616,0.1778943695973422001177510765046463347971,-0.08134158405124965185439833703640033490956,-0.1934303218861826989538599264051299542189,-0.2195565280451239886794212452514329925179,0.08288766211596092225999399261127109639347]
    let IW_r18:  [CGFloat] = [0.2443141929564349168479964191647013649344,-0.05807144269836704564280438489731750451028,-0.1250643826870639907511417732166592031717,0.2579166639349732004227178094879491254687,0.1822063300679153396988141366819036193192,0.2274531921069029294368846194629441015422,0.02909943015460075832478992197138722985983,0.02802788996138048591144631416227639419958,0.05047599937760815363985145154401834588498,-0.05598643703944611998979397071707353461534,0.1058298934327824153411867769136733841151,0.1381527447047637413568565989407943561673,-0.04926856130745270456738893471992923878133,0.03209940371666539227213377216685330495238,0.01962316795669954982983540503482799977064,0.007505616269926856584659979887419467559084,-0.182917312342124688262501308599894400686,0.1192618688967399254163836985753732733428,-0.09713539832019874031843187367485370486975,-0.03766083149982708128122865787190676201135,0.0365617012282025352631897874289279570803,0.08918566862752376478429283679361105896533,0.1646829681941212319973288913388387300074,0.04694141888790360345184993207112711388618,-0.05670107400211057968597572198632406070828,0.04979047813347966394692534208843426313251,-0.1959383625496550207500945361971389502287,-0.1392513409782570876771501389157492667437,0.1173422711139397722757138353699701838195,0.2347231006701801792058148521391558460891,0.1671157807382071813773194435270852409303,0.07700927049579406324930630489689065143466,0.05779676436649405085743680388077336829156,-0.1183541628332290401859339112888847012073,0.05781154092129046906389788773594773374498,-0.04701003402414773851836216067567875143141,-0.1994336350338216101718558093125466257334,0.06535558887718230514085604454521671868861,-0.1957201994477842932340649895195383578539,0.05330371002395974805443401578486373182386,0.129182982918386479731509552948409691453,-0.08120079472805678821867303440740215592086,0.1641284089413329316808898283852613531053,-0.07142305579600083387248332655872218310833,-0.1758503063708826974487209326980519108474,0.1643789702729192558905424448312260210514,-0.06170458216794757339007659879825951065868,-0.1095425946578482273574550731609633658081,0.1449000133789009880924680828684358857572,-0.002799089240420350559179762939265856402926,0.08512207067662951043285346486300113610923,0.1856328475082942019991349980045924894512,0.113514875613969307144301978951261844486,-0.1985990942802650649490203704772284254432,0.04188747400462358716488608934014337137341,0.05603459445780783337864860982335812877864,-0.212733705589129407087511935969814658165,0.1941305936386822916794869797740830108523,-0.1713202504121259517333442090603057295084,0.01265709697352559483241041249357294873334,-0.1733651007490244200237583527268725447357,-0.01113044612056950100065222386547247879207,-0.1738543307247152336358908542024437338114,-0.09947600280943554029722264431256917305291,-0.09258422803585576732476880579270073212683,-0.04034852347275500600298769882101623807102,0.1650745366276696324270290006097638979554,0.08924731364783383691374751833791378885508,-0.02237935172484139742521414007114799460396,0.07838593612552408051996621907164808362722,-0.2001774092473617983056755065263132564723,0.0808758062800733479313919360720319673419,-0.120446218508742999842020537926146062091,0.005473022419972811865307438239369730581529,0.0626784120121585824891852212203957606107,0.07283436720514405160464832533762091770768,0.1810595108381544970921339654523762874305,-0.2211796459729691299855858233058825135231,-0.1918975847946300106183770139978150837123,-0.1457089182023814655231319648009957745671,-0.02312307249856433363777163947361259488389,0.002270795495216215622441557897559505363461,0.19841796628260155443967960309237241745,0.09694435533765193013788774578642915003002,-0.0907036651535303578564040094533993396908,-0.1404384283078889128493216276183375157416,0.1196848722545748311407720620991312898695,0.03190518709800164304235536860687716398388,-0.07443468295842974036258254955100710503757,0.1670366543921909807668413350256741978228,0.1752612355643557717765901315942755900323,-0.1262284697906146946344563275488326326013,0.09166123445183393947388594824587926268578,-0.2002114194684293801973495874335640110075,-0.1885590270575371873995607074903091415763,-0.1953916935746543848129164189231232739985,-0.1802539275040153099460837893275311216712,0.1630838030888413225927280336691183038056,-0.2135925742230655177689158108478295616806,0.1106324700511645414691130895334936212748,-0.2130131665784213979009109607432037591934,0.05636870212901236992797393554610607679933,0.05360861094605564453052792828202655073255,0.1746347712730700330041599954711273312569,0.1879660087239066745823379278590437024832,-0.1473818106289886686877110832938342355192,0.06593766254867676479545224310641060583293,0.06665163398254241033935585392100620083511,0.1182939008544184322779813101078616455197,0.06987865009589996900807307156355818733573,-0.1431040684958585218478077649706392548978,0.1359596306358596407015681961638620123267,0.1143188543742677393266760077494836878031,-0.1929218516287315721147166414084495045245,-0.09534076718805806205381259132991544902325,-0.09282937734640873961300400196705595590174,0.1724948954676535084473698589135892689228,0.03177778506288758686437745382136199623346,-0.1140077965606048626678870050454861484468,0.06493055760248560293046438118835794739425]
    let IW_r19:  [CGFloat] = [0.06101591720611114488814763490154291503131,0.0539008424064503777195511702302610501647,0.2903603449973540806539062941737938672304,-0.1026443458647371270719972358165250625461,-0.08350057175491544525502973783659399487078,0.07924928582606576010771703977297875098884,0.1579600000935252601674818606625194661319,0.1706026283868453119474395407451083883643,0.1917444572858546247839939269397291354835,0.1992376578712142520810601808989304117858,0.007106257129195138466659642517697648145258,-0.05598869796065696069486961050643003545702,-0.229532174922065179689667502316297031939,0.1296189907138087238358536978921620175242,0.2323252430168376847507971660888870246708,-0.1671677891184223108123063639141037128866,-0.0003864313821700975570480607323986532719573,-0.1782841974097960358047743056886247359216,-0.0483813281242301551632323253215872682631,0.1280091176048878121029872545477701351047,-0.0268393723944497578082213351535756373778,0.003442007852916246276459011355086659023073,-0.01436994624857133515116736077743553323671,-0.05343702925502140377300719364939141087234,-0.01268207052314174188012430022354237735271,-0.03987338291989159927419805740100855473429,0.07740780567509311649310177472216309979558,-0.03163014198782557878653065586149750743061,0.03227364012689053207605383022382739000022,0.02120600348193293904763834234472597017884,0.09958910772923970644576741051423596218228,-0.1895224582061839635471756082552019506693,-0.07129969797679598653150634390840423293412,-0.2158894810878032310963448026086552999914,0.0103903094329769254966500113823713036254,-0.1067344747335834953538835634390125051141,-0.1706965639671239320929174709817743860185,0.06957832340469072285316087800310924649239,-0.2159775418746520403434629997718730010092,-0.03132257638308041935992775961494771763682,0.07771784877979075190079782942120800726116,0.04324154004173826754131582106310816016048,-0.1436563936460709123288381761085474863648,-0.09248610713428194463059384133885032497346,-0.1147458578187964400862952629722713027149,-0.1508738511900569179147169052157551050186,0.2225543972206773524202816361139412038028,-0.07278114560924292542054558907693717628717,-0.1370741032925297253619589810114121064544,-0.03995524195630583558225268347996461670846,0.1259169083184039084066796476690797135234,-0.004087125242290092982933025211877975380048,0.2081343695147156724889470069683738984168,-0.05757136986495881708636446205673564691097,0.2319077991403696581418358846349292434752,-0.1484748218489898297089979450902319513261,0.01083303040961684782228502399448188953102,0.1377496600929045966754671326270909048617,0.1435679845105202467880900485397432930768,-0.03586543352491849967478287908306811004877,0.2447435791922625281102909866604022681713,-0.1035944519840537453303497272827371489257,-0.1193371990771297241895609886341844685376,0.06147387541153649659353419565377407707274,-0.01020012054955882034590342044566568802111,-0.1443741407761353345851063068039366044104,0.217209757251651147669235797366127371788,0.1283249101217238674621512473095208406448,-0.05022011541291199199221750859578605741262,0.09255978960073998895730085223476635292172,-0.1184148808698873706068965816484706010669,0.1762383613884515587422185944888042286038,0.1802251521229788489009138174878899008036,0.0383679130579486146745971097971050767228,0.02275122156134734563437405086006037890911,0.1616623272451956638828818313413648866117,-0.1929265452679996273310791821131715551019,-0.2018994512107357974795007748980424366891,0.2168421663081485373236745317626628093421,0.03032063159371048421952821172453695908189,0.1344557390989847001083745681171421892941,-0.09200787053378509106060789690673118457198,0.01541145192737178835906686202861237688921,0.05988938709491237188942136526748072355986,0.1090579079667349654547692239248135592788,0.0007848002320398970565323848447292220953386,0.09641562829570428372338852796019637025893,-0.1766063696431624530092108216194901615381,0.1984604103415045228686608425050508230925,0.2488108624644319311070006506270146928728,-0.08093749054456865488216266157905920408666,0.09007578766000086389897916205882211215794,0.06253333526246764029199454171248362399638,-0.1209348152244666962928931752685457468033,0.09779518905249597049422760619563632644713,0.1048410121719483417690454984949610661715,-0.113048542567520240997858138598530786112,-0.1608140729532895607523101944025256671011,0.1717190817497926957901910327564110048115,0.2210813888537975779868816061934921890497,0.1995148677505069745308219353319145739079,-0.02683487068512479048476571108494681539014,0.04961948721092311609393021853975369594991,0.06881077882920866306548646207374986261129,0.1669437179638627311017984311547479592264,-0.07806921400629260321402114186639664694667,0.02154258420665634485291484168101305840537,-0.1401518950254171946845360707811778411269,0.2403854500136097804841028846567496657372,0.08672092880969214934161470864637522026896,-0.234276913721548268876304632613027933985,-0.1625239543206242476269807184507953934371,-0.0684490849794440608944157133919361513108,-0.04306935428663004328253549601868144236505,0.08447790088302158106881023513778927735984,0.009870228910751965151204601056633691769093,0.2296882335998869928417320807056967169046,-0.02499890752490748282999000196014094399288,-0.03680226134364666945586463953077327460051,0.03058844562947450954060180094984389143065]
    let IW_r20:  [CGFloat] = [-0.2037804079915206401096838817466050386429,-0.1379430077371676666153632595523959025741,0.02799211089959808412830355450751085299999,-0.1151004316601692695209990802140964660794,0.02338271962481175414438894222257658839226,-0.06886851809919962430495132821306469850242,-0.004716151154040460966032632939004543004557,0.0003946443305685839921664870288964266364928,0.1465138195048394931241375616082223132253,-0.1157251882695116140808977434062398970127,-0.009780897495086574369715926025037333602086,0.1714164346275795225427174273136188276112,0.1993674974640745056753132757876301184297,0.09501617931893893698180875162506708875299,0.1148660071491063028314982830124790780246,0.2000162239370944783356520702000125311315,0.1145154437585412243727489567390875890851,-0.1693248863380365787367765051385504193604,-0.06993741259808076982107394314880366437137,-0.06030733142514272532297425755132280755788,-0.0666253699605666022121042146864056121558,0.1052898946783251132863767907110741361976,0.1870861980207213781657316076234565116465,0.04714398766865179890572790100122801959515,-0.09273679781352851814180127121289842762053,0.005834201397955450507648578195585287176073,0.03242953374479543016128957333421567454934,0.209994893903611506980055878557323012501,-0.1075579371751034934989732505528081674129,-0.1745844126759507342061539247879409231246,0.004075206614185424361385123859236045973375,0.1037660276346924898005497084341186564416,-0.09034305088334768085722714658913901075721,0.103610563550927875509088949002034496516,0.02768829821285894582372222316735133063048,0.03785411992111464840604639903176575899124,0.06795713402384136181400009490971569903195,-0.171886239216602676460610155118047259748,-0.1795456097465464306850435605156235396862,0.1660877946614029154748237715466530062258,-0.1546073019365296064009385190729517489672,0.1703020412547774642408882073141285218298,-0.1744046883818827498036085899002500809729,0.1791833135455160597171442304897936992347,0.1531738552682631038237559550907462835312,0.09287978920158979079246819310355931520462,-0.2126256651307248668469895847010775469244,0.1455922042282970785276319247714127413929,-0.1230109346541739256952752157303621061146,0.06065894243165120824912150965246837586164,-0.1039608124488244356165012050041696056724,-0.01355580933636778458162286398192009073682,0.1128968479539006752876417749575921334326,0.1838811107373620190585938871663529425859,-0.03794760309511008983252011717013374436647,-0.1238597428615541978791370070211996790022,0.1523010640174176921757265290580107830465,0.06571946186574656456613752197881694883108,0.1985316876031781030409462118768715299666,0.1797219184240186895529234334389911964536,0.01366000933825466286120065007025914383121,-0.2085874448438657380311411770890117622912,-0.2023481097713558107820119857933605089784,0.1719750606501024847716507792938500642776,-0.1278791776031706073357696595849120058119,-0.02741094920500623116632610276610648725182,0.03360571939189313517282187149248784407973,-0.1660180040084375807651895229355432093143,0.1671923464626073052574639632439357228577,-0.1503821406537843297090972782825701870024,0.06735524130841100132194299021648475900292,-0.07046707846354327564597497257636860013008,-0.05361351540538915327882563133243820630014,-0.09381813274764345955691879908044938929379,-0.1117860584193544754016969022814009804279,-0.1248854070560696943870127029185823630542,0.1176489034849249604164356242108624428511,-0.1655913972341499784679541562582016922534,0.05539924408861601756726145140419248491526,-0.1484487240626638226981270918258815072477,0.1468561133653928929554410842683864757419,0.07982012632867521717550118864892283454537,-0.1218671428415698254621446494638803415,0.187353622697731453383696020864590536803,0.009371884236068312931666746123937627999112,0.1530507079099110989695020634826505556703,-0.153659048800209863117061104276217520237,0.1391957764348399351206353458110243082047,0.2025429950178996019172217302184435538948,0.2007322383220600803266364664523280225694,0.02588275903217649928644839008029521210119,0.1545973435629343917252498386005754582584,0.04278855113090618972337964009966526646167,-0.04682798578908667352926897819997975602746,-0.1684995234681508358143275927432114258409,0.1310871024214347035918848405344760976732,0.1116054278756452855514424982175114564598,0.124054544153724258248594480846804799512,0.07602078233310470556371996053712791763246,0.1260298785123307452327168221017927862704,0.1608164195967322629421403235028265044093,-0.1953062611165398143597826674522366374731,0.059098256458574381644321960038723773323,0.03427467723908498437035419215135334525257,-0.1388651153676605520814746341784484684467,-0.01728442281152925766307681954003783175722,-0.2048223561826571503807770113780861720443,-0.1623794344705246639470885838818503543735,0.05424176193472603907386186961048224475235,0.173444093885374739372196017939131706953,-0.1660570544711965357276284294130164198577,0.2015597437575258887854090517066651955247,0.08936957625045728603740968765123398043215,0.1348314161370308961185315865805023349822,-0.1839804325659560035877149175576050765812,0.04124638895358744700159192575483757536858,0.02523559057348736395232080553796549793333,0.2105124612222991353771561762187047861516,0.1340655899094311265251633358275284990668,0.1600779075982993460147696396234096027911]
    
    // Input Biases (to be loaded from CSV later)
    let b1: [CGFloat] = [1.434042613355562156840505849686451256275,1.283494776926444425058093656843993812799,-1.123463715322583045264082102221436798573,0.9970547692928469762918552987684961408377,0.82669329440108063611347688492969609797,-0.6834527978443064588631727929168846458197,0.5140154428257621699316359809017740190029,-0.3779209671428065409060081947245635092258,0.2316816870600901245857983212772523984313,-0.06866007118443760715020829366039833985269,0.07550753683337466104497082142188446596265,-0.2324456794468939824227504686859901994467,0.3838442905588782538828240831207949668169,-0.5457840804461083772380902701115701347589,-0.6849270389294790373213572820532135665417,0.8277655192827073626915534987347200512886,-0.9796751209026877127428178937407210469246,1.145805680955927163822138936666306108236,-1.292687305413686926769400997727643698454,-1.435760001571880328796737558150198310614]
    
    // Layer 2 Weights (to be loaded from CSV later)
    let L2W_r1:  [CGFloat] = [0.1860745023544314313834746599241043440998,0.3533336149616749244373181682021822780371,-0.4769249189897039609142836980026913806796,0.04956721877868186520998960986617021262646,-0.02592065034329432346438260026388888945803,0.5075119162014193330278999383153859525919,0.3674371977015625234663787068711826577783,-0.5203712384605908569668031304900068789721,0.09868979875399849777117822213767794892192,-0.5039286414824044602056574149173684418201,-0.007706878274888293023359153721685288473964,0.5718726549889663335335399096948094666004,-0.2900117067456722819152048487012507393956,-0.4880478472922565313929510466550709679723,-0.5310670128122055855257599432661663740873,-0.3800522452938581707826415367890149354935,-0.1829405225640442778090033471016795374453,-0.2813648848155096415801779130561044439673,0.2572483513062915894131776894937502220273,0.2483342270048118360925570868857903406024]
    let L2W_r2:  [CGFloat] = [0.141200196569397640189436060609295964241,-0.4302421141710047747253042871307116001844,-0.01645875732326583171238887359777436358854,-0.03260815308299944148551219313958426937461,-0.1620294338593691874095270577527116984129,0.4096583057797319460391349821293260902166,0.1682473664289353965095585863309679552913,0.3663081481696878194398436789924744516611,0.4742344764493113262737722379824845120311,0.4079095182519577589275172613270115107298,-0.3495348491033513083081629702064674347639,0.5861305350521892609805263418820686638355,-0.5933339153163272872149036629707552492619,-0.4844422580782231646523428025830071419477,-0.2178369598806335627472208216204307973385,-0.4988780752443713883970133338152663782239,-0.2182536094879757582187806974616250954568,-0.07848599641048380204377821200978360138834,0.4331940444970882597708339289965806528926,0.3185419689222591665966888285765890032053]
    let L2W_r3:  [CGFloat] = [0.3639610021502193148990045301616191864014,-0.01758208626171132993309953462812700308859,-0.3027208557973704583510254906286718323827,-0.5279784081775616977338927426899317651987,0.2817640848201224401670117458706954494119,0.3422804697796927309028092167864087969065,0.5545159313297235437190124685002956539392,0.1781526647440216659656897491004201583564,0.1346623735501983054607677559033618308604,-0.06359332619900180672001255288705579005182,0.3033132985826001437601462384918704628944,-0.1845700735716872542546695967757841572165,0.39785550229776006636583929321204777807,-0.2978394740844581556338255268201464787126,0.4094333281790440981495748928864486515522,0.5242595745076866764478040749963838607073,-0.2095182868092458905451280770648736506701,-0.4465437807903043232471418377826921641827,-0.4141259100085207811581256009958451613784,0.5479666204637249071751625706383492797613]
    let L2W_r4:  [CGFloat] = [0.4810223961867615138920939443778479471803,0.02516634134668071370866115898934367578477,0.4849251931597653997307872941746609285474,-0.03581891292544333443848003639686794485897,0.3706855338829136981004808149009477347136,-0.49693843754622452069114046935283113271,-0.06103457496849620800283275912079261615872,-0.2818134341769773509867036409559659659863,0.4548115553359615703676865905435988679528,-0.5269646850378678637483176316891331225634,-0.3588196718110193139672503548354143276811,-0.3275524484993027618529026767646428197622,0.17340881600199214984669993100396823138,0.3236713065548609824517711786029394716024,0.3055562584049804630836888463818468153477,-0.5317417257466031665913419601565692573786,-0.2837199691068456597342617442336631938815,0.1940391869808731628577191941076307557523,0.5248961538876565358080483747471589595079,0.2820580406450278743157866756519069895148]
    let L2W_r5:  [CGFloat] = [-0.469060373167159150309402093625976704061,-0.08299836444851922678811462219528038986027,0.2253071200881430757867462943977443501353,-0.3295289886360948106158730297465808689594,0.0538826093580894727175234493188327178359,-0.0404606653410189073816205507228005444631,0.6232438881707313971247685913112945854664,-0.2195350913169558659809865730494493618608,-0.2862755613818257494074259739136323332787,-0.3530220817583625270152936082013184204698,0.2568801068628042139074807437282288447022,0.4887466036254782264514062717353226616979,0.5381227838340303382125284770154394209385,-0.3674492249321030246100860949809430167079,-0.02927965322204368475711433461583510506898,-0.4108062153791093851218363397492794319987,-0.3821173705093653949482757070654770359397,0.05640371792980094362013332442984392400831,-0.4049620631540084558785963508853456005454,0.6316282847961195434649539492966141551733]
    let L2W_r6:  [CGFloat] = [-0.5710350980976979240466562259825877845287,0.1361689008485378604706994565276545472443,-0.1462633383865825087433165663242107257247,0.5847675724398010421722915452846791595221,-0.560440462052618104671353194135008379817,0.201138616386733998231406417289690580219,-0.02846022288209591397101227983057469828054,-0.2843449216597121464999986528709996491671,0.2095942052218315587719388304321910254657,0.05086920699214972363400022459245519712567,0.4211830501137575621939390657644253224134,0.06699126515906672629796503315446898341179,0.5444448438168207893284034071257337927818,0.5244326461961394958422033596434630453587,-0.1358877625491504148591559442138532176614,-0.4109380208057955563560881273588165640831,-0.3423478497651720187100465864205034449697,0.09563018038813655974372807122563244774938,-0.5640354775961349265145372555707581341267,-0.2791537250550549797978305832657497376204]
    let L2W_r7:  [CGFloat] = [-0.01651912783220014710461320817103114677593,0.0421450179622372272936203785320685710758,-0.406080511617280204283986222435487434268,0.3576785290805750694431708325282670557499,-0.3783782960246394044823148306022631004453,0.2416525349776206255114630039315670728683,-0.05602580188708971425937122035065840464085,-0.3581896512994291459364148977329023182392,0.1649219956855115798433075724460650235415,0.6284415303468586788682159749441780149937,0.5904958048155203309548255674599204212427,0.5626143058713483080524042634351644665003,-0.1075701838074692717750480142058222554624,-0.1487245701501858641258024817943805828691,-0.1261214049774165291140093358990270644426,0.5815999720342386325455663609318435192108,0.00374607303248843592421990500440642790636,-0.3887660529221221850093570537865161895752,0.5762491754236153118640118009352590888739,0.2715658347650070636447594552009832113981]
    let L2W_r8:  [CGFloat] = [0.1382861330742878591681943589719594456255,-0.5225250737465941819337444940174464136362,-0.09656223399372126925399584251863416284323,-0.5037510700100144012125724657380487769842,-0.4265879649957571850826809622958535328507,0.3647504884824618875960311470407759770751,-0.5186362797609597174997020374576095491648,-0.0418997382035087156948449660376354586333,-0.1259169387315230426160894694476155564189,-0.5399108622365209608773284344351850450039,-0.4763890315664677244100744246679823845625,0.5408026879205359849223100354720372706652,0.02883366888533849328735136907653213711455,0.03188282896263479326837142480144393630326,0.4126974756334200189478167430934263393283,-0.2198820395162869034688668534727185033262,0.2186214473979024019989481075754156336188,-0.01633294326462803730537487467699975240976,-0.4685113562571789902477803479996509850025,0.4316459703272936265783243925397982820868]
    let L2W_r9:  [CGFloat] = [0.5571308284632174867567755427444353699684,0.0775913082319523023100416025954473298043,0.4509271544851209956306092863087542355061,-0.07021243342992863900597910742362728342414,0.1510121194531339194888630572677357122302,0.09766400508740291641629482910502701997757,-0.4875978061107733574353062522277468815446,-0.3089732747926799971693867519206833094358,-0.4107835865646032313946989233954809606075,0.3920070293338022149320920561876846477389,0.1257972452335257007582924870803253725171,-0.5036154289578119724879456953203771263361,-0.239216301080764748299145594501169398427,-0.1066484668040974109759488896997936535627,-0.07342771220986807345632030319393379613757,0.4961989098503409856277812650660052895546,0.430889758605220496434640153893269598484,-0.4068347547339801750787557921285042539239,-0.4560713300468360875683515587297733873129,-0.4836125817963181638958758412627503275871]
    let L2W_r10:  [CGFloat] = [-0.2432564239246262083327110303798690438271,-0.5561458797658820341069940695888362824917,-0.02633835152978278651425547707276564324275,0.2521955123056862091424079608259489759803,0.06910458575296066219273427577718393877149,0.05859889065206268926599975088720384519547,0.3239515136557993280064238206250593066216,0.623061538722108232413177120179170742631,0.04322614431588408384632415959458739962429,0.5520219589394733672449433470319490879774,-0.03897318524869628625362238949492166284472,-0.1874127130150345099668385273616877384484,0.241509137968222764580872308215475641191,0.2760234170259233121846875746996374800801,0.5920705757392966672725265198096167296171,0.6340972338184784895531720394501462578773,-0.3662734690288730332596855987503658980131,-0.4726248252053931175886702931165928021073,-0.3483547144724920552327773748402250930667,0.02205887765677556899834854675646056421101]
    let L2W_r11:  [CGFloat] = [-0.04826949252396421641275736647003213874996,0.06268481096655496853653488642521551810205,-0.3787574606100879148762317072396399453282,0.08875737610690730139406667831281083635986,-0.1608705434705307857345957245343015529215,-0.1735313414950504229405936484909034334123,0.2040218574836225318147597818096983246505,-0.2117384689884181936392337775032501667738,0.5878798942596134002869234791432972997427,0.2207484864084799380812285107822390273213,-0.3185672378171777174848955382913118228316,-0.0009334928511709664590914603543581051781075,0.631146778083201076547936736460542306304,0.6059431171311845387705830034974496811628,0.2903969266885369493458313172595808282495,-0.6456023850460420598906807754246983677149,-0.1488522034442399388787237057840684428811,0.4096317195312541570295650217303773388267,0.4930264967650754281969227577064884826541,-0.3668330063947072283703221273754024878144]
    let L2W_r12:  [CGFloat] = [0.4308135220790457742268131369201000779867,0.07058152375017949509139469910223851911724,-0.3122831450445570644625092882051831111312,-0.4124497019102335571005824021995067596436,-0.272500401448194373710265381305362097919,-0.5315979531417108772117785520094912499189,0.1141205655910652039253250222827773541212,0.4781665162604799568235591777920490130782,0.3363187750697974043312399317073868587613,0.576074749720524192930781737231882289052,-0.540490065856297996482737744372570887208,0.4281643182980745532262289998470805585384,0.2342066071537210747433022106633870862424,0.2098956961336656823480240063872770406306,0.4818413032954400598839583835797384381294,-0.2984321872749280402103977394290268421173,0.04695398634353599442992077683811658062041,-0.1365861869778419168675043238181388005614,-0.2997192538939643657869282833416946232319,0.3662159996724262955858364421146688982844]
    let L2W_r13:  [CGFloat] = [-0.1177914341589998692416685344142024405301,0.4331266556247558296988131587568204849958,0.1919605655735417970575440449465531855822,0.312776830154967599995075033803004771471,-0.02369657561917705435039493977456004358828,-0.520314059857146959942042485636193305254,0.5442916441154148632364240256720222532749,0.5273233461743360717122186542837880551815,0.3167484160316267338686202492681331932545,0.5288411916274201596266379965527448803186,-0.182621692965193538338297685186262242496,0.08694195071055600687603970300187938846648,0.3508294013750825057762483538681408390403,-0.005212284532190584324107263114456145558506,-0.4028728668784984923156855529668973758817,-0.5526240719987823846182095621770713478327,-0.2890056354279209038793396757682785391808,-0.02049476040391345899038810784986708313227,-0.5726696998026202800602391107531730085611,-0.1725271506039745272875762793773901648819]
    let L2W_r14:  [CGFloat] = [-0.02554046872299277348705714985044323839247,-0.5377853165783984534797923515725415199995,0.4038713999524226050397146536852233111858,-0.5205350040646116172027291213453281670809,0.09068541029729838831574539881330565549433,0.2871668721152008107999620278860675171018,-0.3638464389844134339035974790022009983659,-0.4294767315283729569586057550623081624508,0.3174080601979618054819809458422241732478,0.3001867368206339592440201613499084487557,0.5468815604921294371010276336164679378271,0.2171696228004558748558849856635788455606,0.4595477213219082979200891259097261354327,0.344420128661682978243874231338850222528,-0.2205555396026664116693183359529939480126,-0.3243055874631464163826422009151428937912,0.1323794316677031346340953632534365169704,-0.2121226588200737506184623271110467612743,0.3486751148812122780284994405519682914019,-0.5486947382771439896131937530299182981253]
    let L2W_r15:  [CGFloat] = [-0.1092043766852833497349450908586732111871,0.0206511387010612917913832120575534645468,0.3208764989900266817457463730534072965384,-0.5625600653818024765584482338454108685255,-0.1164144057961414846502634645730722695589,0.3063959736190234317554370591096812859178,-0.5382399554705962207989955459197517484426,-0.08374677067315144940451432375994045287371,-0.1985292655367619507611465223817504011095,-0.4913739567578052636065422120736911892891,-0.07081084690248271029666682352399220690131,0.4538556347988604855459016107488423585892,0.41483007515935949038876628947036806494,-0.5470903797382261624093757745868060737848,0.3791850311600037937154183964594267308712,0.3947071194262865012625240979105001315475,-0.2509312035676362073743916880630422383547,-0.153716283811040299589478763664374127984,-0.5042807565831982641313402382365893572569,0.4370210840642407279510450734960613772273]
    let L2W_r16:  [CGFloat] = [0.5117589170694072375766836557886563241482,-0.5484492293853849842477643505844753235579,0.04904827222373958628409695847949478775263,0.5106749638089383980243951555166859179735,-0.176175323976588693586364797738497145474,-0.388663309053611405463612982202903367579,0.3331467057129607334253762473963433876634,-0.4178527721916862613937837522826157510281,-0.587585248430157136567686393391340970993,0.2104132654122533030438546575169311836362,0.2038124529857693323364742354897316545248,-0.1971261174498595558635116731238667853177,-0.5888551125393394203300090339325834065676,0.5544338719376386004356049852503929287195,-0.2793324122322113911565111266099847853184,0.1089505613274443091009757722531503532082,-0.1392963407114947149700867612409638240933,-0.1563663031300418226887671835356741212308,0.1409978873716721536890617016979376785457,0.3470439604405285982657858312450116500258]
    let L2W_r17:  [CGFloat] = [0.4519469276803790291907603204890619963408,0.5245810220100886045457855288987047970295,0.4624732597679855894412526140513364225626,-0.4799088075385970486586018068919656798244,-0.4590440007831421698192286839912412688136,-0.5260189903448718728995459059660788625479,0.1667195326639757391173901623915298841894,-0.2080915875857258512393599403367261402309,0.4721977658555898682557483425625832751393,-0.06425695924542441928029035125291557051241,-0.1723965332291901020322910653703729622066,0.234279430441638708559892734228924382478,0.306167431596989836339872681492124684155,-0.4054541607487572307810808069916674867272,0.3761002221723750982285139343730406835675,-0.3921482971864151956253863318124786019325,-0.09752284537682420761939283693209290504456,0.2596384300374430798008518195274518802762,-0.4539858713222447161861339282040717080235,-0.1196412693294867934934444519967655651271]
    let L2W_r18:  [CGFloat] = [-0.3646638379411270558527746743493480607867,0.4523668223913715480399844182102242484689,-0.2743039922557705123651317080657463520765,-0.1871887869511496549357332241925178095698,0.06398486312378062756955898748856270685792,0.1790877115467220948019644310988951474428,-0.4282492578770294988643740907718893140554,-0.6353633796120515819794150047528091818094,-0.5754396428651441519619424980191979557276,0.05910847022322499033641918231296585872769,0.03935723716580752373772611463209614157677,0.3356054805510763072717850263870786875486,-0.04238881772436461220499026580910140182823,0.3293050306319078024408497640251880511642,0.5022581494892167652821513001981656998396,-0.3853492927121358047060084572876803576946,-0.3657413921894540620449731704866280779243,-0.0288633858031649218056635675111465388909,-0.3288722996042840462926903910556575283408,0.6117541586696559896552116697421297430992]
    let L2W_r19:  [CGFloat] = [0.03265179089394541073199107472646574024111,0.2540834345526006288196185778360813856125,0.1620210929777522734784866997870267368853,0.4107310210995144261758582615584600716829,-0.2678210131849382835689254989119945093989,0.1208811532348655765067846346028090920299,-0.6168502229472748732419518091774079948664,0.1339285347899163147733503365088836289942,-0.3549251018196455942366185354330809786916,-0.3142964134665000019985825474577723070979,-0.07228809609486225307151130436977837234735,-0.3751221739813471178770498681842582300305,0.6592383401924356567391782846243586391211,-0.719091705885136933673607018135953694582,-0.5246059564704279587488144898088648915291,0.2406662956120997620690360463413526304066,-0.01465636175365662464964433553404887788929,0.2210839718627231331726790131142479367554,-0.1477045758080390291944183900341158732772,0.4162519249315299041391824630409246310592]
    let L2W_r20:  [CGFloat] = [0.3203320282015520437113309526466764509678,-0.2640004105328118688689187365525867789984,-0.150645099473712157367444319788774009794,-0.6875104053851525121032750575977843254805,-0.612489828590272566977148471778491511941,0.716081263792267219692178059631260111928,-0.04890955573827732855152206070670217741281,0.001090193834047565321979100794180794764543,-0.3200582944325729983781059218017617240548,-0.0695222450233761585236536006959795486182,0.2876602077967922443946235944167710840702,0.0145924388689044823297358277613966492936,-0.04680370017523498293865458208529162220657,-0.5382388301762580651299572309653740376234,0.3236827386949480134248346985259559005499,-0.309968975871762975060619282885454595089,0.009720210757161732578746082822362950537354,0.169887792287171823790714597635087557137,0.5018034720171192786253300255339127033949,-0.3477951090983303905623813534475630149245]
    
    // Layer 2 Biases (to be loaded from CSV later)
    let b2: [CGFloat] = [-1.636356577498946363036225193354766815901,-1.451344765295818017847295777755789458752,-1.308870439412749497876120585715398192406,-1.114957400569245304922105788136832416058,0.9451442358594434045571119895612355321646,0.7716541170306336905326816122396849095821,0.5864853112215087094227783381938934326172,-0.4347935336136402040274617775139631703496,-0.2687415182813018277308003689540782943368,0.07481298608941300276597985430271364748478,-0.097070405082396019058599279105692403391,0.2673115335684740356825273011054378002882,-0.4398661933276465374476060787856113165617,-0.6017324157557802921658662853587884455919,-0.7776496597619647621613125920703168958426,0.9291255128033401033960103632125537842512,1.112856431665873557790291670244187116623,-1.280313834171721065757765245507471263409,1.456097756742374071947665470361243933439,1.622052265295153450352927393396385014057]
    
    // Layer 3 Weights (to be loaded from CSV later)
    let L3W_r1: [CGFloat] = [-0.5327950052484636822569541436678264290094,-0.2241524935063767265397416394989704713225,0.504631305649219319420240026374813169241,-0.2632666273172438731187128269084496423602,0.3914155291924890645027801383548649027944,-0.1318474852748604264629506133132963441312,-0.5075280450598200765455203509191051125526,-0.1070899710096058499164684008064796216786,-0.4726887965811705227814343288628151640296,0.2144510293444132076334796010996797122061,0.4000185806801361820816964609548449516296,-0.286615279167399039650376835197675973177,0.2901176229394124006510935487312963232398,0.5149843539857921204117019442492164671421,-0.0374061546450403167862752695782546652481,-0.4729798226625204771167432227230165153742,0.1141068543235802257296285233678645454347,0.5111002508286380807689397443027701228857,0.01968773262391015563266272181408567121252,0.09859534065580280448592986886069411411881]
    let L3W_r2: [CGFloat] = [0.4496634075412805908733560045220656320453,-0.2066749659218183321485184933408163487911,0.2336654447152247959795801079962984658778,0.2460680482584096662179717895924113690853,-0.1078054118067488797994002425184589810669,-0.1364962051690337407894304533328977413476,-0.4938794420570726262376126669551013037562,-0.4198995415823978949454442499700235202909,-0.4984090833945041820740584626037161797285,0.5106621342008804687040424141741823405027,-0.4043717562023745326627022222965024411678,-0.4263172794292591771814215917402179911733,-0.4499609757216838090698729502037167549133,0.5001159114833448882109223632141947746277,0.101369078117874336641968113781331339851,0.1571254501306025286311296440544538199902,0.2444648974107674066491568964920588769019,-0.4875079826576481090150139152683550491929,0.07534077541054566562461758394420030526817,-0.09620294277473449839899188873459934256971]
    let L3W_r3: [CGFloat] = [0.180606197428454767761607513421040493995,0.1317054752362187552972017101637902669609,-0.02035384939283604865956078810995677486062,-0.3409189702828579471294290215155342593789,-0.4133716185342556359572085966647136956453,-0.6918673102779624439762073961901478469372,0.3442394308535697278195186754601309075952,-0.0278016829229983802873604759042791556567,-0.6361833869348590964065692787698935717344,0.1647806557130662985510838325353688560426,0.01915559994906228941102810381380550097674,-0.09419810068875270059329807281756075099111,0.4163264896990260255371651965106138959527,-0.4979830015135582876872888391517335548997,0.2145570395738594926537956553147523663938,0.2891797109442333924000934075593249872327,0.03395303309690980708701601997745456174016,-0.5865742525186239397783083404647186398506,0.04765588315227326648981787116099440027028,-0.4308545330556421415479917413904331624508]
    let L3W_r4: [CGFloat] = [-0.05674080331130747917312007189138967078179,0.3396718444244909984597313723497791215777,0.4600087380613077647772968248318647965789,-0.4349487850541360334233331741415895521641,0.1865627502858138997421377780483453534544,-0.2474374010889394404077989975121454335749,-0.2121188681939832898493136781326029449701,0.3214417504062732633407506455114344134927,0.5218610041383884290411288020550273358822,-0.4611844446980038481065378164203139021993,-0.4797318597827982533665647224552230909467,0.1244657095721665718279780321608996018767,0.4665101034451407668868228029168676584959,-0.2413258419860397629985726553059066645801,0.2008746869588148298291230275935959070921,0.02271662925092023457840362254955834941939,0.3736294238853237748010371888085501268506,-0.5963955331687267324980439298087731003761,0.2202876572974928615078482607714249752462,-0.3459552828097185450673123341402970254421]
    let L3W_r5: [CGFloat] = [-0.5210098027825407207558328082086518406868,-0.487685886488715469866406237997580319643,-0.4746771833452894662208620957244420424104,-0.2755677369528842790558087472163606435061,-0.1097767516640029555885504919388040434569,-0.4417811605001952801607956189400283619761,-0.2413412511758585288212941577512538060546,0.509470513163801319578283255395945161581,-0.282331726379692948825095299980603158474,0.4268615214585063100116713030729442834854,-0.3926140721398757027493786608829395845532,-0.08351466424156049617177899335729307495058,-0.3049644645142647325641860334144439548254,-0.1133864961200138493646605297726637218148,-0.01071327862099713014443214120774428010918,0.3795979987148778156402784134115790948272,0.5097281454016874269186132551112677901983,-0.1850655108413764293739944832850596867502,-0.2467815957129732284958123500473448075354,0.2704359269389585151976973520504543557763]
    let L3W_r6: [CGFloat] = [-0.5896400807760658890899208017799537628889,-0.3921842553123062180553404232341563329101,0.08311515426805264616927360066256369464099,-0.677923701419925195388316296885022893548,-0.3991904064968360144050052440434228628874,-0.07053826643350830094547632143076043576002,0.565571593240779435518561513163149356842,0.3899198403149829461611375336360651999712,-0.2194235914195304670837316507459036074579,0.1720117418884487547892092607071390375495,-0.16501007887702906495874799475132022053,-0.1181200149439740332280024404099094681442,0.03085350908863367797030363703925104346126,0.3795025649839404158214506423973944038153,0.09373668236093181393986384364325203932822,0.6311186336026867182980026882432866841555,-0.3325565271603940775690944064990617334843,0.2812058555839906937023897626204416155815,0.004464614610607578817913498880898259812966,-0.05140355146798145785647093930492701474577]
    let L3W_r7: [CGFloat] = [0.4113155494553988877903805132518755272031,0.02404691675157928990036459993007156299427,0.4446623926542691562779907599178841337562,0.04422351702843454329672212566038069780916,-0.3563824510893058850058423558948561549187,-0.2346456205411397433202580486977240070701,0.281390998423278471118891275182249955833,-0.1241196314045031195982815575007407460362,0.5246468381674949110760053372359834611416,-0.3992361914143916501451769818231696262956,0.5482530600156112488008375294157303869724,0.3549965209905859842010045213100966066122,-0.2258684993956820152849473970491089858115,0.4174005527322532382861197675083531066775,0.357791508128306956493247525941114872694,-0.500667321262220910149665087374160066247,0.2292895223998016596134164046816295012832,0.01778396369205064581064945627986162435263,-0.5273557805654380814530668430961668491364,0.1485886773966877960617694043321534991264]
    let L3W_r8: [CGFloat] = [-0.03930962360310592124124084989489347208291,-0.3331970491277579937694497402844717726111,-0.1177314254279887700826989771485386881977,-0.1847415427426526424170560858328826725483,-0.5936428494671091016243735793977975845337,0.5382027983799824166766256894334219396114,0.5597272501671757272134755112347193062305,-0.3911086165335536657394754911365453153849,-0.3105596991145042617965543740865541622043,-0.1811116506798411129874892822044785134494,0.05221292066375288198898374503187369555235,0.5450203463296847683494661396252922713757,0.06096850508955882486095134709103149361908,-0.290906381605092412279134350683307275176,0.4249812757557575038092068098194431513548,-0.1615161256595901151378313898021588101983,0.1099456518142097327661588224145816639066,0.5167950157854911408250586646317970007658,-0.3350561661035025839971979166875826194882,-0.3067536591953484159667198127863230183721]
    let L3W_r9: [CGFloat] = [0.2959743474865852430610857481951825320721,-0.1174194702758145775201015226230083499104,0.3483347656157315674896324253495549783111,0.2201989477722429144890270436007995158434,-0.3123241010286021412944990061077987775207,0.08153022866730624818032424627745058387518,-0.1276646211425340182721299697732320055366,-0.1308659577245228911035468399859382770956,0.4654500712347551250047672510845586657524,0.1783559329004594240508652092103147879243,0.2836464721744526018554211077571380883455,-0.2046339538821130288326344270899426192045,0.2966130895253230037589275980280945077538,0.6145406376941225934373846939706709235907,0.339006132415438421467968055367236956954,-0.4956166720630795774482635351887438446283,0.7367168918304145552866657453705556690693,-0.4271164597865911849439157776942010968924,0.2863350806074401178058508321555564180017,0.2344591274869120556267887423018692061305]
    let L3W_r10: [CGFloat] = [0.3350586808873666777586208809225354343653,0.5376003141360168324780488546821288764477,-0.5287052733375355861866751183697488158941,-0.1868819387267749709824471437968895770609,0.268723628436579375922121926123509183526,-0.2132483083960848568860768637023284099996,-0.4376602453519623514566205813025590032339,0.1480110331416715496732905421595205552876,0.1825164316239228645688541519120917655528,-0.4333362187068348081453450504341162741184,0.4604583791113184276788672377733746543527,-0.1398906323764156633959743203377001918852,-0.4900612589735147683889238123811082914472,-0.5007978253579111749260732722177635878325,-0.3014919756993445498771677648619515821338,-0.4101445160210401286171588708384661003947,-0.1917581964576390018972773532368591986597,-0.4114481969467753685876232339069247245789,-0.1148250310894896458746572420750453602523,-0.03440235755161642761112972266346332617104]
    
    // Layer 3 Biases (to be loaded from CSV later)
    let b3: [CGFloat] = [1.570493584548697807434791684499941766262,-1.222254635440018333270018047187477350235,-0.8939436934239100018828594329534098505974,0.5291253558829219771908469738264102488756,0.1782877325415959113286135107045993208885,-0.1763305425743845744612769976811250671744,0.5083600940619132924069845103076659142971,-0.8639738751331075272688053701131138950586,1.222805516764232436344173038378357887268,1.56888578481245466456073245353763923049]
    
    // Layer 4 Weights (to be loaded from CSV later)
    let L4W_r1: [CGFloat] = [-0.09757692133798477607253829546607448719442,-0.1600734480416460547846924100667820312083,0.5061304187815753863333156914450228214264,-0.7998312630434650793986861572193447500467,0.7553450764297324759866114618489518761635,0.5691900987505308373570755975379142910242,-0.2014162458317498849424964646459557116032,-0.2709058300807062336090780263475608080626,-0.1461462013368294843296268936683190986514,0.5188522782604573224674027187575120478868]
    
    // Layer 4 Biases (to be loaded from CSV later)
    let b4: [CGFloat] = [0.54109089835098778121]
    
}

extension NSMutableData {
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}
