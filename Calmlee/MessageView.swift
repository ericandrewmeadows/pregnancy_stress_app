//
//  MessageView.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/2/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

class MessageView: UIView {
    @IBOutlet weak var senderLabel:  UILabel!
    @IBOutlet weak var timeLabel:  UILabel!
    @IBOutlet weak var profilePicture:  UIImageView!
    @IBOutlet weak var message:  UILabel! {
        didSet {
            setNeedsDisplay()
        }
    }
    
//    override func drawRect(rect: CGRect) {
//        code
//    }
}
