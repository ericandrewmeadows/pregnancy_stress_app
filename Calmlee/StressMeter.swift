//
//  StressMeter.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/22/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit
import Darwin

let max_dailyStress:  CGFloat = 60*60 // Time in seconds
/* Maximum set of hours stress can happen.  Above this, it will be set to the maximum.  This will show up on the plot as well */
let π:CGFloat = CGFloat(M_PI)
var stressIndex_p:  CGFloat = 0.00
let stressThreshold:  CGFloat = 0.60

@IBDesignable class StressMeter: UIView {
    
    @IBOutlet weak var stressIndex_number:  UILabel!
    @IBOutlet weak var dailyStress_time:  UILabel! // Will change to incorporate stress severity
    @IBOutlet weak var stressIsWrong:  UIButton!
    
    var moodColor = UIColor.whiteColor()
    var thresholdColor: UIColor = UIColor.init(red: 255/255,
                                               green: 170/255,
                                               blue: 170/255,
                                               alpha: 1) //242,81,84
    
    @IBInspectable var stressIndex_today: CGFloat = 0.0 {
        didSet {
            if (stressIndex_today != 0) {//let _unneeded = stressIndex_today {
                self.dailyStress_time.hidden = true
            }
            if (stressIndex_today <=  max_dailyStress) && (stressIndex_today > -0.01) {
                //the view needs to be refreshed
//                dailyStress_time?.text = String(format: "%0.1f",stressIndex_today)
                
                let stressIndex_hours = floor(stressIndex_today / (60*60))
                let stressIndex_minutes = floor((stressIndex_today - stressIndex_hours * (60*60))/60)
                
                if stressIndex_minutes < 10 {
                    dailyStress_time?.text = String(format: "%0.0f:0%0.0f",stressIndex_hours,stressIndex_minutes)
                }
                else {
                    dailyStress_time?.text = String(format: "%0.0f:%0.0f",stressIndex_hours,stressIndex_minutes)
                }
                setNeedsDisplay()
            }
        }
    }
    
    @IBInspectable var stressIndex:  CGFloat = 50 {
        didSet {
            //the view needs to be refreshed
            switch stressIndex {
            case 0..<50:
                // Red == Not Good
                moodColor = UIColor(red: 255/255,
                                    green: 140/255,
                                    blue: 148/255,
                                    alpha: 1)
            case 50..<100:
                // Green = Good
                moodColor = UIColor(red: 168/255,
                                    green: 230/255,
                                    blue: 206/255,
                                    alpha: 1)
            default:
                moodColor = UIColor(red: 169/255,
                                    green: 197/255,
                                    blue: 230/25,
                                    alpha:  1)
            }
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var outlineColor: UIColor = UIColor.blackColor()
    @IBInspectable var stressMeter_background: UIColor = UIColor.darkGrayColor()
    @IBInspectable var glowMeter_numBackground: UIColor = UIColor.whiteColor()
    @IBInspectable var glowMeter_numOutline: UIColor = UIColor.blackColor()
    @IBInspectable var counterColor: UIColor = UIColor(red: 126/255,
                                                       green: 91/255,
                                                       blue: 119/255,
                                                       alpha: 0.64)
    
    override func drawRect(rect: CGRect) {
        
        var newFrame:  CGRect = CGRectMake(bounds.width/4,
                                           bounds.height/4,
                                           bounds.width/2,
                                           bounds.height/2);
        
        stressIndex_number?.frame = newFrame
        
//        stressIndex_number.font = stressIndex_number.font.fontWithSize(40)
        
        // Main variables
        let center = CGPoint(x: bounds.width/2,y: bounds.width*5/12)
        let arcWidth: CGFloat = 10//radius/2 for filled circle
        let radius = 2 / 3 * bounds.width
        let circleStartAngle:  CGFloat = 0
        let circuleEndAngle:  CGFloat = 2*π
        
        
        // Draw the current level meter
        let circleRadius:  CGFloat = min(radius/6 + (stressIndex/100) * radius*1/3 - (arcWidth + 2),
                                         radius/2 - (arcWidth + 2))
        let circlePath = UIBezierPath(arcCenter: center,
                                      radius: circleRadius/2,
                                      startAngle: circleStartAngle,
                                      endAngle: circuleEndAngle,
                                      clockwise: true)
        
        circlePath.lineWidth = circleRadius
        moodColor.setStroke()
        circlePath.stroke()
        
        let triHeight = radius / 4
        let triWidth = triHeight * 9 / 8
        newFrame = CGRectMake(center.x + bounds.width / 16,
                              center.y + bounds.width / 6,
                              triWidth,
                              triHeight)
        stressIsWrong?.frame = newFrame
        
        
        // Draw outer meter (background)
        let startAngle: CGFloat = 3 * π / 4
        // Fill region by the ratio of total/max (stress)
        var endAngle: CGFloat = 3 * π / 4 + 3 * π / 2        // Daily Cumulative Stress Level
        var path = UIBezierPath(arcCenter: center,
                                radius: radius/2 - arcWidth/2,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        path.lineWidth = arcWidth
        path.lineCapStyle = CGLineCap.Round
        stressMeter_background.setStroke()
        path.stroke()
        
        
        // Draw outer meter (data)
        // Fill region by the ratio of total/max (stress)
        endAngle = 3 * π / 4 + π * 3/2 * (self.stressIndex_today / max_dailyStress)
//        let dailyStress_hrs = floor(stressIndex_today)
//        let dailyStress_min = round(60*(stressIndex_today - dailyStress_hrs))
//        if dailyStress_min == 0 {
//            dailyStress_time.text = String(format: "%0.0f:00",dailyStress_hrs)
//        }
//        else {
//            dailyStress_time.text = String(format: "%0.0f:%0.0f",dailyStress_hrs,dailyStress_min)
//        }
        
        
        
        
//        self.dailyStress_time.text = String(format: "%0.1f",self.stressIndex_today)
        
        // Daily Cumulative Stress Level
        path = UIBezierPath(arcCenter: center,
                                radius: radius/2 - arcWidth/2,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        path.lineWidth = arcWidth
        path.lineCapStyle = CGLineCap.Round
        counterColor.setStroke()
        path.stroke()
        
        // Draw outline for current level text
        var outlinePath = UIBezierPath()
        
        // Corner Anchor
        let bubbleAngle = π/8
        let outlineHeight: CGFloat = 24
        let outlineWidth: CGFloat = outlineHeight * 1.25
        
        if let _unneeded = dailyStress_time {
            if !(endAngle.isNaN) {//&& (stressIndex_today != 0) {
                dailyStress_time.hidden = false
                
                let anchorPoint = CGPointMake(center.x + (radius/2 + arcWidth/4) * cos(endAngle),
                                              center.y + (radius/2 + arcWidth/4) * sin(endAngle))
                outlinePath.moveToPoint(anchorPoint)
                
                let point1 = CGPointMake(
                    anchorPoint.x + outlineWidth/2 * cos(endAngle + bubbleAngle),
                    anchorPoint.y + outlineWidth/2 * sin(endAngle + bubbleAngle))
                let point9 = CGPointMake(
                    anchorPoint.x + outlineWidth/2 * cos(endAngle - bubbleAngle),
                    anchorPoint.y + outlineWidth/2 * sin(endAngle - bubbleAngle))
                outlinePath.addLineToPoint(point1)
                
                if endAngle < π {outlinePath.addLineToPoint(
                        CGPointMake(
                            point9.x - outlineWidth,
                            point1.y))
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point9.x - outlineWidth,
                            point1.y + outlineHeight))
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point9.x,
                            point1.y + outlineHeight))
                    
                    // Text layout inside daily score quip bubble
                    let newFrame:  CGRect = CGRectMake(point9.x - outlineWidth,
                                                       point1.y,
                                                       outlineWidth,
                                                       outlineHeight);
                    self.dailyStress_time?.frame = newFrame
                }
                else if ((π <= endAngle) && (endAngle < 3 / 2 * π)) {
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point1.x,
                            point9.y - outlineHeight))
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point1.x - outlineWidth,
                            point9.y - outlineHeight))
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point1.x - outlineWidth,
                            point9.y))
                    
                    // Text layout inside daily score quip bubble
                    let newFrame:  CGRect = CGRectMake(point1.x - outlineWidth,
                                                       point9.y - outlineHeight,
                                                       outlineWidth,
                                                       outlineHeight);
                    self.dailyStress_time?.frame = newFrame
                }
                else if ((3 / 2 * π <= endAngle) && (endAngle < 2 * π)) {
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point9.x + outlineWidth,
                            point1.y))
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point9.x + outlineWidth,
                            point1.y - outlineHeight))
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point9.x,
                            point1.y - outlineHeight))
                    
                    // Text layout inside daily score quip bubble
                    let newFrame:  CGRect = CGRectMake(point9.x,
                                                       point1.y - outlineHeight,
                                                       outlineWidth,
                                                       outlineHeight);
                    self.dailyStress_time?.frame = newFrame
                }
                else if ((2 * π <= endAngle) && (endAngle < 5 / 2 * π)) {
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point1.x,
                            point9.y + outlineHeight))
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point1.x + outlineWidth,
                            point9.y + outlineHeight))
                    outlinePath.addLineToPoint(
                        CGPointMake(
                            point1.x + outlineWidth,
                            point9.y))
                    
                    // Text layout inside daily score quip bubble
                    let newFrame:  CGRect = CGRectMake(point1.x,
                                                       point9.y,
                                                       outlineWidth,
                                                       outlineHeight);
                    self.dailyStress_time?.frame = newFrame
                }
                outlinePath.addLineToPoint(point9)
                outlinePath.addLineToPoint(anchorPoint)
                
                stressMeter_background.setFill()
    //            dailyStress_time.hidden = true
                outlinePath.fill()
            }
        }
    }
}