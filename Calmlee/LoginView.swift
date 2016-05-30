//
//  LoginView.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/25/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

@IBDesignable class LoginView: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var calmleeLogo: UIImageView?
    @IBOutlet weak var loginDetails: LoginDetails?
    weak var loginInfo:  loginCommunications?
    let defaults = NSUserDefaults.standardUserDefaults()
    var userName = String()
    var passWord = String()
    
    var width:  CGFloat = 0
    var height:  CGFloat = 0
    var originY:  CGFloat = 0
    var keyboardFirstTime = 0
    var minKeyHeight:  CGFloat = 0
    var keyboardShown = 0
    
    var walkthroughSeen = 0
    
    override func viewDidLoad() {
        self.loginDetails?.username.delegate = self
        self.loginDetails?.password.delegate = self
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.width = view.bounds.width
        self.height = view.bounds.height
        self.originY = self.view.frame.origin.y
        
        var newFrame :  CGRect = CGRectMake(0, self.height * 9 / 40, self.width, self.height / 10)
        self.calmleeLogo?.frame = newFrame
        
        newFrame = CGRectMake(0, self.height / 2, self.width, self.height / 2)
        self.loginDetails?.frame = newFrame
        
        self.getWalkthroughSeen()
        self.loginDetails!.username.text = self.getUsername()
        self.loginDetails!.password.text = self.getPassword()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: self.view.window)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getUsername () -> String {
        if let username = defaults.stringForKey("username") {
            return username
        }
        else {
            return String()
        }
    }
    
    func getPassword () -> String {
        if let password = defaults.stringForKey("password") {
            return password
        }
        else {
            return String()
        }
    }
    
    func getWalkthroughSeen() {
        if let walkthroughSeen = defaults.stringForKey("walkthroughSeen") {
            self.walkthroughSeen = Int(walkthroughSeen)!
        }
    }
    
    @IBAction func loginSubmit(sender: AnyObject?) {
        self.defaults.setObject(loginDetails!.username.text, forKey: "username")
        self.defaults.setObject(loginDetails!.password.text, forKey: "password")
        self.userName = getUsername()
        self.passWord = getPassword()
    }
    
    @IBAction func forgotPassword(sender:  UIButton!) {
        self.userName = getUsername()
        print(self.userName)
        self.passWord = getPassword()
        print(self.passWord)
        self.performSegueWithIdentifier("goto_walkthrough", sender: nil)
    }
    
    @IBAction func goTo_calmleeScore (sender:  AnyObject?) {
        if self.walkthroughSeen == 0 {
            self.performSegueWithIdentifier("goto_walkthrough", sender: nil)
            self.defaults.setObject(1, forKey: "walkthroughSeen")
        }
        else {
            self.performSegueWithIdentifier("goto_calmleeScore", sender: nil)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent!) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(theTextField: UITextField) -> Bool {
        if (theTextField == self.loginDetails?.password) {
            theTextField.resignFirstResponder()
            self.loginSubmit(self)
            self.goTo_calmleeScore(self)
        } else if (theTextField == self.loginDetails?.username) {
            self.loginDetails?.password.becomeFirstResponder()
        }
        return true
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: self.view.window)
    }
    
    func keyboardWillHide(sender: NSNotification) {
        if self.keyboardShown == 1 {
            let userInfo: [NSObject : AnyObject] = sender.userInfo!
            let keyboardSize: CGSize = userInfo[UIKeyboardFrameBeginUserInfoKey]!.CGRectValue.size
            self.view.frame.origin.y += keyboardSize.height
            self.keyboardShown = 0
        }
    }
    
    func keyboardWillShow(sender: NSNotification) {
        self.keyboardShown = 1
        let userInfo: [NSObject : AnyObject] = sender.userInfo!
        let keyboardSize: CGSize = userInfo[UIKeyboardFrameBeginUserInfoKey]!.CGRectValue.size
        let offset: CGSize = userInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue.size
        
        if (self.keyboardFirstTime == 0) && (offset.height > 0) {
            self.keyboardFirstTime = 1
            self.minKeyHeight = offset.height
        }
//        print(keyboardSize)
//        print(offset)
//        print(self.view.frame.origin.y)
        print("<<<>>>")
        print(offset.height)
        print(self.minKeyHeight)
        print(self.view.frame.origin.y)
        print("<<<>>>")
        
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.view.frame.origin.y = min(self.view.frame.origin.y,self.originY - max(self.minKeyHeight,offset.height))
        })

        
//        if keyboardSize.height == offset.height {
//            UIView.animateWithDuration(0.1, animations: { () -> Void in
//                print("A")
//                self.view.frame.origin.y = self.originY - keyboardSize.height
//            })
//        } else {
//            UIView.animateWithDuration(0.1, animations: { () -> Void in
//                print("B")
//                self.view.frame.origin.y = self.originY - offset.height
//            })
//        }
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
