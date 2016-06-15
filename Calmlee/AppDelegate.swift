//
//  AppDelegate.swift
//  Calmlee
//
//  Created by Eric Meadows on 5/22/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import UIKit
import SendBirdSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var Sensor: sensorComms! = sensorComms()
    let app_notifications = notifications()
    var previousPage: Int = 0
    let sQ = serverQuery()
    let aM = AudioMeter()
    let defaults = NSUserDefaults.standardUserDefaults()
    let nav = UINavigationController()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Reads historical stress from existing storage.  Async due to read-time.
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            self.Sensor.readStressFile()
            self.aM.loadAudio()
        }
        Sensor.start()
        Sensor.startTesting()
        
//        Sensor!.determineBandDisconnect()
        
        // Consider moving this  around because of the time to initialize
        let APP_ID: String = "2857873A-3D5C-46AB-8681-E2C8EB52EA7E"
        SendBird.initAppId(APP_ID)
        
        if let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        {
            print(settings.types.contains(.Alert))
            print(settings.types.contains(.Badge))
            print(settings.types.contains(.Sound))
        }
        
        return true
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        print(notification.category)
        switch identifier! {
            
            
            
            
            
            
        case "Meditate":
            
            print("Opening to Meditation")
            
            // Currently everything is initializing with below, but it is not in the call heirarchy!
            let mainStoryboardIpad : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let gotoMeditation : UIViewController = mainStoryboardIpad.instantiateViewControllerWithIdentifier("MeditationPage") as UIViewController
            self.window?.rootViewController = gotoMeditation
            self.window?.makeKeyAndVisible()
            
        case "Incorrect":
            print("Incorrect selected")
            Sensor.reportIncorrectStress(nil)
        default:
            print("Meditate selected")
        }
        completionHandler()
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        self.window?.endEditing(true)
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
        /*
         We cannot prevent the termination of the app.
         We should send notifications to users that are terminating their app in this manner.
        */
        
        Sensor!.writeStressFile(1,initialize: false)
        try Sensor!.stop_bandDisconnectUpdates()
        Sensor!.sendFile()
    }

}

extension UIViewController {
    var lastPresentedViewController: UIViewController {
        guard let presentedViewController = presentedViewController else { return self }
        return presentedViewController.lastPresentedViewController
    }
}
