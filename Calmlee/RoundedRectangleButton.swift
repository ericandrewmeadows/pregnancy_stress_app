//
//  RoundedRectangleButton.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/12/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

class RoundedRectangleButton: UIButton {
    
    @IBInspectable var timeSelected:  Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {
        self.backgroundColor = UIColor.clearColor()
        self.layer.cornerRadius = rect.height * 2 / 25
        self.layer.borderWidth = 1
        if timeSelected {
            self.layer.borderColor = UIColor.init(red: 126/255, green: 91/255, blue: 119/255, alpha: 1.0).CGColor
            self.titleLabel!.textColor = UIColor.init(red: 126/255, green: 91/255, blue: 119/255, alpha: 1.0)
        }
        else {
            self.layer.borderColor = UIColor.init(red: 205/255, green: 205/255, blue: 205/255, alpha: 1.0).CGColor
            self.titleLabel!.textColor = UIColor.init(red: 205/255, green: 205/255, blue: 205/255, alpha: 1.0)
        }
        self.setTitleColor(UIColor.brownColor(), forState: UIControlState.Selected)
    }
}
