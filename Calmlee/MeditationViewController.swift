//
//  MeditationViewController.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/29/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit
//import MediaPlayer
//import MobileCoreServices
import AVFoundation

class MeditationViewController: UIViewController {
    
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
    @IBOutlet weak var audioMeter: AudioMeter?

    @IBOutlet var navigationBar:  NavigationBar? =  NavigationBar()
    
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
    
    @IBOutlet weak var menuButton:  UIButton!
    @IBAction func goto_menu(sender: AnyObject) {
        delegate!.previousPage = self.navigationBar!.homePage
        print(delegate!.previousPage)
        self.performSegueWithIdentifier("goto_menu", sender: nil)
    }
    
    // Media Player elements
    var audioPlayer: AVAudioPlayer?
    var isPlaying = false
    var timer:NSTimer! = NSTimer.init()
    var playTimer = NSTimer()
    
    func loadAudio() {
        // Play audio file
        do {
            let url = "https://io.calmlee.com/mindfulnessTracks/2mins-inner-peace-stereo.mp3"
            let fileURL = NSURL(string:url)
            let soundData = NSData(contentsOfURL:fileURL!)
            try self.audioPlayer = AVAudioPlayer(data: soundData!)
            self.audioPlayer!.prepareToPlay()
            self.audioPlayer!.volume = 1.0
//            delegate!.aM.audioPlayer!.play()
            self.audioMeter!.audioTrackLength = CGFloat(delegate!.aM.audioPlayer!.duration)
//            delegate?.aM.audioTrackLength = CGFloat(self.audioPlayer!.duration)
            print("Duration:  \(self.audioPlayer!.duration)")
            NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: "updateAudioProgressView", userInfo: nil, repeats: true)

        } catch {
            print("Error getting the audio file")
        }
    }
    
    @IBAction func pauseAudioPlayer() {
        if self.audioPlayer != nil {
            self.audioPlayer!.pause()
        }
    }
    
    @IBAction func playAudioPlayer() {
        if delegate!.aM.audioPlayer != nil {
            print("exists")
            if delegate!.aM.isPlaying == false {
                delegate!.aM.audioPlayer!.play()
                delegate!.aM.isPlaying == true
                NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: "updateAudioProgressView", userInfo: nil, repeats: true)
            }
        }
        else {
            print("DNE")
        }
    }
    
    func updateAudioProgressView() {
//        print(delegate!.aM.audioPlayer!.currentTime)
        self.audioMeter!.audioTrackProgress = CGFloat(delegate!.aM.audioPlayer!.currentTime)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.width = self.view.frame.size.width
        self.height = self.view.frame.size.height
        
        // NavigationBar subview
        var newFrame = CGRectMake(0,
                                  self.height * 0.9,
                                  self.width,
                                  self.height * 0.1)
        self.navigationBar?.frame = newFrame
        
        // Menu Button
        newFrame = CGRectMake(self.width / 30, self.height / 15, self.width / 10, self.width / 10)
        self.menuButton?.frame = newFrame
        self.menuButton!.titleLabel?.adjustsFontSizeToFitWidth = true
        
        if let _ = self.navigationBar {
            print("navigationBar_exists")
        }
        else {
            self.navigationBar = NavigationBar.init(frame: newFrame)
        }
        self.navigationBar!.homePage = 1
        
        // Button images
        self.navigationBar!.cM_button.setImage(self.cM_desel, forState: .Normal)
        self.navigationBar!.cM_button.setImage(self.cM_sel, forState: .Highlighted)
        self.navigationBar!.med_button.setImage(self.med_sel, forState: .Normal)
        self.navigationBar!.med_button.setImage(self.med_desel, forState: .Highlighted)
        self.navigationBar!.mes_button.setImage(self.mes_desel, forState: .Normal)
        self.navigationBar!.mes_button.setImage(self.mes_sel, forState: .Highlighted)
        self.navigationBar!.hG_button.setImage(self.hG_desel, forState: .Normal)
        self.navigationBar!.hG_button.setImage(self.hG_sel, forState: .Highlighted)
        
        self.width = self.view.frame.size.width
        self.height = self.view.frame.size.height
        
        newFrame = CGRectMake(0,
                              self.height/2-self.width/2,
                              self.width,
                              self.width*5/6);
        
        self.audioMeter?.frame = newFrame
//        delegate?.aM.frame = newFrame
//        self.loadAudio()
        
        self.playTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
                                                                target: self,
                                                                selector: #selector(self.playAudioPlayer),
                                                                userInfo: nil,
                                                                repeats: true)
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