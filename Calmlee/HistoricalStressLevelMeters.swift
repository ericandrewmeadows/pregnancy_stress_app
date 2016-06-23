//
//  HistoricalStressLevelMeters.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/21/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

class HistoricalStressLevelMeters: UIView {
    
    @IBInspectable var stressMeter_background: UIColor = UIColor.init(red: 209/255, green: 209/255, blue: 209/255, alpha: 1.0)
    
    @IBInspectable var counterColor: UIColor = UIColor(red: 126/255,
                                                       green: 91/255,
                                                       blue: 119/255,
                                                       alpha: 0.64)
    
    @IBOutlet weak var todayButton:  UIButton!
    @IBOutlet weak var yesterdayButton:  UIButton!
    @IBOutlet weak var tenDayButton:  UIButton!
    var dayToPlot:  Int = 0
    
    @IBAction func changePlotDay(sender: UIButton) {
        switch sender {
        case todayButton:
            self.dayToPlot = 0
        case yesterdayButton:
            self.dayToPlot = 1
        default:
            print("uh oh")
        }
    
    }
    
    var stressTodayRatio:  CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var stressYesterdayRatio:  CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var stressTenDayRatio:  CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {
        let entire_uiview = UIScreen.mainScreen().bounds
        
        print("TodayStart:  \(entire_uiview.width * 6 / 15)")
        print("TodayFinish: \(entire_uiview.width * (6 + 7 * self.stressTodayRatio) / 15)")
        print("10Day: \(6 + 7 * self.stressTenDayRatio)")
        
        // rect height: entire_uiview.height * 4 / 25
        // rect shape - vertical anchor:  entire_uiview.height * 16 / 25
        // today line - vertical anchor:  entire_uiview.height * 2 / 3
        
        // Today stress levels
        // Background
        let todayBackground = UIBezierPath()
        let vertAnchor1 = entire_uiview.height * (67 / 100 - 16 / 25)
        todayBackground.moveToPoint(CGPointMake(entire_uiview.width * 6 / 15, vertAnchor1))
        todayBackground.addLineToPoint(CGPointMake(entire_uiview.width * 13 / 15, vertAnchor1))
        todayBackground.lineWidth = 10
        todayBackground.lineCapStyle = CGLineCap.Round
        self.stressMeter_background.setStroke()
        todayBackground.stroke()
        
        // Actual Stress
        let todayStress = UIBezierPath()
        todayStress.moveToPoint(CGPointMake(entire_uiview.width * 6 / 15, vertAnchor1))
        todayStress.addLineToPoint(
            CGPointMake(entire_uiview.width * (6 + 7 * self.stressTodayRatio) / 15,
                        vertAnchor1))
        todayStress.lineWidth = 10
        todayStress.lineCapStyle = CGLineCap.Round
        self.counterColor.setStroke()
        todayStress.stroke()

        
        
        // Yesterday stress levels
        // Background
        let yesterdayBackground = UIBezierPath()
        let vertAnchor2 = entire_uiview.height * (18 / 25 - 16 / 25)
        yesterdayBackground.moveToPoint(CGPointMake(entire_uiview.width * 6 / 15, vertAnchor2))
        yesterdayBackground.addLineToPoint(CGPointMake(entire_uiview.width * 13 / 15, vertAnchor2))
        yesterdayBackground.lineWidth = 10
        yesterdayBackground.lineCapStyle = CGLineCap.Round
        self.stressMeter_background.setStroke()
        yesterdayBackground.stroke()
        
        // Actual Stress
        let yesterdayStress = UIBezierPath()
        yesterdayStress.moveToPoint(CGPointMake(entire_uiview.width * 6 / 15, vertAnchor2))
        yesterdayStress.addLineToPoint(
            CGPointMake(entire_uiview.width * (6 + 7 * self.stressYesterdayRatio) / 15,
                vertAnchor2))
        yesterdayStress.lineWidth = 10
        yesterdayStress.lineCapStyle = CGLineCap.Round
        self.counterColor.setStroke()
        yesterdayStress.stroke()
        
        
        
        // Yesterday stress levels
        // Background
        let tenDayBackground = UIBezierPath()
        let vertAnchor3 = entire_uiview.height * (77 / 100 - 16 / 25)
        tenDayBackground.moveToPoint(CGPointMake(entire_uiview.width * 6 / 15, vertAnchor3))
        tenDayBackground.addLineToPoint(CGPointMake(entire_uiview.width * 13 / 15, vertAnchor3))
        tenDayBackground.lineWidth = 10
        tenDayBackground.lineCapStyle = CGLineCap.Round
        self.stressMeter_background.setStroke()
        tenDayBackground.stroke()
        
        // Actual Stress
        let tenDayStress = UIBezierPath()
        tenDayStress.moveToPoint(CGPointMake(entire_uiview.width * 6 / 15, vertAnchor3))
        tenDayStress.addLineToPoint(
            CGPointMake(entire_uiview.width * (6 + 7 * self.stressTenDayRatio) / 15,
                vertAnchor3))
        tenDayStress.lineWidth = 10
        tenDayStress.lineCapStyle = CGLineCap.Round
        self.counterColor.setStroke()
        tenDayStress.stroke()
        
//        let breakBar = UIBezierPath()
//        breakBar.moveToPoint(CGPointMake(width * 2 / 25, line_topAnchor))
//        breakBar.addLineToPoint(CGPointMake(width * 23 / 25, line_topAnchor))
//        UIColor.init(red: 29/255, green: 29/255, blue: 38/255, alpha: 0.1).setStroke()
//        breakBar.lineWidth = 1
//        breakBar.stroke()

    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
