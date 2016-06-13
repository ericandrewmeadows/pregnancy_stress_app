//
//  SettingsViewController.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/11/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet var profilePicture:  UIImageView! = UIImageView()
    @IBOutlet weak var homeButton:  UIButton!
    
    @IBOutlet var maleButton:   GenderRadioButton! = GenderRadioButton()
    @IBOutlet var femaleButton: GenderRadioButton! = GenderRadioButton()
    @IBOutlet var maleLabel:   UILabel! = UILabel()
    @IBOutlet var femaleLabel: UILabel! = UILabel()
    
    @IBOutlet var fullName_textField: UITextField! = UITextField()
    @IBOutlet var email_textField:    UITextField! = UITextField()
    @IBOutlet var password_textField: UITextField! = UITextField()
    @IBOutlet var dueDate_textField:  UITextField! = UITextField()
    
    @IBOutlet var fullName_label: UILabel! = UILabel()
    @IBOutlet var email_label:    UILabel! = UILabel()
    @IBOutlet var password_label: UILabel! = UILabel()
    @IBOutlet var dueDate_label:  UILabel! = UILabel()
    @IBOutlet var gender_label:   UILabel! = UILabel()
    
    @IBOutlet var notificationsSwitch:  UISwitch! = UISwitch()
    @IBOutlet var notificationsLabel:   UILabel! = UILabel()
    
    @IBOutlet var minutes10_button:  RoundedRectangleButton! = RoundedRectangleButton()
    @IBOutlet var minutes15_button:  RoundedRectangleButton! = RoundedRectangleButton()
    @IBOutlet var minutes30_button:  RoundedRectangleButton! = RoundedRectangleButton()
    
    var width:  CGFloat = 0
    var height: CGFloat = 0
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent!) {
        self.view.endEditing(true)
    }
    
    @IBOutlet weak var menuButton:  UIButton!
    @IBAction func goto_menu(sender: AnyObject) {
        self.performSegueWithIdentifier("goto_menu", sender: nil)
    }
    
    @IBAction func goto_calmleeScore(sender: AnyObject) {
        self.performSegueWithIdentifier("goto_calmleeScore", sender: nil)
    }
    
    @IBAction func switchGender(sender: UIButton?) {
//        if sender.name
//        maleButton.buttonChosen = (self.defaults.stringForKey("female") == "0")
//        femaleButton.buttonChosen = (self.defaults.stringForKey("female") == "1")
        self.maleButton.buttonChosen = sender != self.femaleButton
        self.femaleButton.buttonChosen = sender == self.femaleButton
    }
    
    @IBAction func set_intervalSecondsInStress_toWarn(sender: AnyObject?) {
        var time:  Int
        if ((sender?.isKindOfClass(RoundedRectangleButton)) != nil){
            time = self.defaults.integerForKey("intervalSecondsInStress_toWarn")
            switch sender as! RoundedRectangleButton {
            case minutes10_button:
                time = 10*60
                print("10")
            case self.minutes15_button:
                time = 15*60
                print("15")
            case self.minutes30_button:
                time = 30*60
                print("30")
            default:
                time = self.defaults.integerForKey("intervalSecondsInStress_toWarn")
            }
        }
        else {
            time = self.defaults.integerForKey("intervalSecondsInStress_toWarn")
        }
        switch time {
        case 10*60:
            self.defaults.setValue(10*60, forKey: "intervalSecondsInStress_toWarn")
            self.minutes10_button.timeSelected = true
            self.minutes15_button.timeSelected = false
            self.minutes30_button.timeSelected = false
        case 15*60:
            self.defaults.setValue(15*60, forKey: "intervalSecondsInStress_toWarn")
            self.minutes10_button.timeSelected = false
            self.minutes15_button.timeSelected = true
            self.minutes30_button.timeSelected = false
        case 30*60:
            self.defaults.setValue(30*60, forKey: "intervalSecondsInStress_toWarn")
            self.minutes10_button.timeSelected = false
            self.minutes15_button.timeSelected = false
            self.minutes30_button.timeSelected = true
        default:
            self.minutes10_button.timeSelected = false
            self.minutes15_button.timeSelected = false
            self.minutes30_button.timeSelected = false
        }
    }

    override func viewDidLoad() {
        
        self.width = self.view.frame.width
        self.height = self.view.frame.height
        
        // Item initial values
        email_textField.text = self.defaults.stringForKey("email")!
        fullName_textField.text = self.defaults.stringForKey("firstName")! + " " + self.defaults.stringForKey("lastName")!
        dueDate_textField.text = self.defaults.stringForKey("dueDate")
        maleButton.buttonChosen = (self.defaults.stringForKey("female") == "0")
        femaleButton.buttonChosen = (self.defaults.stringForKey("female") == "1")
        
        // Menu Button
        var newFrame = CGRectMake(self.width / 30, self.height / 15, self.width / 10, self.width / 10)
        self.menuButton?.frame = newFrame
        self.menuButton!.titleLabel?.adjustsFontSizeToFitWidth = true
        
        // Home Button
        newFrame = CGRectMake(self.width * 26 / 30, self.height / 15,
                              self.width / 12, self.width / 12 * 23 / 25)
        self.homeButton?.frame = newFrame
        self.homeButton!.titleLabel?.adjustsFontSizeToFitWidth = true
        
        newFrame = CGRectMake(self.width * 11 / 30, self.height * 13 / 100,
                              self.width * 4 / 15, self.width * 4 / 15)
        self.profilePicture.frame = newFrame
        self.profilePicture.layer.borderColor = UIColor.whiteColor().CGColor
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.height / 2
        self.profilePicture.clipsToBounds = true
        self.profilePicture.contentMode = UIViewContentMode.ScaleAspectFill

        
        // Item layouts
        // Username Text Field & Label
        newFrame = CGRectMake(width * 2 / 25, height * 67 / 200,
                              width * 21 / 25, height * 3 / 40)
        fullName_textField.frame = newFrame
        newFrame = CGRectMake(width * 2 / 25, height * 64 / 200,
                              width * 21 / 25, height * 3 / 100)
        fullName_label.frame = newFrame
        
        
        // Email Text Field & Label
        newFrame = CGRectMake(width * 2 / 25, height * 87 / 200,
                              width * 21 / 25, height * 3 / 40)
        email_textField.frame = newFrame
        newFrame = CGRectMake(width * 2 / 25, height * 84 / 200,
                              width * 21 / 25, height * 3 / 100)
        email_label.frame = newFrame
        
        
        // Password Text Field & Label
        newFrame = CGRectMake(width * 2 / 25, height * 107 / 200,
                              width * 21 / 25, height * 3 / 40)
        password_textField.frame = newFrame
        newFrame = CGRectMake(width * 2 / 25, height * 104 / 200,
                              width * 21 / 25, height * 3 / 100)
        password_label.frame = newFrame
        
        
        // Due Date Text Field & Label
        newFrame = CGRectMake(width * 2 / 25, height * 127 / 200,
                              width * 21 / 25, height * 3 / 40)
        dueDate_textField.frame = newFrame
        newFrame = CGRectMake(width * 2 / 25, height * 124 / 200,
                              width * 21 / 25, height * 3 / 100)
        dueDate_label.frame = newFrame
        
        // Gender fields
        newFrame = CGRectMake(self.width * 2 / 25, self.height * 59 / 80,
                              self.width * 2 / 15, self.height * 9 / 400)
        self.gender_label.frame = newFrame
        
        // Labels
        newFrame = CGRectMake(self.width * 29 / 50, self.height * 59 / 80,
                              self.width * 2 / 15, self.height * 9 / 400)
        self.femaleLabel.frame = newFrame
        self.femaleLabel.sizeToFit()
        newFrame = CGRectMake(self.width * (23 / 25 - 9 / 100), self.height * 59 / 80,
                              self.width * 2 / 15, self.height * 9 / 400)
        self.maleLabel.frame = newFrame
        self.maleLabel.sizeToFit()
        
        // Buttons
        newFrame = CGRectMake(self.width * 79 / 150, self.height * (59 / 80 + 3 / 800),
                              self.width * 2 / 75, self.width * 2 / 75)
        self.femaleButton.frame = newFrame
        newFrame = CGRectMake(self.width * 39 / 50, self.height * (59 / 80 + 3 / 800),
                              self.width * 2 / 75, self.width * 2 / 75)
        self.maleButton.frame = newFrame
        print((self.femaleLabel.frame.maxX - self.maleButton.frame.minX) / 2)
        self.femaleButton.touchAreaEdgeInsets = UIEdgeInsetsMake(self.dueDate_textField.frame.maxY - self.femaleLabel.frame.minY,
                                                               (self.maleLabel.frame.maxX - self.width),
                                                               self.dueDate_textField.frame.maxY - self.femaleLabel.frame.minY,
                                                               self.femaleButton.frame.maxX - self.femaleLabel.frame.maxX + (self.femaleLabel.frame.maxX - self.maleButton.frame.minX) / 2)
        self.maleButton.touchAreaEdgeInsets = UIEdgeInsetsMake(self.dueDate_textField.frame.maxY - self.maleLabel.frame.minY,
                                                    (self.femaleLabel.frame.maxX - self.maleButton.frame.minX) / 2,
                                                    self.dueDate_textField.frame.maxY - self.maleLabel.frame.minY,
                                                    (self.maleButton.frame.maxX - self.width))
        
        
        // Bottom-edge borders
        let borderWidth = CGFloat(1.0)
        // Full Name UITextField
        let fullName_border = CALayer()
        fullName_border.borderColor = UIColor.init(red: 226/255,
                                                   green: 226/255,
                                                   blue: 228/255,
                                                   alpha: 1.00).CGColor
        fullName_border.frame = CGRect(x: 0,
                                       y: fullName_textField.frame.size.height - borderWidth,
                                       width:  fullName_textField.frame.size.width,
                                       height: fullName_textField.frame.size.height)
        fullName_border.borderWidth = borderWidth
        fullName_textField.layer.addSublayer(fullName_border)
        fullName_textField.layer.masksToBounds = true
        
        // Email UITextField
        let email_border = CALayer()
        email_border.borderColor = UIColor.init(red: 226/255,
                                                green: 226/255,
                                                blue: 228/255,
                                                alpha: 1.00).CGColor
        email_border.frame = CGRect(x: 0,
                                    y: email_textField.frame.size.height - borderWidth,
                                    width:  email_textField.frame.size.width,
                                    height: email_textField.frame.size.height)
        email_border.borderWidth = borderWidth
        email_textField.layer.addSublayer(email_border)
        email_textField.layer.masksToBounds = true
        
        // Password UITextField
        let password_border = CALayer()
        password_border.borderColor = UIColor.init(red: 226/255,
                                                   green: 226/255,
                                                   blue: 228/255,
                                                   alpha: 1.00).CGColor
        password_border.frame = CGRect(x: 0,
                                       y: password_textField.frame.size.height - borderWidth,
                                       width:  password_textField.frame.size.width,
                                       height: password_textField.frame.size.height)
        password_border.borderWidth = borderWidth
        password_textField.layer.addSublayer(password_border)
        password_textField.layer.masksToBounds = true
        
        // Due Date UITextField
        let dueDate_border = CALayer()
        dueDate_border.borderColor = UIColor.init(red: 226/255,
                                                   green: 226/255,
                                                   blue: 228/255,
                                                   alpha: 1.00).CGColor
        dueDate_border.frame = CGRect(x: 0,
                                      y: dueDate_textField.frame.size.height - borderWidth,
                                      width:  dueDate_textField.frame.size.width,
                                      height: dueDate_textField.frame.size.height)
        dueDate_border.borderWidth = borderWidth
        dueDate_textField.layer.addSublayer(dueDate_border)
        dueDate_textField.layer.masksToBounds = true
        
        // Gender Border
        let gender_border = CALayer()
        gender_border.borderColor = UIColor.init(red: 226/255,
                                                  green: 226/255,
                                                  blue: 228/255,
                                                  alpha: 1.00).CGColor
        gender_border.frame = CGRect(x: self.dueDate_textField.frame.minX,
                                     y: self.height * 79 / 100 - borderWidth,
                                     width:  self.dueDate_textField.frame.width,
                                     height: borderWidth)
        gender_border.borderWidth = borderWidth
        self.view.layer.addSublayer(gender_border)

        
        // Notifications Switch
        self.notificationsSwitch.thumbTintColor! = UIColor.init(red: 126/255, green: 91/255, blue: 119/255, alpha: 1.0)
        self.notificationsSwitch.onTintColor! = UIColor.init(red: 126/255, green: 91/255, blue: 119/255, alpha: 0.5)

        
        // Notification time periods
        self.set_intervalSecondsInStress_toWarn(nil)

        minutes10_button.titleLabel!.textAlignment = NSTextAlignment.Center
        minutes15_button.titleLabel!.textAlignment = NSTextAlignment.Center
        minutes30_button.titleLabel!.textAlignment = NSTextAlignment.Center
        
        minutes10_button.titleLabel!.numberOfLines = 0
        minutes15_button.titleLabel!.numberOfLines = 0
        minutes30_button.titleLabel!.numberOfLines = 0
        
        newFrame = CGRectMake(width * 2 / 25, height * 333 / 400,
                              width * 1 / 4, height * 11 / 800)
        self.notificationsLabel.frame = newFrame
        
        self.notificationsSwitch.transform = CGAffineTransformMakeScale(29 / 40, 129 / 200) //  51x31 -> 37x20
        self.notificationsSwitch.sizeToFit()
        self.notificationsSwitch.frame = CGRectMake(self.width * 23 / 25 - self.notificationsSwitch.frame.width,
                                                    height * 33 / 40,
                                                    self.notificationsSwitch.frame.width,
                                                    self.notificationsSwitch.frame.height)
        
        newFrame = CGRectMake(width * 51 / 200, height * 71 / 80,
                              width * 14 / 75, height * 3 / 40)
        minutes10_button.frame = newFrame
        
        newFrame = CGRectMake(width * 37 / 75, height * 71 / 80,
                              width * 14 / 75, height * 3 / 40)
        minutes15_button.frame = newFrame
        
        newFrame = CGRectMake(width * 11 / 15, height * 71 / 80,
                              width * 14 / 75, height * 3 / 40)
        minutes30_button.frame = newFrame
    }
}
