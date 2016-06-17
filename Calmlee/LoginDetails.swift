//
//  LoginDetails.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/25/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

class LoginDetails: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    // View Objects
    @IBOutlet weak var username:        UITextField!
    @IBOutlet weak var password:        UITextField!
    @IBOutlet weak var username_label:  UILabel!
    @IBOutlet weak var password_label:  UILabel!
    @IBOutlet weak var forgotPassword:  UIButton!
    @IBOutlet weak var submit:          UIButton!
    
    // Frame sizes
    var width:  CGFloat = 0
    var height:  CGFloat = 0

    override func drawRect(rect: CGRect) {
        
        width = bounds.width
        height = bounds.height
        
        // Item layouts
        // Username Text Field
        var layerRect = CGRectMake(width * 0.1,
                                   height * 0.1,
                                   width * 0.8,
                                   height * 1 / 8)
        username.frame = layerRect
        
        // Username Label
        layerRect = CGRectMake(width * 0.1,
                               height * 0.1,
                               width * 0.8,
                               height * 0.03)
        username_label.frame = layerRect
        
        // Password Text Field
        layerRect = CGRectMake(width * 0.1,
                               height * 0.4,
                               width * 0.55,
                               height * 1 / 8)
        password.frame = layerRect
        
        // Password Label
        layerRect = CGRectMake(width * 0.1,
                               height * 0.4,
                               width * 0.8,
                               height * 0.03)
        password_label.frame = layerRect
        
        // Forgot Password Button
        layerRect = CGRectMake(width * 0.65,
                               height * 0.4,
                               width * 0.25,
                               height * 1 / 8)
        forgotPassword.frame = layerRect
        forgotPassword.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Right
        forgotPassword.titleLabel?.numberOfLines = 1
        forgotPassword.titleLabel?.adjustsFontSizeToFitWidth = true
        forgotPassword.titleLabel?.lineBreakMode = NSLineBreakMode.ByClipping
        
        self.bringSubviewToFront(forgotPassword)
        
        // Submit Button
        layerRect = CGRectMake(width * 0.1,
                               height * 0.6,
                               width * 0.8,
                               height * 5 / 32)
        submit.frame = layerRect
        
        
        // Bottom-edge borders
        let usernameBorder = CALayer()
        let borderWidth = CGFloat(1.0)
        usernameBorder.borderColor = UIColor.init(red: 226/255,
                                                  green: 226/255,
                                                  blue: 228/255,
                                                  alpha: 1.00).CGColor
        usernameBorder.frame = CGRect(x: 0,
                                      y: username.frame.size.height - borderWidth,
                                      width:  width * 0.8,
                                      height: username.frame.size.height)
        usernameBorder.borderWidth = borderWidth
        username.layer.addSublayer(usernameBorder)
        username.layer.masksToBounds = true
        
        let passwordBorder = CALayer()
        passwordBorder.borderColor = UIColor.init(red: 226/255,
                                                  green: 226/255,
                                                  blue: 228/255,
                                                  alpha: 1.00).CGColor
        passwordBorder.frame = CGRect(x: 0,
                                      y: username.frame.size.height - borderWidth,
                                      width:  width * 0.8,
                                      height: username.frame.size.height)
        passwordBorder.borderWidth = borderWidth
        password.layer.addSublayer(passwordBorder)
        password.layer.masksToBounds = true
        
        let forgotPasswordBorder = CALayer()
        forgotPasswordBorder.borderColor = UIColor.init(red: 226/255,
                                                        green: 226/255,
                                                        blue: 228/255,
                                                        alpha: 1.00).CGColor
        forgotPasswordBorder.frame = CGRect(x: 0,
                                            y: username.frame.size.height - borderWidth,
                                            width:  width * 0.8,
                                            height: username.frame.size.height)
        forgotPasswordBorder.borderWidth = borderWidth
        forgotPassword.layer.addSublayer(forgotPasswordBorder)
        forgotPassword.layer.masksToBounds = true
    }

}
