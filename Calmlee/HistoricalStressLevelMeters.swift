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

    override func drawRect(rect: CGRect) {
        let entire_uiview = UIScreen.mainScreen().bounds

        let todayBackground = UIBezierPath()
        todayBackground.moveToPoint(CGPointMake(0, 10))
        todayBackground.addLineToPoint(CGPointMake(entire_uiview.width, 10))
        todayBackground.lineWidth = entire_uiview.height / 40
        self.stressMeter_background.setStroke()
        todayBackground.stroke()
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
