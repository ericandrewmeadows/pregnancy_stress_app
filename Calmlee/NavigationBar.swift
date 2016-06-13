//
//  NavigationBar.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/29/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

class NavigationBar: UIView {
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBInspectable var homePage:  Int = -1 {
        didSet {
            print(homePage)
        }
    }
    
    // Function Parents
    @IBOutlet weak var calmleeMeter:  ViewController?
    @IBOutlet weak var messaging_vc:  MessagingViewController?
    @IBOutlet weak var historicalGraph_vc:  HistoricalGraphViewController?
    @IBOutlet weak var meditation_vc:  MeditationViewController?
    
    // Navigation elements
    // Buttons
    @IBOutlet var cM_button:   UIButton! = UIButton()
    @IBOutlet var med_button:  UIButton! = UIButton()
    @IBOutlet var mes_button:  UIButton! = UIButton()
    @IBOutlet var hG_button:   UIButton! = UIButton()
    
    // Background Images
    var cM_desel:   UIImage = UIImage(named: "calmleeMeter_pageIcon_deselected")!
    var cM_sel:     UIImage = UIImage(named: "calmleeMeter_pageIcon_selected")!
    var med_desel:  UIImage = UIImage(named: "meditation_pageIcon_deselected")!
    var med_sel:    UIImage = UIImage(named: "meditation_pageIcon_selected")!
    var mes_desel:  UIImage = UIImage(named: "messaging_pageIcon_deselected")!
    var mes_sel:    UIImage = UIImage(named: "messaging_pageIcon_selected")!
    var hG_desel:   UIImage = UIImage(named: "historicalGraph_pageIcon_deselected")!
    var hG_sel:     UIImage = UIImage(named: "historicalGraph_pageIcon_selected")!
    
    // Frame sizes
    var width:  CGFloat = 0
    var height:  CGFloat = 0
    let lineSpace_scaling: CGFloat = 1 / 8
    
    /*
     Pages:
        0:  Calmlee Meter
        1:  Meditation
        2:  Historical Graph
        3:  Messaging
     */
    @IBAction func goto_calmleeMeter(sender:  UIButton) {
        switch self.homePage {
        case 1:
            self.meditation_vc!.performSegueWithIdentifier("goto_calmleeMeter", sender: nil)
        case 2:
            self.historicalGraph_vc!.performSegueWithIdentifier("goto_calmleeMeter", sender: nil)
        case 3:
            self.messaging_vc!.performSegueWithIdentifier("goto_calmleeMeter", sender: nil)
        default:
            print("Woops")
        }
    }
    @IBAction func goto_meditation(sender:  UIButton) {
        switch self.homePage {
        case 0:
            self.calmleeMeter!.performSegueWithIdentifier("goto_meditation", sender: nil)
        case 2:
            self.historicalGraph_vc!.performSegueWithIdentifier("goto_meditation", sender: nil)
        case 3:
            self.messaging_vc!.performSegueWithIdentifier("goto_meditation", sender: nil)
        default:
            print("Woops")
        }
    }
    @IBAction func goto_historicalGraph(sender:  UIButton) {
        switch self.homePage {
        case 0:
            self.calmleeMeter!.performSegueWithIdentifier("goto_historicalGraph", sender: nil)
        case 1:
            self.meditation_vc!.performSegueWithIdentifier("goto_historicalGraph", sender: nil)
        case 3:
            self.messaging_vc!.performSegueWithIdentifier("goto_historicalGraph", sender: nil)
        default:
            print("Woops")
        }
    }
    @IBAction func goto_messaging(sender:  UIButton) {
        switch self.homePage {
        case 0:
            self.calmleeMeter!.performSegueWithIdentifier("goto_messaging", sender: nil)
        case 1:
            self.meditation_vc!.performSegueWithIdentifier("goto_messaging", sender: nil)
        case 2:
            self.historicalGraph_vc!.performSegueWithIdentifier("goto_messaging", sender: nil)
        default:
            print("Woops")
        }
    }
    
    override func drawRect(rect: CGRect) {
        
        // height = 0.1 * H
        width = bounds.width
        height = bounds.height
        
        let button_h = height * 2 / 5
        let button_topAnchor = height * 13 / 40
        let button_leftAnchor = width * 1 / 6
        let button_spacing = width * 2 / 9
        
        let line_topAnchor = height * self.lineSpace_scaling
        
        var newFrame = CGRectMake(button_leftAnchor + button_spacing * 0 - button_h * 33 / 56,
                                  button_topAnchor,
                                  button_h * 33 / 28,
                                  button_h)
        self.cM_button.frame = newFrame
        self.cM_button.touchAreaEdgeInsets = UIEdgeInsetsMake(line_topAnchor - button_topAnchor,
                                                              -button_spacing / 2,
                                                              (button_h + button_topAnchor) - height,
                                                              -button_spacing / 2)
        
        newFrame = CGRectMake(button_leftAnchor + button_spacing * 1 - button_h / 2,
                              button_topAnchor,
                              button_h,
                              button_h)
        self.med_button.frame = newFrame
        self.med_button.touchAreaEdgeInsets = UIEdgeInsetsMake(line_topAnchor - button_topAnchor,
                                                               -button_spacing / 2,
                                                               (button_h + button_topAnchor) - height,
                                                               -button_spacing / 2)
        
        newFrame = CGRectMake(button_leftAnchor + button_spacing * 2 - button_h * 33 / 58,
                              button_topAnchor,
                              button_h * 33 / 29,
                              button_h)
        self.hG_button.frame = newFrame
        self.hG_button.touchAreaEdgeInsets = UIEdgeInsetsMake(line_topAnchor - button_topAnchor,
                                                              -button_spacing / 2,
                                                              (button_h + button_topAnchor) - height,
                                                              -button_spacing / 2)
        
        newFrame = CGRectMake(button_leftAnchor + button_spacing * 3 - button_h / 2,
                              button_topAnchor,
                              button_h,
                              button_h)
        self.mes_button.frame = newFrame
        self.mes_button.touchAreaEdgeInsets = UIEdgeInsetsMake(line_topAnchor - button_topAnchor,
                                                               -button_spacing / 2,
                                                               (button_h + button_topAnchor) - height,
                                                               -button_spacing / 2)
        
        let breakBar = UIBezierPath()
        breakBar.moveToPoint(CGPointMake(width * 2 / 25, line_topAnchor))
        breakBar.addLineToPoint(CGPointMake(width * 23 / 25, line_topAnchor))
        UIColor.init(red: 29/255, green: 29/255, blue: 38/255, alpha: 0.7).setStroke()
        breakBar.lineWidth = 1
        breakBar.stroke()
    }
}