//
//  AudioMeter.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/13/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit
import AVFoundation

class AudioMeter: UIView {
    
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
    
    @IBInspectable var audioTrackLength:  CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var audioTrackProgress:  CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBOutlet var playPauseButton:  UIButton?
    var playButton:   UIImage = UIImage(named: "playButton")!
    var pauseButton:  UIImage = UIImage(named: "pauseButton")!

    
    var audioMeter_background: UIColor = UIColor.init(red: 209/255, green: 209/255, blue: 209/255, alpha: 64/100)
    var audioMeter_progColor:  UIColor = UIColor.init(red: 168/255, green: 230/255, blue: 206/255, alpha: 1.0)//was alpha: 64/100
    
    // Media Player elements
    var audioPlayer: AVAudioPlayer?
    var isPlaying = false
    var timer:NSTimer! = NSTimer.init()
    
    func loadAudio() {
        // Play audio file
        print("loadingAudioTrack")
        do {
//            let url = "https://io.calmlee.com/mindfulnessTracks/2mins-inner-peace-stereo.mp3"
//            let fileURL = NSURL(string:url)
//            let soundData = NSData(contentsOfURL:fileURL!)
//            try self.audioPlayer = AVAudioPlayer(data: soundData!)
            
            let url = String(format: "%@/2mins-inner-peace-stereo.mp3",NSBundle.mainBundle().resourcePath!)
            let fileURL = NSURL(string:url)
            try self.audioPlayer = AVAudioPlayer.init(contentsOfURL: fileURL!)
            self.audioPlayer!.prepareToPlay()
            self.audioPlayer!.volume = 1.0
            //            self.audioPlayer!.play()
            self.audioTrackLength = CGFloat(self.audioPlayer!.duration)
            print("Duration:  \(self.audioPlayer!.duration)")
            NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: "updateAudioProgressView", userInfo: nil, repeats: true)
            
        } catch {
            print("Error getting the audio file")
        }
    }
    
    @IBAction func playPauseAudio(sender: AnyObject?) {
        if delegate!.aM.isPlaying {
            self.audioPlayer!.pause()
        }
        else {
            self.audioPlayer!.play()
        }
    }

    override func drawRect(rect: CGRect) {
        
        // Main variables
        let center = CGPoint(x: bounds.width/2,y: bounds.width*5/12)
        let arcWidth: CGFloat = 10//radius/2 for filled circle
        let radius = 2 / 3 * bounds.width
        let circleStartAngle:  CGFloat = 0
        let circuleEndAngle:  CGFloat = 2*π
        
        
        // Draw the play/pause background
        let circleRadius:  CGFloat = bounds.width * 11 / 75
        let circlePath = UIBezierPath(arcCenter: center,
                                      radius: circleRadius/2,
                                      startAngle: circleStartAngle,
                                      endAngle: circuleEndAngle,
                                      clockwise: true)
        
        circlePath.lineWidth = circleRadius
        UIColor.init(red: 126/255, green: 91/255, blue: 119/255, alpha: 1.0).setStroke()
        circlePath.stroke()
        
        // Draw the play/pause button
        let newFrame = CGRectMake(center.x - circleRadius * 2 / 5, center.y - circleRadius * 5 / 22,
                                  circleRadius * 4 / 5, circleRadius * 5 / 11)
        self.playPauseButton!.frame = newFrame
        if delegate!.aM.isPlaying {
            self.playPauseButton!.setImage(self.pauseButton, forState: .Normal)
        }
        else {
            self.playPauseButton!.setImage(self.playButton, forState: .Normal)
        }
        
        
        // Draw outer meter (background)
        let startAngle: CGFloat = 3 * π / 4
        // Fill region by the ratio of total/max (stress)
        var endAngle: CGFloat = 3 * π / 4 + 3 * π / 2        // Daily Cumulative Stress Level
        let path = UIBezierPath(arcCenter: center,
                                radius: radius/2 - arcWidth/2,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        path.lineWidth = arcWidth
        path.lineCapStyle = CGLineCap.Round
        audioMeter_background.setStroke()
        path.stroke()
        
        // Draw outer meter (data)
        // Fill region by the ratio of total/max (stress)
        endAngle = 3 * π / 4 + π * 3/2 * (self.audioTrackProgress / self.audioTrackLength)
        
//        // Daily Cumulative Stress Level
//        path = UIBezierPath(arcCenter: center,
//                            radius: radius/2 - arcWidth/2,
//                            startAngle: startAngle,
//                            endAngle: endAngle,
//                            clockwise: true)
//        path.lineWidth = arcWidth
//        path.lineCapStyle = CGLineCap.Round
//        audioMeter_progColor.setStroke()
//        path.stroke()
    }
}
