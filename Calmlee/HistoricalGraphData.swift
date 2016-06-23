//
//  HistoricalGraphData.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/22/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import Foundation

class HistoricalGraphData {
    
    var singleMinuteVals: [Int] = []
    var doubleMinuteVals: [Int] = []
    var xvals_str: [String] = []
    
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
    }
}
