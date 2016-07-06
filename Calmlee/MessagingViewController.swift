//
//  MessagingViewController.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/29/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit
import SendBirdSDK

class MessagingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate

    @IBOutlet weak var navigationBar:  NavigationBar?
    @IBOutlet weak var calmleeLogo: UIImageView?
    let defaults = NSUserDefaults.standardUserDefaults()
    let sQ = serverQuery()
    
    var loginView = LoginView()
    
    var width:  CGFloat = 0
    var height:  CGFloat = 0
    var originY:  CGFloat = 0
    var keyboardFirstTime = 0
    var minKeyHeight:  CGFloat = 0
    var keyboardShown = 0
    
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
    
    // SendBird-specific
    private var messageArray: Array<SendBirdMessageModel>?
    private var updateMessageTs: ((model: SendBirdMessageModel!) -> Void)!
    // Timer elements
    var timer = NSTimer()
    private var channelListQuery: SendBirdChannelListQuery?
    var channels: NSMutableArray?
    var messageSet: NSMutableArray?
    var scrolling = false
    var pastMessageLoading = true
    var typingNowView: TypingNowView?
    private var readStatus: NSMutableDictionary?
    private var typeStatus: NSMutableDictionary?
    let kTypingViewHeight: CGFloat = 36.0
    private var tableViewBottomMargin: NSLayoutConstraint?
    var channelUrl = "1f731.feb2017"
    
    // Messaging-specific
    @IBOutlet var messageTableView:  UITableView!
    var messagesArray:  [String] = ["Alpha","Beta","c"]
    @IBOutlet var messageToSend:  UITextField!
    
    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer?) {
        if sender!.state == UIGestureRecognizerState.Began {
            let p = sender!.locationInView(self.messageTableView)
            if let indexPath: NSIndexPath = self.messageTableView.indexPathForRowAtPoint(p) {
                if let tempModel = self.messageSet?[indexPath.row] {
                    if tempModel.isKindOfClass(SendBirdMessage) {
                        let message: SendBirdMessage = tempModel as! SendBirdMessage
                        let msgString: String = message.message!
                        let sndString: String = message.getSenderName()
                    }
                }
            }
            
        }
    }
    
    @IBOutlet weak var menuButton:  UIButton!
    @IBAction func goto_menu(sender: AnyObject) {
        delegate!.previousPage = self.navigationBar!.homePage
        print(delegate!.previousPage)
        self.performSegueWithIdentifier("goto_menu", sender: nil)
    }
    
    // Profile Image
//    @IBOutlet weak var changePicture_btn: UIButton!
//    @IBOutlet weak var imageView: UIImageView!
//    var picker:UIImagePickerController?=UIImagePickerController()
//    var popover:UIPopoverController?=nil
    
    func login() {
        // Login to SendBird
        if (self.defaults.stringForKey("username") != nil) && (defaults.stringForKey("firstName") != nil) {
            SendBird.sharedInstance().taskQueue.cancelAllOperations()
            SendBird.loginWithUserId(self.defaults.stringForKey("username")!, andUserName: self.defaults.stringForKey("firstName")!) // UserId is retained over
            SendBird.joinChannel(self.channelUrl) // Set a channel to join cycles when disconnect is issued; key section is guestId
            SendBird.queryMessageListInChannel(SendBird.getChannelUrl()).prevWithMessageTs(Int64.max, andLimit: 50, resultBlock: { (queryResult) -> Void in
                self.messageSet = NSMutableArray(array: queryResult.reverseObjectEnumerator().allObjects).mutableCopy() as? NSMutableArray
                
                var maxMessageTs: Int64 = Int64.min
                for model in queryResult {
                    if model.isKindOfClass(SendBirdMessage) {
                        let message: SendBirdMessage = model as! SendBirdMessage
                        //                    let msgString: String = message.message
                        //                    let msgPicture:String = message.sender.imageUrl
                        //                    let msgSender:String = message.sender.name
                        //                    let msgSenderId:Int64 = message.sender.senderId
                    }
                    self.messageArray?.addSendBirdMessage(model as! SendBirdMessageModel, updateMessageTs: self.updateMessageTs)
                    
                    if maxMessageTs < (model as! SendBirdMessageModel).getMessageTimestamp() {
                        maxMessageTs = (model as! SendBirdMessageModel).getMessageTimestamp()
                    }
                }
                
                if self.messageTableView != nil {
                    self.messageTableView?.reloadData()
                    
                    // Lets user know more messages can be seen via scrolling
                    self.messageTableView.flashScrollIndicators()
                    
                    if self.messageSet?.count > 0 {
                        self.messageTableView?.scrollToRowAtIndexPath(NSIndexPath.init(forRow: self.messageSet!.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
                    }
                }
                
                // Load last 50 messages then connect to SendBird.
                SendBird.connectWithMessageTs(maxMessageTs)
                //            SendBird.connect()
                }, endBlock: { (error) -> Void in
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.SendBird_init()
        // Do any additional setup after loading the view.
        
        self.width = self.view.frame.size.width
        self.height = self.view.frame.size.height
        
        // Variables for Layout
        let scalingFromTop: CGFloat = 0.9
        let bottomEdge = self.height * scalingFromTop + self.height * (1 - scalingFromTop) * (self.navigationBar?.lineSpace_scaling)! - 1
        let topEdge = bottomEdge - self.height / 20
        
        //        picker!.delegate=self
        self.messageTableView.dataSource = self
        self.messageTableView.delegate = self
        self.messageTableView.frame = CGRectMake(0,
                                                 self.height * 0.105,
                                                 self.width,
                                                 topEdge - self.height * 0.1)
        self.messageTableView.flashScrollIndicators()
        
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        var newFrame = CGRectMake(0, statusBarHeight, self.width, self.height / 10 - statusBarHeight)
        self.calmleeLogo?.frame = newFrame
        
        // Add messages to messagesArray
        self.messagesArray.append("Test 1")
        self.messagesArray.append("Test 2")
        self.messagesArray.append("Test 3")
        
        // Typing-now View
        self.typingNowView = TypingNowView()
        self.typingNowView?.translatesAutoresizingMaskIntoConstraints = false
        self.typingNowView?.hidden = true
        self.view.addSubview(self.typingNowView!)
        
        self.apply_constraints()
        
        
        // Login to SendBird
//        SendBird.sharedInstance().taskQueue.cancelAllOperations()
//        SendBird.loginWithUserId(self.defaults.stringForKey("username")!, andUserName: self.defaults.stringForKey("firstName")!) // UserId is retained over
//        SendBird.joinChannel(self.channelUrl) // Set a channel to join cycles when disconnect is issued; key section is guestId
        
//        SendBird.loginWithUserName("Jamie", andUserImageUrl: "https://sendbird-upload.s3-ap-northeast-1.amazonaws.com/9768c729191246c7b04369de63ec1f96.jpg")
//        SendBird.connect()
        
//        self.initChannelList()
//        self.loadChannels()
        
        SendBird.queryMessageListInChannel(SendBird.getChannelUrl()).prevWithMessageTs(Int64.max, andLimit: 50, resultBlock: { (queryResult) -> Void in
            self.messageSet = NSMutableArray(array: queryResult.reverseObjectEnumerator().allObjects).mutableCopy() as? NSMutableArray
            
            var maxMessageTs: Int64 = Int64.min
            for model in queryResult {
                if model.isKindOfClass(SendBirdMessage) {
                    let message: SendBirdMessage = model as! SendBirdMessage
                    //                    let msgString: String = message.message
                    //                    let msgPicture:String = message.sender.imageUrl
                    //                    let msgSender:String = message.sender.name
                    //                    let msgSenderId:Int64 = message.sender.senderId
                }
                self.messageArray?.addSendBirdMessage(model as! SendBirdMessageModel, updateMessageTs: self.updateMessageTs)
                
                if maxMessageTs < (model as! SendBirdMessageModel).getMessageTimestamp() {
                    maxMessageTs = (model as! SendBirdMessageModel).getMessageTimestamp()
                }
            }
            
            if self.messageTableView != nil {
                self.messageTableView?.reloadData()
                
                // Lets user know more messages can be seen via scrolling
                self.messageTableView.flashScrollIndicators()
                
                if self.messageSet?.count > 0 {
                    self.messageTableView?.scrollToRowAtIndexPath(NSIndexPath.init(forRow: self.messageSet!.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
                }
            }
            
            // Load last 50 messages then connect to SendBird.
            SendBird.connectWithMessageTs(maxMessageTs)
            //            SendBird.connect()
            }, endBlock: { (error) -> Void in
        })
//        SendBird.queryMessageListInChannel(SendBird.getChannelUrl()).prevWithMessageTs(Int64.max, andLimit: 50, resultBlock: { (queryResult) -> Void in
//            self.messageSet = NSMutableArray(array: queryResult.reverseObjectEnumerator().allObjects).mutableCopy() as? NSMutableArray
//            
//            var maxMessageTs: Int64 = Int64.min
//            for model in queryResult {
//                if model.isKindOfClass(SendBirdMessage) {
//                    let message: SendBirdMessage = model as! SendBirdMessage
////                    let msgString: String = message.message
////                    let msgPicture:String = message.sender.imageUrl
////                    let msgSender:String = message.sender.name
////                    let msgSenderId:Int64 = message.sender.senderId
//                }
//                self.messageArray?.addSendBirdMessage(model as! SendBirdMessageModel, updateMessageTs: self.updateMessageTs)
//                
//                if maxMessageTs < (model as! SendBirdMessageModel).getMessageTimestamp() {
//                    maxMessageTs = (model as! SendBirdMessageModel).getMessageTimestamp()
//                }
//            }
//            
//            self.messageTableView?.reloadData()
//            
//            // Lets user know more messages can be seen via scrolling
//            self.messageTableView.flashScrollIndicators()
//            
//            if self.messageSet?.count > 0 {
//                self.messageTableView?.scrollToRowAtIndexPath(NSIndexPath.init(forRow: self.messageSet!.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
//            }
//
//            
//            // Load last 50 messages then connect to SendBird.
//            SendBird.connectWithMessageTs(maxMessageTs)
////            SendBird.connect()
//            }, endBlock: { (error) -> Void in
//        })
//        self.SendBird_init()
//        SendBird.typeStart()
//        let delay: NSTimeInterval = NSTimeInterval(5) // Time until connection retry
//        self.timer = NSTimer.scheduledTimerWithTimeInterval(delay,
//                                                            target: self,
//                                                            selector: #selector(self.sendMessage),
//                                                            userInfo: nil,
//                                                            repeats: false)
//        SendBird.disconnect()
        

        // NavigationBar subview
        let entire_uiview = UIScreen.mainScreen().bounds
        newFrame = CGRectMake(0,
                              entire_uiview.height * 0.9,
                              entire_uiview.width,
                              entire_uiview.height * 0.1)
        self.navigationBar!.frame = newFrame
        self.navigationBar!.homePage = 3
        
        // Menu Button
        newFrame = CGRectMake(self.width / 30, self.height / 15, self.width / 10, self.width / 10)
        self.menuButton?.frame = newFrame
        self.menuButton!.titleLabel?.adjustsFontSizeToFitWidth = true
        
        // Button images
        self.navigationBar!.cM_button.setImage(self.cM_desel, forState: .Normal)
        self.navigationBar!.cM_button.setImage(self.cM_sel, forState: .Highlighted)
        self.navigationBar!.med_button.setImage(self.med_desel, forState: .Normal)
        self.navigationBar!.med_button.setImage(self.med_sel, forState: .Highlighted)
        self.navigationBar!.mes_button.setImage(self.mes_sel, forState: .Normal)
        self.navigationBar!.mes_button.setImage(self.mes_desel, forState: .Highlighted)
        self.navigationBar!.hG_button.setImage(self.hG_desel, forState: .Normal)
        self.navigationBar!.hG_button.setImage(self.hG_sel, forState: .Highlighted)
        
        // Prepare empty message field
        newFrame = CGRectMake(0, topEdge, self.width, self.height / 20)
        self.messageToSend.frame = newFrame
        self.messageToSend.layer.zPosition = 1
        
        // Top border to messaging field
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.3).CGColor
        border.frame = CGRect(x: 0, y: width, width:  messageToSend.frame.size.width, height: width)
        
        border.borderWidth = width
        messageToSend.layer.addSublayer(border)
        messageToSend.layer.masksToBounds = true
        
        let placeholder = NSAttributedString(string: "Message...", attributes: [NSForegroundColorAttributeName : UIColor.init(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0)])

        messageToSend.attributedPlaceholder = placeholder
        
        
        // Keyboard show and Hide functions
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessagingViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessagingViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: self.view.window)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("goToBackground"), name:UIApplicationWillResignActiveNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("killAll"), name:UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reloadView:"), name:UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reloadView:"), name:UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
//    func goToBackground(sender: NSNotification?) {
//        print("<<<<< Disappearing")
//        if self.timer != nil {
//            self.timer.invalidate()
//            self.timer = NSTimer()
//        }
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
//    }
//    
//    func killAll(sender: NSNotification?) {
//        self.goToBackground(nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
//    }
    
    func reloadView(sender: NSNotification?) {
        self.viewDidLoad()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func apply_constraints() {
        // Typing-now View
        self.view.addConstraint(NSLayoutConstraint.init(item: self.typingNowView!, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.messageToSend!, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint.init(item: self.typingNowView!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint.init(item: self.typingNowView!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint.init(item: self.typingNowView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: kTypingViewHeight))
        
        //unsure
        self.tableViewBottomMargin = NSLayoutConstraint.init(item: self.messageTableView!, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.messageToSend!, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        self.view.addConstraint(self.tableViewBottomMargin!)

    }
    
    func keyboardWillHide(sender: NSNotification) {
        if self.keyboardShown == 1 {
            let userInfo: [NSObject : AnyObject] = sender.userInfo!
            let keyboardSize: CGSize = userInfo[UIKeyboardFrameBeginUserInfoKey]!.CGRectValue.size
            self.view.frame.origin.y += keyboardSize.height
            self.keyboardShown = 0
        }
    }
    
    // For keyboard dismissal
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent!) {
        self.view.endEditing(true)
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        self.view.endEditing(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationWillEnterForegroundNotification, object: nil)
//        SendBird.disconnect()
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
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.view.frame.origin.y = min(self.view.frame.origin.y,self.originY - max(self.minKeyHeight,offset.height))
        })
    }
    
    /*
     Table cell height - automatic adjustment
    */
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let cell = MessagingCell()
        if let tempModel = self.messageSet?[indexPath.row] {
            if tempModel.isKindOfClass(SendBirdMessage) {
                let message: SendBirdMessage = tempModel as! SendBirdMessage
                let msgString: String = message.message!
                let sndString: String = message.getSenderName()!
                /*
                 Adjust height against:
                 - Chat text (height)
                 - Sender text (height)
                */
                var height = cell.heightForView(msgString, font: cell.chatFont!, width: self.width * cell.messageWidth)
                if message.sender.guestId == self.defaults.stringForKey("username") {
                    height += 1
                }
                else {
                    height += cell.heightForView(sndString, font: cell.nameFont!, width: self.width * 0.7)
                }
                height += 2 * self.height / 50
                return height
            }
        }
        return 0
    }
    
//    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return CGFloat(100.0)
//    }
    
    /*
     Magically populated tables
     ...
     They somehow work
    */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Create table cell
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath) as! MessagingCell
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        // Customize the cell
        if let tempModel = self.messageSet?[indexPath.row] {
            if tempModel.isKindOfClass(SendBirdMessage) {
                let message: SendBirdMessage = tempModel as! SendBirdMessage
                let msgString: String = message.message!
                cell.message.numberOfLines = 0;
                cell.message.lineBreakMode = NSLineBreakMode.ByWordWrapping;
                cell.message!.hidden = false
                cell.message!.text = msgString
                cell.senderLabel!.text = tempModel.getSenderName()
                cell.hiddenEmailField!.text = message.sender.guestId
                cell.profilePicture!.hidden = true
                cell.timeLabel!.hidden = true
                cell.hiddenEmailField!.hidden = true
                cell.senderLabel!.hidden = false
                cell.sizeToFit()
            }
        }
        
        // Return the cell
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.messageSet != nil {
            return self.messageSet!.count
        }
        else {
            return 0
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.messageTableView?.reloadData()
    }
    
    func SendBird_init() {
        
        SendBird.setEventHandlerConnectBlock({ (channel) -> Void in
                // Callback for SendBird.connectWithMessageTs() or SendBird.connect()
                self.updateChannelTitle()
            }, errorBlock: { (code) -> Void in
                // Error occured due to bad APP_ID (or other unknown reason)
                self.updateChannelTitle()
            }, channelLeftBlock: { (channel) -> Void in
                // Callback for SendBird.leaveChannel()
                SendBird.disconnect()
            }, messageReceivedBlock: { (message) -> Void in
                // Received a regular chat message
                self.updateChannelTitle()
                self.messageArray?.addSendBirdMessage(message, updateMessageTs: self.updateMessageTs)
                // For my message setup
                self.messageSet?.addObject(message)
                self.scrollToBottomWithReloading(true, force: false, animated: false)
                SendBird.markAllAsRead()
                
            }, systemMessageReceivedBlock: { (message) -> Void in
                // depreated. use System Event instead
                self.updateChannelTitle()
            }, broadcastMessageReceivedBlock: { (message) -> Void in
                // When broadcast message has been received
                self.updateChannelTitle()
            }, fileReceivedBlock: { (fileLink) -> Void in
                // Received a file
                self.updateChannelTitle()
            }, messagingStartedBlock: { (channel) -> Void in
                // Callback for SendBird.startMessagingWithUserId() or SendBird.inviteMessagingWithChannelUrl()
            }, messagingUpdatedBlock: { (channel) -> Void in
                // Callback for SendBird inviteMessagingWithChannelUrl()
            }, messagingEndedBlock: { (channel) -> Void in
                // Callback for SendBird.endMessagingWithChannelUrl()
            }, allMessagingEndedBlock: { () -> Void in
                // Callback for SendBird.endAllMessaging()
            }, messagingHiddenBlock: { (channel) -> Void in
                // Callback for SendBird.hideMessagingWithChannelUrl()
            }, allMessagingHiddenBlock: { () -> Void in
                // Calls when all messaging channels becomes hidden at once.
            }, readReceivedBlock: { (status) -> Void in
                // When ReadStatus has been received
            }, typeStartReceivedBlock: { (status) -> Void in
                // When TypeStatus has been received
                self.setTypeStatus(status.user.guestId, ts: status.timestamp)
                self.showTyping()
            }, typeEndReceivedBlock: { (status) -> Void in
                // When TypeStatus has been received
                self.setTypeStatus(status.user.guestId, ts: 0)
                self.showTyping()
            }, allDataReceivedBlock: { (sendBirdDataType, count) -> Void in
                // depreated.
                self.scrollToBottomWithReloading(true, force: false, animated: false)
            }, messageDeliveryBlock:  { (send, message, data, messageId) -> Void in
                // To determine the message has been successfully sent.
                if send == false {
                    self.messageToSend.text = message
                }
                else {
                    self.messageToSend.text = ""
                }
            }, mutedMessagesReceivedBlock: { (message) -> Void in
                // When soft-muted messages have been received
        }) { (fileLink) -> Void in
            // When soft-muted files have been received
        }
        
        SendBird.setSystemEventReceivedBlock { (event) in
            if event.getCategory() == SendBirdSystemEventCategoryChannelJoin {
                let channelUrl: String = SendBird.getCurrentChannel().url
                let userId: String = event.getDataAsString("user_id")
                let nickname: String = event.getDataAsString("nickname")
                let profileUrl: String = event.getDataAsString("profile_url")
                let isMuted: Bool = event.getDataAsBoolean("is_muted")
            }
            else if event.getCategory() == SendBirdSystemEventCategoryChannelLeave {
                
            }
            else if event.getCategory() == SendBirdSystemEventCategoryUserChannelMute {
                
            }
        }
    }
    
    func sendMessage(message:  String) {
        self.scrollToBottomWithReloading(true, force: true, animated: false)
        let messageId: String = NSUUID.init().UUIDString
//        SendBird.sendMessage("TEST3\nTest_line2\nline3", withTempId: messageId)
        SendBird.sendMessage(message)
        SendBird.typeEnd()
    }
    
    func initChannelList() {
        self.channelListQuery = SendBird.queryChannelList()
        self.channels = NSMutableArray()
    }
    
    func loadChannels() {
        if self.channelListQuery?.isLoading() == true {
            return
        }
        
        if self.channelListQuery?.hasNext() == false {
            return
        }
        
        self.channelListQuery?.nextWithResultBlock({ (queryResult) -> Void in
            if self.channelListQuery?.page == 1 {
                self.channels?.removeAllObjects()
            }
            self.channels?.addObjectsFromArray(queryResult as [AnyObject])
            }, endBlock: { (error) -> Void in
                NSLog("Error")
        })
    }
    
    func textFieldShouldReturn(textfield: UITextField) -> Bool {
        self.scrollToBottomWithReloading(false, force: true, animated: false)
        if (textfield == self.messageToSend) && (textfield.text!.characters.count > 0) {
            let messageId: String = NSUUID.init().UUIDString
            SendBird.sendMessage(textfield.text!, withTempId: messageId)
            textfield.text = nil
        }
        return true
    }
    
    func scrollToBottomWithReloading(reload: Bool, force: Bool, animated: Bool) {
        if reload {
            self.messageTableView?.reloadData()
        }
        
        if self.scrolling == true {
            return
        }
        
        if self.messageSet?.count == 0 {
            return
        }
        
        if self.pastMessageLoading == true || self.isScrollBottom() == true || force {
            print("scroll forced")
            let msgCount: Int = (self.messageSet?.count)!
            if msgCount > 0 {
                self.messageTableView.scrollToRowAtIndexPath(NSIndexPath.init(forRow: (msgCount - 1), inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: animated)
            }
        }
    }

    func isScrollBottom() -> Bool {
        let offset: CGPoint = (self.messageTableView?.contentOffset)!
        let bounds: CGRect = (self.messageTableView?.bounds)!
        let size: CGSize = (self.messageTableView?.contentSize)!
        let inset: UIEdgeInsets = (self.messageTableView?.contentInset)!
        let y: CGFloat = offset.y + bounds.size.height - inset.bottom
        let h: CGFloat = size.height
        
//        if y >= (h - 400) {
//            return true
//        }
//        return false
        return true
    }
    
    func updateChannelTitle() {
        print(SendBirdUtils.getChannelNameFromUrl(self.channelUrl ))
    }

    func showTyping() {
        if self.typeStatus?.count == 0 {
            self.hideTyping()
        }
        else {
            self.tableViewBottomMargin?.constant = -kTypingViewHeight
            self.view.updateConstraints()
            if self.typeStatus != nil {
                self.typingNowView?.setModel(self.typeStatus!)
                self.typingNowView?.hidden = false
            }
        }
    }
    
    func hideTyping() {
        self.tableViewBottomMargin?.constant = 0
        self.view.updateConstraints()
        self.typingNowView?.hidden = true
    }

    
    func setTypeStatus(userId: String, ts: Int64) {
        if userId == SendBird.getUserId() {
            return
        }
        
        if self.typeStatus == nil {
            self.typeStatus = NSMutableDictionary()
        }
        
        if ts <= 0 {
            self.typeStatus?.removeObjectForKey(userId)
        }
        else {
            self.typeStatus?.setObject(NSNumber.init(longLong: ts), forKey: userId)
        }
    }
    
    

//    @IBAction func changeProfilePicture(sender: AnyObject)
//    {
//        let alert:UIAlertController=UIAlertController(title: "Choose Image", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
//        
//        let cameraAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default)
//        {
//            UIAlertAction in
//            self.openCamera()
//            
//        }
//        let galleryAction = UIAlertAction(title: "Gallery", style: UIAlertActionStyle.Default)
//        {
//            UIAlertAction in
//            self.openGallery()
//        }
//        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel)
//        {
//            UIAlertAction in
//            
//        }
//        
//        // Add the actions
//        picker?.delegate = self
//        alert.addAction(cameraAction)
//        alert.addAction(galleryAction)
//        alert.addAction(cancelAction)
//        // Present the controller
//        if UIDevice.currentDevice().userInterfaceIdiom == .Phone
//        {
//            self.presentViewController(alert, animated: true, completion: nil)
//        }
//        else
//        {
//            popover=UIPopoverController(contentViewController: alert)
//            popover!.presentPopoverFromRect(changePicture_btn.frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
//        }
//    }
//    func openCamera()
//    {
//        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera))
//        {
//            picker!.sourceType = UIImagePickerControllerSourceType.Camera
//            self .presentViewController(picker!, animated: true, completion: nil)
//        }
//        else
//        {
//            openGallery()
//        }
//    }
//    func openGallery()
//    {
//        picker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
//        if UIDevice.currentDevice().userInterfaceIdiom == .Phone
//        {
//            self.presentViewController(picker!, animated: true, completion: nil)
//        }
//        else
//        {
//            popover=UIPopoverController(contentViewController: picker!)
//            popover!.presentPopoverFromRect(changePicture_btn.frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
//        }
//    }
//    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
//    {
//        picker .dismissViewControllerAnimated(true, completion: nil)
//        let imagePicked = info[UIImagePickerControllerOriginalImage] as? UIImage
//        let imagePath = info[UIImagePickerControllerReferenceURL]
//        let imageName = imagePath?.lastPathComponent
//        imageView.image = imagePicked
//        var imageToUse: UIImage?
////        let imageFileData: NSData = UIImagePNGRepresentation(imagePicked!)!
//
//        
//        
//        let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage
//        let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage
//        
//        if originalImage != nil {
//            imageToUse = originalImage
//        }
//        else {
//            imageToUse = editedImage
//        }
//        
//        var newWidth: CGFloat = 0;
//        var newHeight: CGFloat = 0;
//        if imageToUse?.size.width > imageToUse?.size.height {
//            newWidth = 450
//            newHeight = newWidth * (imageToUse?.size.height)! / (imageToUse?.size.width)!
//        }
//        else {
//            newHeight = 450
//            newWidth = newHeight * (imageToUse?.size.width)! / (imageToUse?.size.height)!
//        }
//        
//        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), false, 0.0);
//        imageToUse?.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
//        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        let imageFileData: NSData = UIImagePNGRepresentation(newImage)!
//        
//        
//        SendBird.uploadFile(imageFileData,
//                            filename: imageName,
//                            type: "image/png",
//                            hasSizeOfFile: UInt(imageFileData.length),
//                            withCustomField: "") { (fileInfo, error) in
//                                SendBird.sendFile(fileInfo)
//        }
//        
//    }
//    
//    func imagePickerControllerDidCancel(picker: UIImagePickerController)
//    {
//    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


