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
    
    @IBOutlet weak var navigationBar:  NavigationBar?
    
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
    
    let months = ["Jan" , "Feb", "Mar", "Apr", "May", "June", "July", "August", "Sept", "Oct", "Nov", "Dec"]
    let dollars1 = [1453.0,2352,5431,1442,5451,6486,1173,5678,9234,1345,9411,2212]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.width = self.view.frame.size.width
        self.height = self.view.frame.size.height
        
        // NavigationBar subview
        let entire_uiview = UIScreen.mainScreen().bounds
        var newFrame = CGRectMake(0,
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
        // 2
        self.lineChartView.descriptionText = "Tap node for details"
        // 3
        self.lineChartView.descriptionTextColor = UIColor.whiteColor()
        self.lineChartView.gridBackgroundColor = UIColor.darkGrayColor()
        // 4
        self.lineChartView.noDataText = "No data provided"
        // 5
        setChartData(months)
    }
    
    func setChartData(months : [String]) {
        // 1 - creating an array of data entries
        var yVals1 : [ChartDataEntry] = [ChartDataEntry]()
        for var i = 0; i < months.count; i++ {
            yVals1.append(ChartDataEntry(value: dollars1[i], xIndex: i))
        }
        
        // 2 - create a data set with our array
        let set1: LineChartDataSet = LineChartDataSet(yVals: yVals1, label: "First Set")
        set1.axisDependency = .Left // Line will correlate with left axis values
        set1.setColor(UIColor.redColor().colorWithAlphaComponent(0.5)) // our line's opacity is 50%
        set1.setCircleColor(UIColor.redColor()) // our circle will be dark red
        set1.lineWidth = 2.0
        set1.circleRadius = 6.0 // the radius of the node circle
        set1.fillAlpha = 65 / 255.0
        set1.fillColor = UIColor.redColor()
        set1.highlightColor = UIColor.whiteColor()
        set1.drawCircleHoleEnabled = true
        set1.drawCubicEnabled = true
//        set1.mode =  L
        //3 - create an array to store our LineChartDataSets
        var dataSets : [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(set1)
        
        //4 - pass our months in for our x-axis label value along with our dataSets
        let data: LineChartData = LineChartData(xVals: months, dataSets: dataSets)
        data.setValueTextColor(UIColor.whiteColor())
        
        //5 - finally set our data
        self.lineChartView.data = data            
    }
    
    /*
     Experimental own plotting
    */
    func quadCurvedPathWithPoints(points: NSArray) -> UIBezierPath {
        var path: UIBezierPath
        return path
    }
//    UIBezierPath *path = [UIBezierPath bezierPath];
//    
//    NSValue *value = points[0];
//    CGPoint p1 = [value CGPointValue];
//    [path moveToPoint:p1];
//    
//    if (points.count == 2) {
//    value = points[1];
//    CGPoint p2 = [value CGPointValue];
//    [path addLineToPoint:p2];
//    return path;
//    }
//    
//    for (NSUInteger i = 1; i < points.count; i++) {
//    value = points[i];
//    CGPoint p2 = [value CGPointValue];
//    
//    CGPoint midPoint = midPointForPoints(p1, p2);
//    [path addQuadCurveToPoint:midPoint controlPoint:controlPointForPoints(midPoint, p1)];
//    [path addQuadCurveToPoint:p2 controlPoint:controlPointForPoints(midPoint, p2)];
//    
//    p1 = p2;
//    }
//    return path;
//    }
    
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