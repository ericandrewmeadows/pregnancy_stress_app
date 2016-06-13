//
//  MenuViewController.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/10/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
    
    @IBOutlet var homeButton:  UIButton! = UIButton()
    @IBOutlet var settingsButton:   UIButton! = UIButton()
    @IBOutlet var logoutButton:   UIButton! = UIButton()
    @IBOutlet var profileInfoView:  UIView! = UIView()
    @IBOutlet var backButton:  UIButton! = UIButton()
    
    // Layout details
    var height:  CGFloat = 0
    var width:  CGFloat = 0
    
    @IBAction func portionSelected() {
        print("abc")
    }
    
    @IBAction func goto_calmleeScore(sender: AnyObject?) {
        self.performSegueWithIdentifier("goto_calmleeScore", sender: nil)
    }
    
    @IBAction func goto_login(sender: AnyObject?) {
        self.performSegueWithIdentifier("goto_login", sender: nil)
    }
    
    @IBAction func goto_settings(sender: AnyObject?) {
        self.performSegueWithIdentifier("goto_settings", sender: nil)
    }
    
    @IBAction func go_back(sender:  UIButton) {
        switch delegate!.previousPage {
        case 0:
            self.performSegueWithIdentifier("goto_calmleeScore", sender: nil)
        case 1:
            self.performSegueWithIdentifier("goto_meditation", sender: nil)
        case 2:
            self.performSegueWithIdentifier("goto_historicalGraph", sender: nil)
        case 3:
            self.performSegueWithIdentifier("goto_messaging", sender: nil)
        default:
            self.performSegueWithIdentifier("goto_calmleeScore", sender: nil)
        }
    }
    
    override func viewDidLoad() {
        print("loaded")
        self.width = self.view.bounds.width
        self.height = self.view.bounds.height
        var newFrame = CGRectMake(0, 0, self.width, self.height * 0.2)
        self.profileInfoView.frame = newFrame
        
        // Home Button
        self.homeButton.titleLabel?.font = UIFont(name: "Avenir Book", size: self.height * 11 / 400)!
        var messageWidth = self.widthForView((self.homeButton.titleLabel?.text)!,
                                             font: (self.homeButton.titleLabel?.font)!,
                                             width: self.width * 59 / 75)
        newFrame = CGRectMake(self.width * 16 / 75 - self.height * 9 / 400, self.height * 6 / 25,
                              messageWidth + self.height * 9 / 200, self.height * 29 / 400)
        self.homeButton.frame = newFrame
        
        
        // Settings Button
        self.settingsButton.titleLabel?.font = UIFont(name: "Avenir Book", size: self.height * 11 / 400)!
        messageWidth = self.widthForView((self.settingsButton.titleLabel?.text)!,
                                         font: (self.settingsButton.titleLabel?.font)!,
                                         width: self.width * 59 / 75)
        newFrame = CGRectMake(self.width * 16 / 75 - self.height * 9 / 400, self.homeButton.frame.maxY,
                              messageWidth + self.height * 9 / 200, self.height * 29 / 400)
        self.settingsButton.frame = newFrame
        
        
        // Logout Button
        self.logoutButton.titleLabel?.font = UIFont(name: "Avenir Book", size: self.height * 11 / 400)!
        messageWidth = self.widthForView((self.logoutButton.titleLabel?.text)!,
                                         font: (self.logoutButton.titleLabel?.font)!,
                                         width: self.width * 59 / 75)
        newFrame = CGRectMake(self.width * 16 / 75 - self.height * 9 / 400, self.settingsButton.frame.maxY,
                              messageWidth + self.height * 9 / 200, self.height * 29 / 400)
        self.logoutButton.frame = newFrame
        
        let forwardH: CGFloat = 3/80 * self.height // *2 since in subframe
        let forward_dBot: CGFloat = 9/200 * self.height// *2 since in subframe
        newFrame = CGRectMake((self.width - forwardH)/2,
                              self.height - (forwardH + forward_dBot),
                              forwardH,
                              forwardH)
        self.backButton.frame = newFrame
        self.backButton.layer.zPosition = 1
        
        self.backButton.touchAreaEdgeInsets = UIEdgeInsetsMake(-self.height * 1 / 4,
                                                               -(self.width - forwardH)/2,
                                                               -forward_dBot,
                                                               -(self.width - forwardH)/2)

    }
    
    func widthForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 1
        label.font = font
        label.text = text
        
        //        return (label.intrinsicContentSize().height)
        label.sizeToFit()
        return (label.frame.width)
    }

}
