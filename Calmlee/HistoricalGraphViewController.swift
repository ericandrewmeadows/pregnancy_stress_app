//
//  HistoricalGraphViewController.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/29/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit
import Charts

class HistoricalGraphViewController: UIViewController, ChartViewDelegate {
    
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    @IBOutlet weak var navigationBar:  NavigationBar?
    @IBOutlet weak var calmleeLogo: UIImageView?
    @IBOutlet weak var historicalStressMeters:  HistoricalStressLevelMeters?
    
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
    
    // Line Chart
    @IBOutlet weak var lineChartView: LineChartView!
    var timer: NSTimer?
    var timeBetweenPlotUpdates:  Double = 5 // Time in seconds
    var singleMinuteVals: [Int] = []
    var doubleMinuteVals: [Int] = []
    var xvals_str: [String] = []
    
//    let months = ["Jan" , "Feb", "Mar", "Apr", "May", "June", "July", "August", "Sept", "Oct", "Nov", "Dec"]
    //    let dollars1 = [1453.0,2352,5431,1442,5451,6486,1173,5678,9234,1345,9411,2212]
//    var months: [CGFloat] = [] {
//        didSet {
//            self.lineChartView.setNeedsDisplay()
//        }
//    }
    //    var dollars1: [CGFloat] = []
    let buttonSelectedColor =   UIColor.init(red: 126/255, green: 91/255, blue: 119/255, alpha: 1.0)
    let buttonDeselectedColor = UIColor.init(red: 29/255,  green: 29/255, blue: 38/255,  alpha: 0.1)
    
    @IBAction func changeDays (sender: UIButton!) {
//        self.timer.invalidate()
//        self.timer = nil
        if (sender == self.historicalStressMeters?.todayButton) && (dayToPlot == 1) {
            dayToPlot = 0
            self.setChartData()
        }
        else if (sender == self.historicalStressMeters?.yesterdayButton) && (dayToPlot == 0) {
            dayToPlot = 1
            self.setChartData()
        }
        else {
            print("Already Selected")
        }
    }
    
    var delay: NSTimeInterval = NSTimeInterval(2)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.width = self.view.frame.size.width
        self.height = self.view.frame.size.height
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("goToBackground:"), name:UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("killAll:"), name:UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reloadView:"), name:UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reloadView:"), name:UIApplicationDidBecomeActiveNotification, object: nil)

        
        print(">>>>> Appearing")
        
        // Calmlee logo
        var newFrame = CGRectMake(0, self.height / 30, self.width, self.height / 10)
        self.calmleeLogo?.frame = newFrame
        self.calmleeLogo?.frame = newFrame
        
        // Load up Historical Stress Section
        newFrame = CGRectMake(0, self.height * 16 / 25,
                              self.width, self.height * 4 / 25)
        self.historicalStressMeters!.frame = newFrame
        self.historicalStressMeters!.stressTodayRatio = (self.delegate?.Sensor!.stressToday)! / max_dailyStress
        self.historicalStressMeters!.stressYesterdayRatio = (self.delegate?.Sensor!.stressYesterday)! / max_dailyStress
        self.historicalStressMeters!.stressTenDayRatio = (self.delegate?.Sensor!.stress10Day)! / max_dailyStress

        
//        self.months = self.delegate!.Sensor.calmleeTime_today
//        self.dollars1 = self.delegate!.Sensor.calmleeScore_today
//        if self.historicalStressMeters!.dayToPlot == 0 {
//            self.months = self.delegate!.Sensor.calmleeTime_today
//            self.dollars1 = self.delegate!.Sensor.calmleeScore_today
//        }
//        else if self.historicalStressMeters!.dayToPlot == 1 {
//            self.months = self.delegate!.Sensor.calmleeTime_yesterday
//            self.dollars1 = self.delegate!.Sensor.calmleeScore_yesterday
//        }
//        self.months = [1.1,2.1,3.1,4.1,5.1,6.1,7.1,8.1]
//        self.dollars1 = [100,100,95,91,90,89,90,85]
        
        // NavigationBar subview
        let entire_uiview = UIScreen.mainScreen().bounds
        newFrame = CGRectMake(0,
                              entire_uiview.height * 0.9,
                              entire_uiview.width,
                              entire_uiview.height * 0.1)
        self.navigationBar!.frame = newFrame
        self.navigationBar!.homePage = 2
        
        // Menu Button
        newFrame = CGRectMake(self.width / 30, self.height / 15, self.width / 10, self.width / 10)
        self.menuButton?.frame = newFrame
        self.menuButton!.titleLabel?.adjustsFontSizeToFitWidth = true
        
        newFrame = CGRectMake(self.width / 30, self.height / 15, self.width / 10, self.width / 10)
        self.menuButton?.frame = newFrame
        self.menuButton!.titleLabel?.adjustsFontSizeToFitWidth = true

        
        // Button images
        self.navigationBar!.cM_button.setImage(self.cM_desel, forState: .Normal)
        self.navigationBar!.cM_button.setImage(self.cM_sel, forState: .Highlighted)
        self.navigationBar!.med_button.setImage(self.med_desel, forState: .Normal)
        self.navigationBar!.med_button.setImage(self.med_sel, forState: .Highlighted)
        self.navigationBar!.mes_button.setImage(self.mes_desel, forState: .Normal)
        self.navigationBar!.mes_button.setImage(self.mes_sel, forState: .Highlighted)
        self.navigationBar!.hG_button.setImage(self.hG_sel, forState: .Normal)
        self.navigationBar!.hG_button.setImage(self.hG_desel, forState: .Highlighted)
        
        // 1
        self.lineChartView.delegate = self
        // 1.1 - Instigate frame
        newFrame = CGRectMake(0, self.height / 5, self.width, self.height * 3 / 10)
        self.lineChartView.frame = newFrame
        
        self.lineChartView.layer.borderWidth = 1
        self.lineChartView.layer.borderColor = UIColor.whiteColor().CGColor

        // 1.5 - setup axes
        self.lineChartView.maxVisibleValueCount = 10000
        self.lineChartView.leftAxis.axisMinValue = 0
        self.lineChartView.leftAxis.axisMaxValue = 100
        self.lineChartView.scaleXEnabled = false
        self.lineChartView.xAxis.axisLabelModulus = Int(6*60*60)
        self.lineChartView.xAxis.axisMinValue = 0
        self.lineChartView.xAxis.axisMaxValue = 24*60*60
        print("AMod: \(self.lineChartView.xAxis.isAxisModulusCustom)")
//        if self.singleMinuteVals == [] {
//            for minute in 0..<10 {
//                self.singleMinuteVals += [Int](count: 60, repeatedValue: minute)
//            }
//            for minute in 10..<60 {
//                self.doubleMinuteVals += [Int](count: 60, repeatedValue: minute)
//            }
////            self.singleMinuteVals += 0..<10
////            self.doubleMinuteVals += 10..<60
//            for hour in 0..<24 {
//                self.xvals_str += self.singleMinuteVals.map {("\(hour):0\($0)")}
//                self.xvals_str += self.doubleMinuteVals.map {("\(hour):\($0)")}
//            }
//        }
        self.lineChartView.leftAxis.labelCount = 5
        self.lineChartView.rightAxis.axisMinValue = self.lineChartView.leftAxis.axisMinValue
        self.lineChartView.rightAxis.axisMaxValue = self.lineChartView.leftAxis.axisMaxValue
        self.lineChartView.rightAxis.labelCount = self.lineChartView.leftAxis.labelCount
        // 2
        self.lineChartView.descriptionText = ""
        // 3
        self.lineChartView.descriptionTextColor = UIColor.blackColor()
        self.lineChartView.gridBackgroundColor = UIColor.darkGrayColor()
        self.lineChartView.drawGridBackgroundEnabled = false
        self.lineChartView.scaleYEnabled = false
//        self.lineChartView.pinchZoomEnabled = true
        // 4
        self.lineChartView.noDataText = "No data provided"
        // 5
//        setChartData()
        
//        let delay: NSTimeInterval = NSTimeInterval(self.timeBetweenPlotUpdates)
        print("Loaded Stress File \(historicalStressLoaded)")
        if (self.timer == nil) {
//            if (historicalStressLoaded) {
//                self.delay = NSTimeInterval(self.delegate!.Sensor.timeBetweenStressUpdates / 4)
//            }
//            self.timer = NSTimer.scheduledTimerWithTimeInterval(self.delay,
//                                                                target: self,
//                                                                selector: #selector(viewDidLoad),
//                                                                userInfo: nil,
//                                                                repeats: true)
//        }
//        else if (self.delay == NSTimeInterval(2)) {
            setChartData()
//            self.timer.invalidate()
            self.delay = NSTimeInterval(self.delegate!.Sensor!.timeBetweenStressUpdates / 4)
            self.timer = NSTimer.scheduledTimerWithTimeInterval(self.delay,
                                                                target: self,
                                                                selector: #selector(setChartData),
                                                                userInfo: nil,
                                                                repeats: true)
        }
    }

    override func viewWillDisappear(animated: Bool) {
//        killTimers(nil)
    }
    
    func goToBackground(sender: NSNotification?) {
        print("<<<<< Disappearing")
        if self.timer != nil {
            self.timer!.invalidate()
            self.timer = NSTimer()
        }
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    func killAll(sender: NSNotification?) {
        self.goToBackground(nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func reloadView(sender: NSNotification?) {
        self.viewDidLoad()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    
    func setChartData() {
        print("plotUpdate")
        // 1 - creating an array of data entries
        // Done inside HistoricalGraphData.swift
        
        // 2 - create a data set with our array
        var set1: LineChartDataSet
        if dayToPlot == 0 {
            // Button Configuration
            self.historicalStressMeters!.todayButton!.setTitleColor(buttonSelectedColor, forState: .Normal)
            self.historicalStressMeters!.todayButton!.setTitleColor(buttonSelectedColor, forState: .Selected)
            self.historicalStressMeters!.yesterdayButton!.setTitleColor(buttonDeselectedColor, forState: .Normal)
            self.historicalStressMeters!.yesterdayButton!.setTitleColor(buttonSelectedColor, forState: .Selected)
            self.historicalStressMeters!.tenDayButton!.setTitleColor(buttonDeselectedColor, forState: .Normal)
            self.historicalStressMeters!.tenDayButton!.setTitleColor(buttonDeselectedColor, forState: .Selected)
            
            // Data Switch
            set1 = LineChartDataSet(
                yVals: self.delegate?.histData!.yVals_today,
                label: "Calmlee Score - Today"
            )
        }
        else {
            // Button Configuration
            self.historicalStressMeters!.todayButton!.setTitleColor(buttonDeselectedColor, forState: .Normal)
            self.historicalStressMeters!.todayButton!.setTitleColor(buttonSelectedColor, forState: .Selected)
            self.historicalStressMeters!.yesterdayButton!.setTitleColor(buttonSelectedColor, forState: .Normal)
            self.historicalStressMeters!.yesterdayButton!.setTitleColor(buttonSelectedColor, forState: .Selected)
            self.historicalStressMeters!.tenDayButton!.setTitleColor(buttonDeselectedColor, forState: .Normal)
            self.historicalStressMeters!.tenDayButton!.setTitleColor(buttonDeselectedColor, forState: .Selected)
            
            // Data Switch
            set1 = LineChartDataSet(
                yVals: self.delegate?.histData!.yVals_yesterday,
                label: "Calmlee Score - Yesterday"
            )
        }
        set1.axisDependency = .Left // Line will correlate with left axis values
        set1.setColor(UIColor.init(red: 126/255, green: 91/255, blue: 119/255, alpha: 1.0)) // our line's opacity is 50%
        set1.setCircleColor(UIColor.redColor()) // our circle will be dark red
        set1.lineWidth = 1.0
        set1.circleRadius = 0.0 // the radius of the node circle
        set1.fillAlpha = 65 / 255.0
        set1.fillColor = UIColor.redColor()
        set1.highlightColor = UIColor.whiteColor()
        set1.drawCircleHoleEnabled = false
        set1.mode = .HorizontalBezier
        set1.drawCirclesEnabled = false
        set1.drawValuesEnabled = false
        
        
        //3 - create an array to store our LineChartDataSets
        var dataSets : [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(set1)
        
        //4 - pass our months in for our x-axis label value along with our dataSets
        let data: LineChartData = LineChartData(xVals: self.delegate!.histData!.xvals_str, dataSets: dataSets)
//        let data: LineChartData = LineChartData(xVals: self.months.map {("\($0)")}, dataSets: dataSets)
        data.setValueTextColor(UIColor.clearColor())
        
        //5 - finally set our data
        self.lineChartView.data = data
        
//        print(self.lineChartView.xAxis.values)
        
        self.lineChartView.setNeedsDisplay()
//        self.view.setNeedsDisplay()
    }
    
    static func midPointForPoints(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
    }
    
    static func controlPointForPoints(p1: CGPoint, p2: CGPoint) -> CGPoint {
        var controlPoint:  CGPoint = midPointForPoints(p1, p2: p2);
        let diffY:  CGFloat = abs(p2.y - controlPoint.y);
    
        if (p1.y < p2.y) {
            controlPoint.y += diffY;
        }
        else if (p1.y > p2.y) {
            controlPoint.y -= diffY;
        }
        return controlPoint;
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
