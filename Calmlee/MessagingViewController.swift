//
//  MessagingViewController.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/29/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit
//import SendBird

class MessagingViewController: UIViewController {
    
    @IBOutlet weak var navigationBar:  NavigationBar?
    
    var width:  CGFloat = 0
    var height:  CGFloat = 0
    
    // Navigation elements
    // Background Images
    var cM_desel:   UIImage = UIImage(named: "calmleeMeter_pageIcon_deselected")!
    var cM_sel:     UIImage = UIImage(named: "calmleeMeter_pageIcon_selected")!
    var med_desel:  UIImage = UIImage(named: "meditation_pageIcon_deselected")!
    var med_sel:    UIImage = UIImage(named: "meditation_pageIcon_selected")!
    var mes_desel:  UIImage = UIImage(named: "messaging_pageIcon_deselected")!
    var mes_sel:    UIImage = UIImage(named: "messaging_pageIcon_selected")!
    var hG_desel:   UIImage = UIImage(named: "historicalGraph_pageIcon_deselected")!
    var hG_sel:     UIImage = UIImage(named: "historicalGraph_pageIcon_selected")!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        
        
        // Login to SendBird
//        SendBird.loginWithUserId(USER_ID, andUserName: USER_NICKNAME)
        
        
        
        
        
        self.width = self.view.frame.size.width
        self.height = self.view.frame.size.height

        // NavigationBar subview
        var newFrame = CGRectMake(0,
                                  self.height * 0.9,
                                  self.width,
                                  self.height * 0.1)
        self.navigationBar?.frame = newFrame
        self.navigationBar!.homePage = 3
        
        // Button images
        self.navigationBar!.cM_button.setImage(self.cM_desel, forState: .Normal)
        self.navigationBar!.cM_button.setImage(self.cM_sel, forState: .Highlighted)
        self.navigationBar!.med_button.setImage(self.med_desel, forState: .Normal)
        self.navigationBar!.med_button.setImage(self.med_sel, forState: .Highlighted)
        self.navigationBar!.mes_button.setImage(self.mes_sel, forState: .Normal)
        self.navigationBar!.mes_button.setImage(self.mes_desel, forState: .Highlighted)
        self.navigationBar!.hG_button.setImage(self.hG_desel, forState: .Normal)
        self.navigationBar!.hG_button.setImage(self.hG_sel, forState: .Highlighted)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
