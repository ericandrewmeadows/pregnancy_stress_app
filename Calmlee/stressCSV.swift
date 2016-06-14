//
//  stressCSV.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/9/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

class stressCSV: NSObject {
    var columnTitles:[String] = []
    var columnType:[String] = ["measurementTime","measurementAccumulated"]
    var  importDateFormat = "ss.SSS"
    var  stress_measurementTime:  [CGFloat] = []
    var  stress_measurementAccumulated:  [CGFloat] = []
    
    func cleanRows(stringData:String)->[String]{
        var cleanFile = stringData
        cleanFile = cleanFile.stringByReplacingOccurrencesOfString("\r", withString: "\n")
        cleanFile = cleanFile.stringByReplacingOccurrencesOfString("\n\n", withString: "\n")
        return cleanFile.componentsSeparatedByString("\n")
    }
    
    func cleanFields(oldString:String) -> [String]{
        let delimiter = ","
//        let delimiter = "\t"
//        var newString = oldString.stringByReplacingOccurrencesOfString("\",\"", withString: delimiter)
//        newString = newString.stringByReplacingOccurrencesOfString(",\"", withString: delimiter)
//        newString = newString.stringByReplacingOccurrencesOfString("\",", withString: delimiter)
//        newString = newString.stringByReplacingOccurrencesOfString("\"", withString: "")
//        return newString.componentsSeparatedByString(delimiter)
        return oldString.componentsSeparatedByString(delimiter)
    }
    
    func convertCSV(stringData:String) -> ([CGFloat],[CGFloat]) {
        let time = NSDate().timeIntervalSince1970
        let rows = cleanRows(stringData)
        if rows.count > 0 {
            columnTitles = cleanFields(rows.first!)
            for row in rows{
                if row == "time,stressTime" {continue}
                let fields = cleanFields(row)
                if fields.count != columnTitles.count {continue}
                for index in 0..<fields.count{
                    let column = columnTitles[index]
                    let field = fields[index]
                    switch columnType[index]{
                    case "measurementTime":
//                        newRow[column] = Int(field)
                        stress_measurementTime.append(
                            CGFloat(NSNumberFormatter().numberFromString(field)!)
                        )
                    case "measurementAccumulated":
                            self.stress_measurementAccumulated.append(
                            CGFloat(NSNumberFormatter().numberFromString(field)!)
                        )
                    default: //default keeps as string
                        continue
                    }
                }
            }
        } else {
            print("No data in file")
        }
        return((self.stress_measurementTime,self.stress_measurementAccumulated))
    }}