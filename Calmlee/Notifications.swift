//
//  Nootifications.swift
//  Calmlee
//
//  Created by Eric Meadows on 6/9/16.
//  Copyright © 2016 Calmlee. All rights reserved.
//

import Foundation

class notifications:  NSObject {
    
    let defaults = NSUserDefaults.standardUserDefaults()

    // Specify the notification actions.
    let reminderAction_meditate = UIMutableUserNotificationAction()
    let reminderAction_incorrect = UIMutableUserNotificationAction()
    
    // Create a category with the above actions
    let extremeStressCategory = UIMutableUserNotificationCategory()
    let longDurationStressCategory = UIMutableUserNotificationCategory()
    
    // Create the alerts
    let extremeStress = UILocalNotification()
    let longDurationStress = UILocalNotification()
    
    // Alert Categories
    var categories = NSSet(array: [])
    
    // Register for notification: This will prompt for the user's consent to receive notifications from this app.
    let notificationSettings:  UIUserNotificationSettings
    //*NOTE*
    // Registering UIUserNotificationSettings more than once results in previous settings being overwritten.
    
    override init() {
        UIApplication.sharedApplication().registerUserNotificationSettings(
            UIUserNotificationSettings(
                forTypes: [.Alert, .Badge, .Sound], categories: nil))

        /*
         Extreme Stress Alert
         Notification when stress is at an extreme level, as dictated by Calmlee.
         Stress level = self.defaults.stringForKey("minStressToAlert")
         Time between alerts = self.defaults.stringForKey("secondsBetween_extremeStress")
         */
        if (self.defaults.objectForKey("minStressToAlert") == nil) {
            self.defaults.setValue(15, forKey: "minStressToAlert")
        }
        if (self.defaults.objectForKey("secondsBetween_extremeStress") == nil) {
            self.defaults.setValue(15*60, forKey: "secondsBetween_extremeStress")
        }
        
        reminderAction_meditate.identifier = "Meditate"
        reminderAction_meditate.title = "Meditate"
        reminderAction_meditate.activationMode = UIUserNotificationActivationMode.Foreground
        reminderAction_meditate.destructive = false
        reminderAction_meditate.authenticationRequired = false
        
        reminderAction_incorrect.identifier = "Incorrect"
        reminderAction_incorrect.title = "Incorrect"
        reminderAction_incorrect.activationMode = UIUserNotificationActivationMode.Background
        reminderAction_incorrect.destructive = true
        reminderAction_incorrect.authenticationRequired = false
        
        extremeStressCategory.identifier = "extremeStress"
        extremeStressCategory.setActions([reminderAction_meditate, reminderAction_incorrect], forContext: UIUserNotificationActionContext.Default)
        extremeStressCategory.setActions([reminderAction_meditate, reminderAction_incorrect], forContext: UIUserNotificationActionContext.Minimal)
        
        extremeStress.alertTitle = "Extreme Stress"
        extremeStress.alertBody = "Calmlee detected an unusually high level of stress."
        extremeStress.alertAction = "calm down"
        extremeStress.fireDate = NSDate()//.dateByAddingTimeInterval(0) // 5 minutes(60 sec * 5) from now
        extremeStress.timeZone = NSTimeZone.defaultTimeZone()
        extremeStress.soundName = UILocalNotificationDefaultSoundName // Use the default notification tone/ specify a file in the application bundle
        extremeStress.applicationIconBadgeNumber = 1 // Badge number to set on the application Icon.
        extremeStress.category = "extremeStress" // Category to use the specified actions

        
        /*
         Long-duration Stress
         Notification when stress has been present for a user-selectable period of time.
         Stress level = self.defaults.stringForKey("intervalSecondsInStress_toWarn").
         Warning pattern: (D:10SEL) - 10,     20, 30, 45, 60 [minutes]
         Other selectables: (15SEL) -     15,     30, 45, 60 [minutes]
                            (30SEL) -             30,     60 [minutes]
         */
        if (self.defaults.objectForKey("intervalSecondsInStress_toWarn") == nil) {
            self.defaults.setValue(10*60,forKey: "intervalSecondsInStress_toWarn")
        }
        
        reminderAction_meditate.identifier = "Meditate"
        reminderAction_meditate.title = "Meditate"
        reminderAction_meditate.activationMode = UIUserNotificationActivationMode.Foreground
        reminderAction_meditate.destructive = false
        reminderAction_meditate.authenticationRequired = false
        
        reminderAction_incorrect.identifier = "Incorrect"
        reminderAction_incorrect.title = "Incorrect"
        reminderAction_incorrect.activationMode = UIUserNotificationActivationMode.Background
        reminderAction_incorrect.destructive = true
        reminderAction_incorrect.authenticationRequired = false
        
        longDurationStressCategory.identifier = "longDurationStress"
        longDurationStressCategory.setActions([reminderAction_meditate, reminderAction_incorrect], forContext: UIUserNotificationActionContext.Default)
        longDurationStressCategory.setActions([reminderAction_meditate, reminderAction_incorrect], forContext: UIUserNotificationActionContext.Minimal)
        
        longDurationStress.alertTitle = "Continued Stress"
        longDurationStress.alertBody = ""
        longDurationStress.alertAction = "calm down"
        longDurationStress.fireDate = NSDate()//.dateByAddingTimeInterval(0) // 5 minutes(60 sec * 5) from now
        longDurationStress.timeZone = NSTimeZone.defaultTimeZone()
        longDurationStress.soundName = UILocalNotificationDefaultSoundName // Use the default notification tone/ specify a file in the application bundle
        longDurationStress.applicationIconBadgeNumber = 1 // Badge number to set on the application Icon.
        longDurationStress.category = "longDurationStress" // Category to use the specified actions
        
        // Setup categories of actions for the notifications
        self.categories = NSSet(set: [extremeStressCategory,longDurationStressCategory])
        
        // Register notification settings
        self.notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Sound, .Badge], categories: self.categories as? Set<UIUserNotificationCategory>)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    }
}