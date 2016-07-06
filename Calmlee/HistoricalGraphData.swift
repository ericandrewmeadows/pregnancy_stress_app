//
//  HistoricalGraphData.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/22/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import Foundation
import Charts

var dayToPlot: Int = 0

class HistoricalGraphData {
    
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
    
    var singleMinuteVals: [Int] = []
    var doubleMinuteVals: [Int] = []
    var xvals_str: [String] = []
    var todayReady: Bool = false
    
    var times_today:       [CGFloat] = []
    var cScores_today:     [CGFloat] = []
    var times_yesterday:   [CGFloat] = []
    var cScores_yesterday: [CGFloat] = []
    var yVals_today :      [ChartDataEntry] = [ChartDataEntry]()
    var yVals_yesterday :  [ChartDataEntry] = [ChartDataEntry]()
    var graphDataReady :   Bool = false

//    var todayData
    
    init() {
        for minute in 0..<10 {
            self.singleMinuteVals += [Int](count: 60, repeatedValue: minute)
        }
        for minute in 10..<60 {
            self.doubleMinuteVals += [Int](count: 60, repeatedValue: minute)
        }
        //            self.singleMinuteVals += 0..<10
        //            self.doubleMinuteVals += 10..<60
        for hour in 0..<24 {
            self.xvals_str += self.singleMinuteVals.map {("\(hour):0\($0)")}
            self.xvals_str += self.doubleMinuteVals.map {("\(hour):\($0)")}
        }
        
        do {
//            self.times_today = self.delegate!.Sensor.calmleeTime_today
//            self.cScores_today = self.delegate!.Sensor.calmleeScore_today
//            self.times_yesterday = self.delegate!.Sensor.calmleeTime_yesterday
//            self.cScores_yesterday = self.delegate!.Sensor.calmleeScore_yesterday
            if self.delegate!.Sensor != nil {
                self.graphDataReady = self.prepGraphData_today() && self.prepGraphData_yesterday()
            }
        } catch _ {
            print("-->> Values not populated")
        }
        
    }
    
    func prepGraphData_today() -> Bool {
        // Chart preparation
        // Today values
        for i in 0..<self.delegate!.Sensor!.calmleeTime_today.count {
            self.yVals_today.append(
                ChartDataEntry(
                    value: Double(self.delegate!.Sensor!.calmleeScore_today[i]),
                    xIndex: Int(self.delegate!.Sensor!.calmleeTime_today[i])
                )
            )
        }
        return true
    }
    
    func appendData_today(score: CGFloat, time: CGFloat) {
        self.yVals_today.append(
            ChartDataEntry(
                value: Double(score),
                xIndex: Int(time)
            )
        )
    }
    
    func prepGraphData_yesterday() -> Bool {
        // Yesterday Values
        print("Rabbit - 2a: \(self.delegate!.Sensor!.calmleeScore_yesterday.count)")
        for i in 0..<self.delegate!.Sensor!.calmleeTime_yesterday.count {
            self.yVals_yesterday.append(
                ChartDataEntry(
                    value: Double(self.delegate!.Sensor!.calmleeScore_yesterday[i]),
                    xIndex: Int(self.delegate!.Sensor!.calmleeTime_yesterday[i])
                )
            )
        }
        return true
    }
}
