//
//  MessagingCell.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/2/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit

extension UIBezierPath {
    convenience init(roundedRect rect: CGRect, topLeftRadius r1: CGFloat, topRightRadius r2: CGFloat, bottomRightRadius r3: CGFloat, bottomLeftRadius r4: CGFloat) {
        let left  = CGFloat(M_PI)
        let up    = CGFloat(1.5*M_PI)
        let down  = CGFloat(M_PI_2)
        let right = CGFloat(0.0)
        self.init()
        addArcWithCenter(CGPoint(x: rect.minX + r1, y: rect.minY + r1), radius: r1, startAngle: left,  endAngle: up,    clockwise: true)
        addArcWithCenter(CGPoint(x: rect.maxX - r2, y: rect.minY + r2), radius: r2, startAngle: up,    endAngle: right, clockwise: true)
        addArcWithCenter(CGPoint(x: rect.maxX - r3, y: rect.maxY - r3), radius: r3, startAngle: right, endAngle: down,  clockwise: true)
        addArcWithCenter(CGPoint(x: rect.minX + r4, y: rect.maxY - r4), radius: r4, startAngle: down,  endAngle: left,  clockwise: true)
        closePath()
    }
}

class MessagingCell: UITableViewCell {
    
//    @IBOutlet weak var messageView:  MessageView!
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        self.messageView.frame = CGRectMake(0, 0, self.bounds.width, self.bounds.height)
//    }
    var entire_uiview = UIScreen.mainScreen().bounds
    
    var width:  CGFloat = 0.0
    var height:  CGFloat = 0.0
    
    let chatFont = UIFont(name: "Avenir-Book", size: 14.0)
    let nameFont = UIFont(name: "Avenir-Book", size: 12.0)

    @IBOutlet weak var senderLabel:  UILabel!
    @IBOutlet weak var timeLabel:  UILabel!
    @IBOutlet weak var hiddenEmailField:  UILabel!
    @IBOutlet weak var profilePicture:  UIImageView!
    @IBOutlet weak var message:  UILabel! {
        didSet {
            //message.sizeThatFits(<#T##size: CGSize##CGSize#>)
            setNeedsDisplay()
        }
    }
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        return (label.intrinsicContentSize().height)
    }
    
    override func drawRect(rect: CGRect) {
        print(self.hiddenEmailField.text)
        self.width = self.bounds.width
        self.height = self.bounds.height
        
        // Sender Text
        let senderHeight = self.heightForView(self.senderLabel.text!,
                                              font: self.nameFont!,
                                              width: self.width * 0.6)
        
        let senderWidth =  self.width
        var newFrame = CGRectMake(self.width * 0.15, 0,
                                  senderWidth, senderHeight)
        self.senderLabel.textColor = UIColor.init(red: 157/255, green: 157/255, blue: 157/255, alpha: 1.0)
        self.senderLabel.frame = newFrame
        self.senderLabel.font = self.nameFont
        self.senderLabel.sizeToFit()
        self.senderLabel.layer.zPosition = 1
        
        // Chat Text
        let messageWidth = self.entire_uiview.width * 0.8
        let messageHeight = self.heightForView(self.message.text!,
                                               font: self.chatFont!,
                                               width: messageWidth)
        newFrame = CGRectMake(self.width * 0.15, senderHeight + self.entire_uiview.height / 50,
                              messageWidth, messageHeight)
        self.message.frame = newFrame
        self.message.font = self.chatFont
        self.message.sizeToFit()
        self.message.layer.zPosition = 1
        self.message.textColor = UIColor.whiteColor()
        self.message.textAlignment = .Left
        
        // Chat Bubble
        let bubbleHeight = self.message.bounds.height + 2 * self.entire_uiview.height / 50
        let rectangle = CGRect(x: self.width * 0.1,
                               y: senderHeight,
                               width: self.message.bounds.width + 2 * self.width * 0.05,
                               height: bubbleHeight)
        let path = UIBezierPath(roundedRect: rectangle,
                                topLeftRadius: min(self.entire_uiview.height * 0.05, bubbleHeight * 0.45),
                                topRightRadius: min(self.entire_uiview.height * 0.05, bubbleHeight * 0.45),
                                bottomRightRadius: min(self.entire_uiview.height * 0.05, bubbleHeight * 0.45),
                                bottomLeftRadius: min(self.entire_uiview.height * 0.005, bubbleHeight / 10))
        UIColor.init(red: 126/255, green: 91/255, blue: 119/255, alpha: 1.0).setFill()
        path.fill()
        
        // Layout configuration
        self.layoutIfNeeded()
    }
    
//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//    }
}