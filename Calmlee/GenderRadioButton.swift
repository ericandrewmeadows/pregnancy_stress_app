//
//  GenderRadioButton.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/11/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

@IBDesignable
class GenderRadioButton: UIButton {
    
    @IBInspectable var buttonChosen:  Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        
        var path = UIBezierPath()
//        var path = UIBezierPath(ovalInRect: rect)
        if buttonChosen {
            path = UIBezierPath(ovalInRect: rect)
            UIColor.init(red: 126/255, green: 91/255, blue: 119/255, alpha: 1.0).setFill()
            UIColor.clearColor().setStroke()
            path.fill()
        }
        else {
            path = UIBezierPath(ovalInRect: CGRectMake(rect.minX + 1, rect.minY + 1,
                                                       rect.maxX - 2, rect.maxY - 2))
            UIColor.clearColor().setFill()
            UIColor.init(red: 210/255, green: 210/255, blue: 212/255, alpha: 1.0).setStroke()
            path.lineWidth = 1
            path.stroke()
        }
    }
}
