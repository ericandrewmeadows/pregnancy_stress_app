//
//  WalkthroughViewController.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/26/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

@IBDesignable class WalkthroughViewController: UIViewController {
    
    // UI Elements
    @IBOutlet weak var walkthroughQuipSection: WalkthroughQuipSection?
    @IBOutlet weak var walkthroughImage:  UIImageView!
    @IBOutlet weak var pageProgress:  UILabel!
    
    var bandIcon:  UIImage = UIImage(named: "BandIcon")!
    var calmGirl:  UIImage = UIImage(named: "CalmGirlFace")!
    var happyGirl:  UIImage = UIImage(named: "HappyGirlFace")!
    
    var width:  CGFloat = 0
    var height:  CGFloat = 0
    var wI_w:  CGFloat = 0
    var wI_h:  CGFloat = 0
    var wI_x:  CGFloat = 0
    var wI_y:  CGFloat = 0
    
    // Walkthrough Quip items
    var quipPage = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.width = self.view.bounds.width
        self.height = self.view.bounds.height
        
        var newFrame :  CGRect = CGRectMake(0, self.height / 2, self.width, self.height / 2)
        self.walkthroughQuipSection!.frame = newFrame
        
//        newFrame = CGRectMake(0, self.height * 27 / 400, self.width, self.height * 3 / 100)
        newFrame = CGRectMake(0, self.height * 44 / 100, self.width, self.height * 3 / 100)
        self.pageProgress.frame = newFrame
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goTo_nextQuip(sender:  AnyObject?) {
        self.quipPage += 1
        self.walkthroughQuipSection!.walkthroughQuip.text = switchQuip(self.quipPage)
        walkthroughImage.frame = CGRectMake(self.wI_x,
                                            self.wI_y,
                                            self.wI_w,
                                            self.wI_h)
    }
    
    func switchQuip(quipNum:  Int) -> String {
        
        // Standard Layout items
        self.wI_h = self.height * 9 / 100
        self.wI_y = self.height * 23 / 100
        
        // Default due to majority of images (2/3)
        self.wI_w = self.wI_h * 5 / 6
        self.wI_x = (self.width - self.wI_w) / 2
        
        switch quipNum {
        case 1:
            walkthroughImage.image = self.bandIcon
            self.wI_w = self.wI_h * 5 / 4
            self.wI_x = (self.width - self.wI_w * 11 / 15) / 2
            pageProgress.text = "1 of 3"
            return "Detect stress in real time"
        case 2:
            walkthroughImage.image = self.calmGirl
            pageProgress.text = "2 of 3"
            return "Learn the most effective ways to manage stress for you"
        case 3:
            walkthroughImage.image = self.happyGirl
            pageProgress.text = "3 of 3"
            return "Live life with a clear mind"
        case 4:
            self.performSegueWithIdentifier("goto_calmleeScore", sender: nil)
            return ""
        default:
            return "OOOOOOOOOOOOOOOOOOOOOO"
        }
    }

}
