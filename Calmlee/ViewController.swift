//
//  ViewController.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/22/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

// num^power operator
infix operator ** { associativity left precedence 170 }

//func ** (num: CGFloat, power: CGFloat) -> CGFloat{
//    return pow(num, power)
//}

class ViewController: UIViewController {
    
    // UI Elements
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
//    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
//    let deviceToken = delegate.deviceToken
    
    @IBOutlet weak var stressMeter: StressMeter?
    @IBOutlet weak var navigationBar: NavigationBar?
    @IBOutlet weak var calmleeLogo: UIImageView?
    @IBOutlet weak var calmleeQuip: UILabel?
    @IBOutlet weak var menuButton:  UIButton!
    weak var sensorInfo:  sensorComms!
    
    var width:  CGFloat = 0
    var height:  CGFloat = 0
    
    // Array variables
    let measurementMemory = 30
    var measurementArray:  [CGFloat] = [CGFloat](count: 30*4, repeatedValue: 0.0)
    var inputArray:  [CGFloat] = [CGFloat](count: 30*4, repeatedValue: 0.0)
    var gsr_history:  [CGFloat] = []
    var hr_history:  [CGFloat] = []
    var gsrDiffRatio_history:  [CGFloat] = []
    var hrDiffRatio_history:  [CGFloat] = []
    
    // Stress variables
    var stressIndex:  CGFloat = 0.0
    var stressSlope_limit:  CGFloat = 0.5
    var timeBetweenUpdates:  Double = 0.1 // Time in seconds
    var lastUpdateTime = NSDate().timeIntervalSince1970
    
    // Sensor variables
    var firstTime = 1
    weak var client: MSBClient?
    var lastHR:  CGFloat = 0
    var lastGSR:  CGFloat = 0
    var currentHR:  CGFloat = 0
    var currentGSR:  CGFloat = 0
    var currentGSR_DR:  CGFloat = 0
    var currentHR_DR:  CGFloat = 0
    
    // Logging variables
    var headerWritten = 0
    var quitTesting = 0
    var destinationPath: String! = NSTemporaryDirectory() + "tempSensorDump.txt"
    
    // Timer elements
    var timer = NSTimer()
    
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
    
    @IBAction func goto_menu(sender: AnyObject) {
        delegate!.previousPage = self.navigationBar!.homePage
        print(delegate!.previousPage)
        self.performSegueWithIdentifier("goto_menu", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.width = self.view.frame.size.width
        self.height = self.view.frame.size.height
        
        var newFrame:  CGRect = CGRectMake(0,
                                           self.height/2-self.width/2,
                                           self.width,
                                           self.width*5/6);

        self.stressMeter?.frame = newFrame
        
        newFrame = CGRectMake(0, self.height / 30, self.width, self.height / 10)
        self.calmleeLogo?.frame = newFrame
        
        newFrame = CGRectMake(self.width / 30, self.height / 15, self.width / 10, self.width / 10)
        self.menuButton?.frame = newFrame
        self.menuButton!.titleLabel?.adjustsFontSizeToFitWidth = true

        newFrame = CGRectMake(self.width * 0.1,
                              self.height/2+self.width/3,
                              self.width * 0.8,
                              self.height * 9 / 10 - (self.height/2+self.width/3))
        self.calmleeQuip?.frame = newFrame
        
        // NavigationBar subview
        newFrame = CGRectMake(0,
                              self.height * 0.9,
                              self.width,
                              self.height * 0.1)
        self.navigationBar?.frame = newFrame
        self.navigationBar!.homePage = 0
        
        // Button images
        self.navigationBar!.cM_button.setImage(self.cM_sel, forState: .Normal)
        self.navigationBar!.cM_button.setImage(self.cM_desel, forState: .Highlighted)
        self.navigationBar!.med_button.setImage(self.med_desel, forState: .Normal)
        self.navigationBar!.med_button.setImage(self.med_sel, forState: .Highlighted)
        self.navigationBar!.mes_button.setImage(self.mes_desel, forState: .Normal)
        self.navigationBar!.mes_button.setImage(self.mes_sel, forState: .Highlighted)
        self.navigationBar!.hG_button.setImage(self.hG_desel, forState: .Normal)
        self.navigationBar!.hG_button.setImage(self.hG_sel, forState: .Highlighted)
        
        let actualStress = delegate!.Sensor.calmleeScore
        stressMeter?.stressIndex = actualStress
        stressMeter?.stressIndex_number.text = String(format: "%0.0f",actualStress)
        updateCalmleeQuip(actualStress)

        
        let delay: NSTimeInterval = NSTimeInterval(timeBetweenUpdates)
        self.timer = NSTimer.scheduledTimerWithTimeInterval(delay,
                                                            target: self,
                                                            selector: #selector(self.updateStressMeter),
                                                            userInfo: nil,
                                                            repeats: true)
    }
    
    @IBAction func sendData(sender: UIButton!) {
//        delegate!.Sensor.sendFile()
    }

    func updateStressMeter() {
//        stressMeter?.stressIndex_today += 0.1 // Replace with  "= delegate!.Sensor.dailyCalmleeScore"
        let actualStress = delegate!.Sensor.calmleeScore
        let time = NSDate().timeIntervalSince1970
        if ((time - self.lastUpdateTime) > self.timeBetweenUpdates) {
            self.lastUpdateTime = NSDate().timeIntervalSince1970
            stressMeter?.stressIndex = actualStress
            stressMeter?.stressIndex_number.text = String(format: "%0.0f",actualStress)
            stressMeter?.stressIndex_today = delegate!.Sensor.dailyCalmleeScore// Old for average / delegate!.Sensor.measurementsRecorded
            updateCalmleeQuip(actualStress)
        }
    }
    
    func updateCalmleeQuip(relayedStress:  CGFloat) {
        switch relayedStress {
        case 80..<100:
            self.calmleeQuip!.text = "You are so calm. Are you sure you aren’t a meditating monk?"
        case 50..<80:
            self.calmleeQuip!.text = "You are looking good. Keep it up!"
        case 35..<50:
            self.calmleeQuip!.text = "Go to your happy place...you're a bit flustered."
        case 15..<35:
            self.calmleeQuip!.text = "You are experiencing stress. Try to take a 5 min break asap."
        case 0..<15:
            self.calmleeQuip!.text = "Uh oh...you really need a break!!  Try going on a walk and ignore what you were doing"
        default:
            self.calmleeQuip!.text = "I am just starting up...or you broke me"
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}