//
//  WalkthroughQuipSection.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/27/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

class WalkthroughQuipSection: UIView {
    
    @IBOutlet weak var walkthroughNext: UIButton!
    @IBOutlet weak var walkthroughQuip: UITextView!
    @IBOutlet weak var walkthroughViewController: WalkthroughViewController!

    // Frame sizes
    var width:  CGFloat = 0
    var height:  CGFloat = 0
    

    override func drawRect(rect: CGRect) {
        
        self.width = self.bounds.width
        self.height = self.bounds.height
        
        var bounds = CGRectMake(0,
                                0,
                                self.width,
                                self.height)
        self.walkthroughQuip.frame = bounds
        self.walkthroughQuip.textAlignment = NSTextAlignment.Center
        
        var topOffset = (height - self.walkthroughQuip.sizeThatFits(self.walkthroughQuip.frame.size).height * self.walkthroughQuip.zoomScale) / 2
        topOffset = (topOffset < 0.0 ? 0.0 : topOffset)
        self.walkthroughQuip.contentOffset = CGPointMake(0, -topOffset)
        self.walkthroughQuip.layer.zPosition = 1
        walkthroughViewController!.goTo_nextQuip(nil)
        
        let forwardH: CGFloat = 3/80 * self.height * 2 // *2 since in subframe
        let forward_dBot: CGFloat = 9/200 * self.height * 2 // *2 since in subframe
        bounds = CGRectMake((self.width - forwardH)/2,
                            self.height - (forwardH + forward_dBot),
                            forwardH,
                            forwardH)
        self.walkthroughNext.frame = bounds
        self.walkthroughNext.layer.zPosition = 2
        
        self.walkthroughNext.touchAreaEdgeInsets = UIEdgeInsetsMake(-forward_dBot,
                                                                    -(self.width - forwardH)/2,
                                                                    -forward_dBot,
                                                                    -(self.width - forwardH)/2)

    }
    
    
}

private var pTouchAreaEdgeInsets: UIEdgeInsets = UIEdgeInsetsZero

extension UIButton {
    
    var touchAreaEdgeInsets: UIEdgeInsets {
        get {
            if let value = objc_getAssociatedObject(self, &pTouchAreaEdgeInsets) as? NSValue {
                var edgeInsets = UIEdgeInsetsZero
                value.getValue(&edgeInsets)
                return edgeInsets
            }
            else {
                return UIEdgeInsetsZero
            }
        }
        set(newValue) {
            var newValueCopy = newValue
            let objCType = NSValue(UIEdgeInsets: UIEdgeInsetsZero).objCType
            let value = NSValue(&newValueCopy, withObjCType: objCType)
            objc_setAssociatedObject(self, &pTouchAreaEdgeInsets, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if UIEdgeInsetsEqualToEdgeInsets(self.touchAreaEdgeInsets, UIEdgeInsetsZero) || !self.enabled || self.hidden {
            return super.pointInside(point, withEvent: event)
        }
        
        let relativeFrame = self.bounds
        let hitFrame = UIEdgeInsetsInsetRect(relativeFrame, self.touchAreaEdgeInsets)
        
        return CGRectContainsPoint(hitFrame, point)
    }
}
