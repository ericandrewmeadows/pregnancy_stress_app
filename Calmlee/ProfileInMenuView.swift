//
//  ProfileInMenuView.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/10/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

class ProfileInMenuView: UIView {
    
    var entire_uiview = UIScreen.mainScreen().bounds
    var height:  CGFloat = 0
    var width:  CGFloat = 0

    @IBOutlet var profileButton:   UIButton! = UIButton() // Transparent button over Profile area
    @IBOutlet var nameLabel:  UILabel! = UILabel()
    @IBOutlet var emailLabel:  UILabel! = UILabel()
    @IBOutlet var profilePicture:  UIImageView! = UIImageView()
    
    @IBAction func goto_profile(sender:  AnyObject?) {
        print("abc")
    }
    
    override func drawRect(rect: CGRect) {

        self.height = self.frame.height
        self.width = self.frame.width
        self.backgroundColor = UIColor.clearColor()
        
        var newFrame = CGRectMake(0, 0,
                                  self.width, self.height)
        self.profileButton.frame = newFrame
        self.profileButton.backgroundColor = UIColor.clearColor()
        self.profileButton.setTitle("", forState: .Normal)
        
        // Remember that everything is in respsect to normal width, 0.2*height
        // 133.4 total height
        // image 45 down, 40 right of left
        // image 50x50
        newFrame = CGRectMake(self.width * 8 / 75, self.height * 3 / 10,
                              self.width * 2 / 15, self.width * 2 / 15)
        self.profilePicture.frame = newFrame
        self.profilePicture.layer.borderColor = UIColor.whiteColor().CGColor
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.height / 2
        self.profilePicture.clipsToBounds = true
        self.profilePicture.contentMode = UIViewContentMode.ScaleAspectFill
        
        newFrame = CGRectMake(self.width * 22 / 75, self.height * 3 / 10,
                              self.width * 53 / 75, self.height * 3 / 16)
        self.nameLabel.frame = newFrame
        self.nameLabel.font = UIFont(name: "Avenir-Book",
                                                    size: floor(self.height * 3 / 16))
        self.nameLabel.textColor = UIColor(red: 255/255,
                                           green: 255/255,
                                           blue: 255/255,
                                           alpha: 1.0)
        self.nameLabel.text = "Bozo Clown"
        
        newFrame = CGRectMake(self.width * 22 / 75, self.height * 9 / 16,
                              self.width * 53 / 75, self.height * 1 / 10)
        self.emailLabel.frame = newFrame
        self.emailLabel.font = UIFont(name: "Avenir-Book",
                                                    size: floor(self.height * 3 / 25))
        self.emailLabel.textColor = UIColor(red: 255/255,
                                            green: 255/255,
                                            blue: 255/255,
                                            alpha: 0.5)
        self.emailLabel.text = "bozo@clowntown.com"
    }
}
